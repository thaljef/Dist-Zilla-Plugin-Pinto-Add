package Dist::Zilla::Plugin::Pinto::Add::Module::Build;

use strict;
use warnings;

use base 'Module::Build';

#------------------------------------------------------------------------------

sub new {
  my ($class, %args) = @_;

  my $has_pinto        = eval { require Pinto };
  my $has_pinto_remote = eval { require Pinto::Remote };

  if ( !($has_pinto || $has_pinto_remote) ) {

    print <<END_MESSAGE;
#######################################################################
This distribution only provides the front-end of the Dist::Zilla
plugin.  To do anything useful, you also need to install a back-end,
which ships separately.

If you want to release your distribution to a local repository, then
you need to install Pinto.  If you want to release to a remote
repository, then you need to install Pinto::Remote.  Or you can
install both, if you like.
#######################################################################
END_MESSAGE


    $args{requires}->{'Pinto'} = 0
        if $class->y_n('Install Pinto?', 'n');

    $args{requires}->{'Pinto::Remote'} = 0
        if $class->y_n('Install Pinto::Remote?', 'n');

  }

    return $class->SUPER::new(%args);

}

#------------------------------------------------------------------------------

1;

__END__
