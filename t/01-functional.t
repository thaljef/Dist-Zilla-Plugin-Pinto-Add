#!perl

use strict;
use warnings;

use Test::More;
use Test::DZil;
use Test::Exception;

use File::Which;
use Class::Load;
use Dist::Zilla::Tester;

no warnings qw(redefine once);

#------------------------------------------------------------------------------
# Much of this test was deduced from:
#
#  https://metacpan.org/source/RJBS/Dist-Zilla-4.300016/t/plugins/uploadtocpan.t
#
# But it isn't clear how much of the D::Z testing API is actually stable and
# public.  So I wouldn't be surpised if these tests start failing with newer
# D::Z.
#------------------------------------------------------------------------------

my $has_pinto_tester = Class::Load::try_load_class('Pinto::Tester');
plan skip_all => 'Pinto::Tester required' if not $has_pinto_tester;

my $has_pinto_server_tester = Class::Load::try_load_class('Pinto::Server::Tester');
plan skip_all => 'Pinto::Server::Tester required' if not $has_pinto_server_tester;

my $has_pinto = File::Which::which('pinto');
plan skip_all => 'pinto (executable) required' if not $has_pinto;

my $has_pintod = File::Which::which('pintod');
plan skip_all => 'pintod (executable) required' if not $has_pintod;

my $plugin = 'Pinto::Add';

#------------------------------------------------------------------------------

sub build_tzil {

    my $dist_ini = simple_ini('GatherDir', 'ModuleBuild', @_);

    return Builder->from_config(
        { dist_root => 'corpus/dist/DZT' },
        { add_files => {'source/dist.ini' => $dist_ini} }
    );
}

#------------------------------------------------------------------------------

sub build_pinto_tester {
    my ($class, @args) = @_;

    my $tester = $class->new(@args);
    $tester->start_server if $class eq 'Pinto::Server::Tester';
    diag "Tester root is $tester";

    return $tester;
}

#-----------------------------------------------------------------------------
# Run all tests with a local repo, then run again with remote repo

for my $class (qw(Pinto::Tester Pinto::Server::Tester)) {

    local $ENV{PINTO_AUTHOR_ID} = 'AUTHOR';

    subtest "Basic release ($class)" => sub {

        my $t    = build_pinto_tester($class);
        my $tzil = build_tzil( [$plugin => {root => "$t"}] );

        $tzil->release;

        $t->registration_ok("AUTHOR/DZT-Sample-0.001/DZT::Sample~0.001/");
    };


    #-------------------------------------------------------------------------

    subtest "Release to stack ($class)" => sub {

        my $t = build_pinto_tester($class);
        $t->run_ok(New => {stack => 'test'});

        my $tzil = build_tzil( [$plugin => {root  => "$t",
            stack => 'test'}] );
        $tzil->release;

        $t->registration_ok("AUTHOR/DZT-Sample-0.001/DZT::Sample~0.001/test");
    };

    #-------------------------------------------------------------------------

    subtest "Get author from dist.ini ($class)" => sub {

        my $t    =  build_pinto_tester($class);
        my $tzil = build_tzil( [$plugin => {root   => "$t",
            author => 'ME'}] );

        $tzil->release;

        $t->registration_ok("ME/DZT-Sample-0.001/DZT::Sample~0.001/");
    };

    #-----------------------------------------------------------------------------

    subtest "Get username/password from dist.ini ($class)" => sub {

        my ($username, $password);

        # Intercept release() method and record some attributes
        local *Dist::Zilla::Plugin::Pinto::Add::release = sub {
             ($username, $password) = ($_[0]->username, $_[0]->password);
        };

        my $t     = build_pinto_tester($class);
        my $tzil  = build_tzil( [$plugin => { root     => "$t",
                                              username => 'myusername',
                                              password => 'mypassword',
                                              authenticate => 1 }] );
        $tzil->release;

        is $password, 'mypassword', 'got password from dist.ini';
        is $username, 'myusername', 'got username from dist.ini';
    };

    #-----------------------------------------------------------------------------

    subtest "Prompt for password ($class)" => sub {

        my ($username, $password);

        # Intercept release() method and record some attributes
        local *Dist::Zilla::Plugin::Pinto::Add::release = sub {
            ($username, $password) = ($_[0]->username, $_[0]->password);
        };

        my $t     = build_pinto_tester($class);
        my $root  = $t->to_string;
        my $tzil  = build_tzil( [$plugin => { root         => "$t",
                                              authenticate => 1}] );

        $tzil->chrome->set_response_for('Pinto password: ', 'mypassword');

        $tzil->release;

        is $password, 'mypassword', 'got password from prompt';
    };

    #-----------------------------------------------------------------------------

    subtest "Multiple repositories ($class)" => sub {

        my ($t1, $t2)       = map { build_pinto_tester($class) } (1,2);
        my ($root1, $root2) = map { "$_" } ($t1, $t2);
        my $roots           = [ $root1, $root2 ];

        my $tzil = build_tzil( [$plugin => { root => $roots }] );

        $tzil->release;

        $t1->registration_ok("AUTHOR/DZT-Sample-0.001/DZT::Sample~0.001/");
        $t2->registration_ok("AUTHOR/DZT-Sample-0.001/DZT::Sample~0.001/");
    };

    #-----------------------------------------------------------------------------

    subtest "Repo not repsonding -- so abort ($class)" => sub {

        # So we don't have to wait forever...
        local $ENV{PINTO_LOCKFILE_TIMEOUT} = 5;

        my ($t1, $t2)       = map { build_pinto_tester($class) } (1,2);
        my ($root1, $root2) = map { "$_" } ($t1, $t2);
        my $roots           = [ $root1, $root2 ];

        my $tzil  = build_tzil( [$plugin => { root => $roots }] );

        $t2->pinto->repo->lock('EX'); # $t2 now unavailable
        throws_ok { $tzil->release } qr/Aborting/;

        $t1->repository_clean_ok;
        $t2->repository_clean_ok;
    };

    #-----------------------------------------------------------------------------

    subtest "Repo not responding -- partial release ($class)" => sub {

        # So we don't have to wait forever...
        local $ENV{PINTO_LOCKFILE_TIMEOUT} = 5;

        my ($t1, $t2)       = map { build_pinto_tester($class) } (1,2);
        my ($root1, $root2) = map { "$_" } ($t1, $t2);
        my $roots           = [ $root1, $root2 ];

        my $tzil   = build_tzil( [$plugin => { root   => $roots }] );
        my $prompt = "repository at $root2 is not available.  Abort release?";
        $tzil->chrome->set_response_for($prompt, 'N');

        $t2->pinto->repo->lock('EX'); # $t2 now unavailable
        lives_ok { $tzil->release };

        $t1->registration_ok("AUTHOR/DZT-Sample-0.001/DZT::Sample~0.001/");
        $t2->repository_clean_ok;
    };
}

#-----------------------------------------------------------------------------

done_testing;

#-----------------------------------------------------------------------------
# Clean up after Test::DZil;

END {
  require File::Path;
  eval { File::Path::rmtree('tmp') } if -e 'tmp';
}


