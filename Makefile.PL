#!perl

use ExtUtils::MakeMaker;
use File::Spec;

# Copyright (C) 2002-2005 Particle Physics and Astronomy Research Council.
# All Rights Reserved.

# This program is free software; you can redistribute it and/or modify it under
# the terms of the GNU General Public License as published by the Free Software
# Foundation; either version 2 of the License, or (at your option) any later
# version.

# This program is distributed in the hope that it will be useful,but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
# PARTICULAR PURPOSE. See the GNU General Public License for more details.

# You should have received a copy of the GNU General Public License along with
# this program; if not, write to the Free Software Foundation, Inc., 59 Temple
# Place,Suite 330, Boston, MA  02111-1307, USA

my $file = File::Spec->catfile(File::Spec->curdir, "lib", "Astro", 
                               "FITS", "HdrTrans.pm");


WriteMakefile( 
               'NAME'           => 'Astro::FITS::HdrTrans',
               'VERSION_FROM'   => $file,
               'PREREQ_PM'      => { 
                                    Switch => 0,
                                    'Math::Trig' => 0,
                                    'Test::More' => 0,
                                    'Time::Piece' => 0,
                                   },
               'EXE_FILES'      => [qw/ translatehdr /],
               'dist'           => { COMPRESS => "gzip -9f"},
               ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
               ( ABSTRACT_FROM  => $file,
                 AUTHOR         => 'Brad Cavanagh E<lt>b.cavanagh@jach.hawaii.eduE<gt>') : ()),
             );


