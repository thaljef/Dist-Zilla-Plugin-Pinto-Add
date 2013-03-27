#!perl

use strict;
use warnings;

use Test::More;
use Test::DZil;
use Test::Exception;

use File::Temp;
use File::Path;
use File::Which;
use Class::Load;
use Dist::Zilla::Tester;
use Dist::Zilla::Plugin::Pinto::Add;

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

my $has_pinto_tester = Class::Load::try_load_class('Pinto::Server::Tester');
plan skip_all => 'Pinto::Server::Tester required' if not $has_pinto_tester;

my $has_pinto_remote = Class::Load::try_load_class('Pinto::Remote');
plan skip_all => 'Pinto::Remote required' if not $has_pinto_remote;

my $has_pintod = File::Which::which('pintod');
plan skip_all => 'pintod required' if not $has_pintod;

#------------------------------------------------------------------------------
# TODO: Most of 01-remote.t and 02-remote.t are identical.  The only difference
# is the use of a local repository vs. a remote one.  So factor out these
# differences and consolidate them into one test script.
#------------------------------------------------------------------------------

sub build_tzil {

  my $dist_ini = simple_ini('GatherDir', 'ModuleBuild', @_);

  return Builder->from_config(
    { dist_root => 'corpus/dist/DZT' },
    { add_files => {'source/dist.ini' => $dist_ini} } );
}

#---------------------------------------------------------------------
# simple release

{

  my $t = Pinto::Server::Tester->new;
  $t->start_server;

  my $root  = $t->server_url;
  my $tzil  = build_tzil( ['Pinto::Add' => {root    => $root, 
                                            pauserc => ''}] );
  $tzil->release;

  $t->registration_ok("AUTHOR/DZT-Sample-0.001/DZT::Sample~0.001/");
}

#---------------------------------------------------------------------
# release to a stack

{

  my $t  = Pinto::Server::Tester->new;
  $t->start_server;

  $t->run_ok('New', {stack => 'test', message => 'New stack'});

  my $root  = $t->pinto->root->stringify;
  my $tzil  = build_tzil( ['Pinto::Add' => {root => $root,
                                            stack => 'test',
                                            pauserc => ''}] );
  $tzil->release;

  $t->registration_ok("AUTHOR/DZT-Sample-0.001/DZT::Sample~0.001/test");
}

#---------------------------------------------------------------------
# read author from pauserc

{
  my $pauserc = File::Temp->new;
  print {$pauserc} "user PAUSEID\n";
  my $pause_file = $pauserc->filename;

  my $t = Pinto::Server::Tester->new;
  $t->start_server;

  my $root  = $t->server_url;
  my $tzil  = build_tzil( ['Pinto::Add' => {root => $root, pauserc => $pause_file}] );

  $tzil->release;

  $t->registration_ok("PAUSEID/DZT-Sample-0.001/DZT::Sample~0.001/");
}

#---------------------------------------------------------------------
# read author from dist.ini

{
  my $t = Pinto::Server::Tester->new;
  $t->start_server;

  my $root  = $t->server_url;
  my $tzil  = build_tzil( ['Pinto::Add' => {root => $root, author => 'AUTHORID'}] );

  $tzil->release;

  $t->registration_ok("AUTHORID/DZT-Sample-0.001/DZT::Sample~0.001/");
}

#---------------------------------------------------------------------
# multiple repositories

{
  my ($t1, $t2) = map {Pinto::Server::Tester->new} (1,2);
  $_->start_server for ($t1, $t2);

  my ($root1, $root2) = map { $_->server_url } ($t1, $t2);
  my $tzil  = build_tzil( ['Pinto::Add' => { root => [$root1, $root2],
                                             author => 'AUTHORID' }] );

  $tzil->release;

  $t1->registration_ok("AUTHORID/DZT-Sample-0.001/DZT::Sample~0.001/");
  $t2->registration_ok("AUTHORID/DZT-Sample-0.001/DZT::Sample~0.001/");
}

#---------------------------------------------------------------------
# one of the repositories is locked -- abort release

{

  diag("You will see some warnings here.  Do not be alarmed.");

  local $Pinto::Locker::LOCKFILE_TIMEOUT = 5;

  my ($t1, $t2) = map {Pinto::Server::Tester->new} (1,2);
  $_->start_server for ($t1, $t2);

  $t2->pinto->repo->lock('EX'); # $t2 is now unavailable!

  my ($root1, $root2) = map { $_->server_url } ($t1, $t2);
  my $tzil  = build_tzil( ['Pinto::Add' => { root => [$root1, $root2],
                                             author => 'AUTHORID' }] );

  my $prompt = "repository at $root2 is not available.  Abort the rest of the release?";

  $tzil->chrome->set_response_for($prompt, 'Y');
  throws_ok { $tzil->release } qr/Aborting/;

  $t1->repository_clean_ok;
  $t2->repository_clean_ok;
}

#---------------------------------------------------------------------
# one of the repositories is locked -- partial release

{

  diag("You will see some warnings here.  Do not be alarmed.");

  local $Pinto::Locker::LOCKFILE_TIMEOUT = 5;

  my ($t1, $t2) = map {Pinto::Server::Tester->new} (1,2);
  $_->start_server for ($t1, $t2);

  $t2->pinto->repo->lock('EX'); # $t2 is now unavailable!

  my ($root1, $root2) = map { $_->server_url } ($t1, $t2);
  my $tzil  = build_tzil( ['Pinto::Add' => { root => [$root1, $root2],
                                             author => 'AUTHORID' }] );

  my $prompt = "repository at $root2 is not available.  Abort the rest of the release?";

  $tzil->chrome->set_response_for($prompt, 'N');
  lives_ok { $tzil->release };

  $t1->registration_ok("AUTHORID/DZT-Sample-0.001/DZT::Sample~0.001/");
  $t2->repository_clean_ok;
}

#---------------------------------------------------------------------
# Clean up after Test::DZil;

eval { rmtree('tmp') } if -e 'tmp';

#------------------------------------------------------------------------------
done_testing;
