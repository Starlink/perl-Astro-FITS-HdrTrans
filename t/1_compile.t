#!perl

# This test simply loads all the modules
# it does this by scanning ORAC-DR lib dir for .pm files
# and use'ing each in turn

# It is slow because of the fork required for each separate use

# Copyright (C) 2002-2005 Particle Physics and Astronomy Research Council.
# All Rights Reserved.

# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
# General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place,Suite 330, Boston, MA 02111-1307,
# USA

use strict;
use warnings;
use Test; # Not really needed since we don't use ok()

use File::Find;

our @modules;

# If SKIP_COMPILE_TEST environment variable is set we
# just skip this test because it takes a long time
if (exists $ENV{SKIP_COMPILE_TEST}) {
  print "1..0 # Skip compile tests not required\n";
  exit;
}


# Scan the blib/lib/Astro directory looking for modules


find({ wanted => \&wanted,
       no_chdir => 1,
       }, "blib/lib/Astro");

# Start the tests
plan tests => scalar(@modules);


# Loop through each module and try to run it

$| = 1;

for my $module (@modules) {

  # Try forking. Perl test suite runs 
  # we have to fork because each "use" will contaminate the 
  # symbol table and we want to start with a clean slate.
  my $pid;
  if ($pid = fork) {
    # parent

    # wait for the forked process to complet
    waitpid($pid, 0);

    # Control now back with parent.

  } else {
    # Child
    die "cannot fork: $!" unless defined $pid;
    eval "use $module ();";
    if( $@ ) {
      warn "require failed with '$@'\n";
      print "not ";
    }
    print "ok - $module\n";
    # Must remember to exit from the fork
    exit;
  }
}



# We do this as a separate process else we'll blow the hell
# out of our namespace.
sub compile_module {
    my ($module) = $_[0];
    return scalar `$^X "-Ilib" t/lib/compmod.pl $module` =~ /^ok/;
}



# This determines whether we are interested in the module
# and then stores it in the array @modules

sub wanted {
  my $pm = $_;

  # is it a module
  return unless $pm =~ /\.pm$/;

#  print "pm is $pm\n";



  # Remove the blib/lib (assumes unix!)
  $pm =~ s|^blib/lib/||;

  # Translate / to ::
  $pm =~ s|/|::|g;

  # Remove .pm
  $pm =~ s/\.pm$//;

  push(@modules, $pm);
}
