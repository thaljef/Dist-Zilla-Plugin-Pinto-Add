package Dist::Zilla::Plugin::ReleaseToPinto;

# ABSTRACT: Release your dist to a Pinto repository

use Moose;

use English qw(-no_match_vars);

use MooseX::Types::Moose qw(Str Bool);
use Pinto::Types qw(AuthorID);

use Class::Load qw(load_class);

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

with qw(Dist::Zilla::Role::Releaser);

#------------------------------------------------------------------------------

has repos => (
    is        => 'ro',
    isa       =>  Str,
    required  => 1,
);

has author => (
    is       => 'ro',
    isa      => AuthorID,
    builder  => '_build_author',
    lazy     => 1,
);

has is_remote => (
    is       => 'ro',
    isa      => Bool,
    init_arg => undef,
    default  => sub { return $_[0]->repos() =~ m{^ http://}mx },
    lazy     => 1,
);

#------------------------------------------------------------------------------

sub _build_author {
    my ($self) = @_;

    my $author = $self->get_pause_id() || $self->get_username()
       or $self->fatal('Unable to determine your author ID');

    return $author;
}

#------------------------------------------------------------------------------

sub release {
    my ($self, $archive) = @_;

    my $repos       = $self->repos();
    my $pinto_class = $self->load_pinto();
    my $pinto       = $pinto_class->new( repos => $self->repos() );

    $self->log("Releasing $archive to $repos");

    $pinto->new_action_batch();
    $pinto->add_action('Add', author => $self->author(), dist_file => $archive);
    my $result = $pinto->run_actions();

    if ($result->is_success()) {
        $self->log("Added $archive ok");
        return 1;
    }
    else {
        $self->fatal("Failed to add $archive: " . $result->to_string() );
        return 0;
    }
}

#------------------------------------------------------------------------------

sub load_pinto {
    my ($self) = @_;

    my $pinto_class = $self->is_remote() ? 'Pinto::Remote' : 'Pinto';

    if ( not eval { load_class($pinto_class) } ) {
        my $type = $self->is_remote() ? 'remote' : 'local';
        $self->fatal("You must install $pinto_class to release to a $type repository")
    }

    return $pinto_class;
}

#------------------------------------------------------------------------------

sub get_pause_id {
    my ($self) = @_;
    return;
}


#------------------------------------------------------------------------------

sub get_username {
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

1;

__END__

=pod

=head1 SYNOPSIS

  # In your dist.ini
  [ReleaseToPinto]
  repos  = http://pinto.my-company.com  ; required
  author = YOU                          ; optional. defaults to username

  # Then run the release command
  dzil release

=head1 DESCRIPTION

C<Dist::Zilla::Plugin::ReleaseToPinto> is a release-stage plugin that
will ship your distribution to a local or remote L<Pinto> repository.

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

B<NOTE:> You'll need to install L<Pinto>, or L<Pinto::Remote>, or
both, depending on what kind of repositories you're going to release
to.  L<Dist::Zilla::Plugin::ReleaseToPinto> does not explicitly depend
on either of these modules, so you can decide which one you want
without being forced to have a bunch of other modules.

=item author = NAME

This specifies your identity as a module author.  It must be
alphanumeric characters (no spaces) and will be forced to UPPERCASE.
If you do not specify one, it defaults to either your PAUSE ID (if you
have one configured elsewhere) or your current username.

=back

=cut
