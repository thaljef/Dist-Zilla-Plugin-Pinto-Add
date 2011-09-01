package Dist::Zilla::Plugin::ReleaseToPinto;

# ABSTRACT: Release your dist to a Pinto repository

use Moose;

use MooseX::Types::Moose qw(Str Bool);
use Pinto::Types qw(AuthorID);

use Class::Load qw(load_class);

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

with qw(Dist::Zilla::Role::Releaser);

#------------------------------------------------------------------------------

has 'repos' => (
    is        => 'ro',
    isa       =>  Str,
    required  => 1,
);

has 'author' => (
    is       => 'ro',
    isa      => AuthorID,
    builder  => '_build_author',
    lazy     => 1,
);

has 'is_remote' => (
    is       => 'ro',
    isa      => Bool,
    init_arg => undef,
    default  => sub { return $_[0]->repos() =~ m{^ http://}mx },
    lazy     => 1,
);

#------------------------------------------------------------------------------

sub release {
    my ($self, $archive) = @_;

    my $repos       = $self->repos();
    my $pinto_class = $self->load_pinto();
    my $pinto       = $pinto_class->new( repos => $self->repos() );

    $pinto->new_action_batch();
    $pinto->add_action('Add', author => $self->author(), dist => $archive);
    my $result = $pinto->run_actions();

    if ($result->is_success()) {
        $self->log("Added $archive to $repos");
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

1;


__END__
=pod

=head1 NAME

Dist::Zilla::Plugin::Inject - Inject into a CPAN::Mini mirror

=head1 VERSION

version 0.001

=head1 SYNOPSIS

  # in your dist.ini
  [Inject]
  author_id = EXAMPLE

  # injection is triggered at the release stage
  dzil release

=head1 DESCRIPTION

C<Dist::Zilla::Plugin::Inject> is a release-stage plugin that will inject your distribution into a local or remote L<CPAN::Mini> mirror.

=head1 CONFIGURATION

=head2 Author ID

The only mandatory setting that C<Dist::Zilla::Plugin::Inject> requires is the author id that will be used when injecting the module (C<author_id>).

=head2 Injecting into a local repository

C<Dist::Zilla::Plugin::Inject> uses L<CPAN::Mini::Inject> to inject your distribution into a local L<CPAN::Mini> mirror. Thus, you need to have L<CPAN::Mini::Inject> configured on your machine first. L<CPAN::Mini::Inject> looks for its configuration file in a number of predefined locations (see its docs for details), or you can specify an explicit location via the C<config_file> setting in your C<dist.ini>, e.g.:

  [Inject]
  author_id = EXAMPLE
  config_file = /home/example/.mcpani

=head2 Injecting into a remote repository

If you supply a C<remote_server> setting in your C<dist.ini>, C<Dist::Zilla::Plugin::Inject> will try to inject your distribution into a remote mirror via L<CPAN::Mini::Inject::Remote>. A configured L<CPAN::Mini::Inject::Server> must respond to the address specified in C<remote_server>, e.g.:

  [Inject]
  author_id = EXAMPLE
  remote_server = http://mcpani.example.com/

=for stopwords Shangov

=head1 AUTHOR

Peter Shangov <pshangov@yahoo.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Peter Shangov.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
