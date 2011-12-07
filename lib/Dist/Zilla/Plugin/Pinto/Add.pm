package Dist::Zilla::Plugin::Pinto::Add;

# ABSTRACT: Add your dist to a Pinto repository

use Moose;
use Moose::Util::TypeConstraints;

use English qw(-no_match_vars);

use MooseX::Types::Moose qw(Str);
use Pinto::Types qw(AuthorID);

use Class::Load qw();

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

with qw(Dist::Zilla::Role::Releaser);

#------------------------------------------------------------------------------

class_type('Pinto');
class_type('Pinto::Remote');

#------------------------------------------------------------------------------

has repos => (
    is        => 'ro',
    isa       =>  Str,
    required  => 1,
);

has author => (
    is         => 'ro',
    isa        => AuthorID,
    lazy_build => 1,
);

has pinto => (
    is         => 'ro',
    isa        => 'Pinto | Pinto::Remote',
    init_arg   => undef,
    lazy_build => 1,
);

#------------------------------------------------------------------------------

sub _build_author {
    my ($self) = @_;

    my $author = $self->_get_pause_id() || $self->_get_username()
       || $self->log_fatal('Unable to determine your author ID');

    return $author;
}

#------------------------------------------------------------------------------

sub _build_pinto {
    my ($self) = @_;

    my $repos = $self->repos();
    my $type  = $repos =~ m{^ http:// }mx ? 'remote'        : 'local';
    my $pinto_class = $type eq 'remote'   ? 'Pinto::Remote' : 'Pinto';

    $self->log_fatal("uou must install $pinto_class to release to a $type repository")
      if not eval { Class::Load::load_class($pinto_class); 1 };

    return $pinto_class->new(repos => $repos, quiet => 1);
}

#------------------------------------------------------------------------------

sub release {
    my ($self, $archive) = @_;

    return $self->_ping() && $self->_release($archive);
}

#------------------------------------------------------------------------------

sub _ping {
    my ($self) = @_;

    my $pinto = $self->pinto();
    my $repos = $pinto->config->repos();
    $self->log("checking if repository at $repos is available");

    $pinto->new_batch(noinit => 1);
    $pinto->add_action('Nop');
    my $result = $pinto->run_actions();
    return 1 if $result->is_success();

    my $msg = "repository at $repos is not available.  Abort the rest of the release?";
    my $abort  = $self->zilla->chrome->prompt_yn($msg, {default => 'Y'});
    $self->log_fatal('Aborting') if $abort;

    return 0;
}

#------------------------------------------------------------------------------

sub _release {
    my ($self, $archive) = @_;

    my $pinto = $self->pinto();
    my $repos = $pinto->config->repos();
    $self->log("adding $archive to repository at $repos");

    $pinto->new_batch();
    $pinto->add_action('Add', author => $self->author(), archive => $archive);
    my $result = $pinto->run_actions();

    if ($result->is_success()) {
        $self->log("added $archive ok");
        return 1;
    }
    else {
        $self->log_fatal("failed to add $archive: " . $result->to_string() );
        return 0;
    }
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

    # TODO: prompt?
    return;
}

#------------------------------------------------------------------------------

1;

__END__

=pod

=head1 SYNOPSIS

  # In your dist.ini
  [Pinto::Add]
  repos  = http://pinto.my-company.com  ; required
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
repository is available.  If not, you'll be prompted whether to abort
the rest of the release.

=head1 CONFIGURATION

The following parameters can be set in the F<dist.ini> file for your
distribution:

=over 4

=item repos = REPOSITORY

This identifies the Pinto repository you want to release to.  If
C<REPOSITORY> looks like a URL (i.e. starts with "http://") then your
distribution will be shipped with L<Pinto::Remote>.  Otherwise, the
C<REPOSITORY> is assumed to be a path to a local repository directory.
In that case, your distribution will be shipped with L<Pinto>.

=item author = NAME

This specifies your identity as a module author.  It must be
alphanumeric characters (no spaces) and will be forced to UPPERCASE.
If you do not specify one, it defaults to either your PAUSE ID (if you
have one configured elsewhere) or your current username.

=back

=cut
