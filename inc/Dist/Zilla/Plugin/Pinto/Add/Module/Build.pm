package Dist::Zilla::Plugin::Pinto::Add::Module::Build;

use strict;
use warnings;

use base 'Module::Build::CleanInstall';

#------------------------------------------------------------------------------

my $min_pinto_version = 0.082;

sub new {
  my ($class, %args) = @_;

  if (my $home_dir = $ENV{PINTO_HOME}) {

    print "PINTO_HOME is $home_dir\n\n";

    print <<END_MESSAGE;
#######################################################################
Your PINTO_HOME environment variable is set.  Therefore, I'm going to
assume that you have already installed Pinto there and you want me to
build this module against those libraries.  If not, then please unset 
PINTO_HOME and reconfigure this build.
#######################################################################
END_MESSAGE

  }
  elsif( not eval { require Pinto; 1 } ) {

    print <<END_MESSAGE;
#######################################################################
It appears that you do not have Pinto installed in your PERL5LIB and
you have not set the PINTO_HOME environment variable to point to a 
different installation.  To use this module, you'll need to install
Pinto somehow.

I usually recommend installing Pinto as a stand-alone application as 
described in Pinto::Manual::Installing.  You might want to do that first, 
then set PINTO_HOME and come back to install this module afterwards.

Or, I can just have Pinto installed directly into your PERL5LIB
along with all your other Perl modules.  Pinto is a big application,
so it will bring a lot of dependencies into your environment.
#######################################################################
END_MESSAGE


    $args{requires}->{'Pinto'} = $min_pinto_version 
      if $class->y_n('Shall I also install Pinto?', 'n');

  }
  else {

    print <<END_MESSAGE;
#######################################################################
It appears that you have already installed Pinto into your PERl5LIB so
I'm just going to build against that.
#######################################################################
END_MESSAGE

    $args{requires}->{'Pinto'} = $min_pinto_version;
  }

  return $class->SUPER::new(%args);
}

#------------------------------------------------------------------------------

1;

__END__
