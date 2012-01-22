package Dist::Zilla::Plugin::Pinto::Add;

# ABSTRACT: Add your dist to a Pinto repository

use Moose;
use Moose::Util::TypeConstraints;

use English qw(-no_match_vars);

use MooseX::Types::Moose qw(Str ArrayRef);
use Pinto::Types qw(AuthorID);

use Class::Load qw();
use Try::Tiny;

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

with qw(Dist::Zilla::Role::Releaser);

#------------------------------------------------------------------------------

class_type('Pinto');
class_type('Pinto::Remote');

#------------------------------------------------------------------------------

sub mvp_multivalue_args { qw(root) }

#------------------------------------------------------------------------------

has root => (
    is         => 'ro',
    isa        => ArrayRef[Str],
    auto_deref => 1,
    required   => 1,
);


has author => (
    is         => 'ro',
    isa        => AuthorID,
    lazy_build => 1,
);


has pintos => (
    is         => 'ro',
    isa        => ArrayRef['Pinto | Pinto::Remote'],
    init_arg   => undef,
    auto_deref => 1,
    lazy_build => 1,
);

#------------------------------------------------------------------------------

sub _build_author {
    my ($self) = @_;

    return $self->_get_pause_id()
           || $self->_get_username()
           || $self->_prompt_for_author_id();
}

#------------------------------------------------------------------------------

sub _build_pintos {
    my ($self) = @_;

    my $version = $self->VERSION();
    my $options = { -version => $version };
    my @pintos  = ();

    for my $root ($self->root) {
        my $type  = $root =~ m{^ http:// }mx ? 'remote'        : 'local';
        my $class = $type eq 'remote'        ? 'Pinto::Remote' : 'Pinto';


        $self->log_fatal("You must install $class-$version to release to a $type repository: $@")
            if not eval { Class::Load::load_class($class, $options); 1 };

        my $pinto = try   { $class->new(root => $root, quiet => 1) }
                    catch { $self->log_fatal($_) };

        push @pintos, $self->_ping_it($pinto) ? $pinto : ();
    }

    $self->log_fatal('none of your repositories are available') if not @pintos;
    return \@pintos;
}

#------------------------------------------------------------------------------

sub _ping_it {
    my ($self, $pinto) = @_;

    my $root  = $pinto->root();
    $self->log("checking if repository at $root is available");

    $pinto->new_batch(noinit => 1);
    $pinto->add_action('Nop');
    my $result = $pinto->run_actions();
    return 1 if $result->is_success();

    my $msg = "repository at $root is not available.  Abort the rest of the release?";
    my $abort  = $self->zilla->chrome->prompt_yn($msg, {default => 'Y'});
    $self->log_fatal('Aborting') if $abort; # dies!
    return 0;
}

#------------------------------------------------------------------------------

sub release {
    my ($self, $archive) = @_;

    for my $pinto ( $self->pintos() ) {

        my $root  = $pinto->root();
        $self->log("adding $archive to repository at $root");

        $pinto->new_batch();
        $pinto->add_action('Add', author => $self->author(), archive => $archive);
        my $result = $pinto->run_actions();

        $result->is_success() ? $self->log("added $archive to $root ok")
                              : $self->log_fatal("failed to add $archive to $root: $result");

        # TODO: Should we try to release to all pintos, even if one fails?
    }

    return 1;
}

#------------------------------------------------------------------------------

sub _get_pause_id {
    my ($self) = @_;
    # TODO: get from stash
    return;
}


#------------------------------------------------------------------------------

sub _get_username {
    my ($self) = @_;

    # Look at typical environment variables
    for my $var ( qw(USERNAME USER LOGNAME) ) {
        return uc $ENV{$var} if $ENV{$var};
    }

    # Try using pwent.  Probably only works on *nix
    if (my $name = getpwuid($REAL_USER_ID)) {
        return uc $name;
    }

    return;
}

#------------------------------------------------------------------------------

sub _prompt_for_author_id {
    my ($self) = @_;

    my $msg = 'What is your author ID?';
    my $id  = uc $self->zilla->chrome->prompt_str->($msg);

    return $id;
}

#------------------------------------------------------------------------------

1;

__END__

=pod

=head1 SYNOPSIS

  # In your dist.ini
  [Pinto::Add]
  root   = http://pinto.my-host         ; at lease one root is required
  author = YOU                          ; optional. defaults to username

  # Then run the release command
  dzil release

=head1 DESCRIPTION

C<Dist::Zilla::Plugin::Pinto::Add> is a release-stage plugin that
will add your distribution to a local or remote L<Pinto> repository.

B<IMPORTANT:> You'll need to install L<Pinto>, or L<Pinto::Remote>, or
both, depending on whether you're going to release to a local or remote
repository.  L<Dist::Zilla::Plugin::Pinto::Add> does not explicitly
depend on either of these modules, so you can decide which one you
want without being forced to have a bunch of other modules that you
won't use.

Before releasing, L<Dist::Zilla::Plugin::Pinto::Add> will check if the
repository is responding.  If not, you'll be prompted whether to abort
the rest of the release.

=head1 CONFIGURATION

The following parameters can be set in the F<dist.ini> file for your
distribution:

=over 4

=item root = REPOSITORY

This identifies the root of the Pinto repository you want to release
to.  If C<REPOSITORY> looks like a URL (i.e. starts with "http://")
then your distribution will be shipped with L<Pinto::Remote>.
Otherwise, the C<REPOSITORY> is assumed to be a path to a local
repository directory.  In that case, your distribution will be shipped
with L<Pinto>.

At least one C<root> is required.  You can release to mutiple
repositories by specifying the C<root> attribute multiple times.  If
any of the repositories are not responding, we will still try to
release to the rest of them (unless you decide to abort the release
altogether).  If none of the repositories are responding, then the
entire release will be aborted.  Any errors returned by one of the
repositories will also cause the rest of the release to be aborted.

=item author = NAME

This specifies your identity as a module author.  It must be
alphanumeric characters (no spaces) and will be forced to UPPERCASE.
If you do not specify one, it defaults to either your PAUSE ID (if you
have one configured elsewhere) or your current username.

=back

=cut
