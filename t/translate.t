#!perl
# Testing translation to and from FITS headers.

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

use Test::More tests => 15;

# Test compilation.
require_ok( 'Astro::FITS::HdrTrans' );

# Test push_class with array ref.
my @test_classes = qw/ IRIS2 INGRID /;

my $push_array_return = Astro::FITS::HdrTrans::push_class( \@test_classes );

ok( $push_array_return, "push_class with array ref" );

# Test push_class with scalar.
my $test_class = "ISAAC";

my $push_scalar_return = Astro::FITS::HdrTrans::push_class( $test_class );

ok( $push_scalar_return, "push_class with scalar" );

# Set up a test header.

my %test_header_1 = ();
$test_header_1{'INSTRUME'} = 'IRCAM';
$test_header_1{'OBJECT'} = 'MARS';
$test_header_1{'OBSNUM'} = '25';
$test_header_1{'IDATE'} = '20030301';
$test_header_1{'RUTSTART'} = "9.5333334";
$test_header_1{'RUTEND'} = "9.5416667";

# Test header translation for test_header_1.

my %generic_header_1 = Astro::FITS::HdrTrans::translate_from_FITS( \%test_header_1 );

isa_ok( $generic_header_1{'UTDATE'}, 'Time::Piece', "UTDATE" );

is( $generic_header_1{'UTDATE'}->year, 2003, "UTDATE year is 2003" );

is( $generic_header_1{'UTEND'}->minute, 32, "UTEND minute is 32" );

is( $generic_header_1{'OBJECT'}, 'MARS', "OBJECT is MARS" );

# Test header translation for test_header_1, using an test_ prefix.

my %generic_header_2 = Astro::FITS::HdrTrans::translate_from_FITS( \%test_header_1,
                                                                   prefix => 'test_' );

isa_ok( $generic_header_2{'test_UTDATE'}, 'Time::Piece', "test_UTDATE" );

is( $generic_header_2{'test_UTDATE'}->year, 2003, "test_UTDATE year is 2003");

is( $generic_header_2{'test_UTEND'}->minute, 32, "test_UTEND minute is 32" );

is( $generic_header_2{'test_OBJECT'}, 'MARS', "test_OBJECT is MARS" );

# Test going backwards from %generic_header_1.

my %FITS_header_1 = Astro::FITS::HdrTrans::translate_to_FITS( \%generic_header_1 );

is( $FITS_header_1{'IDATE'}, 20030301, "IDATE is 20030301" );

cmp_ok( abs( $FITS_header_1{'RUTSTART'} - 9.5333 ), '<', 0.0001, "RUTSTART is \"close\" to 9.5333" );

# Test going backwards from %generic_header_2, which includes a prefix.

my %FITS_header_2 = Astro::FITS::HdrTrans::translate_to_FITS( \%generic_header_2,
                                                              prefix => 'test_' );

is( $FITS_header_2{'IDATE'}, 20030301, "IDATE is 20030301, test_ prefix" );

cmp_ok( abs( $FITS_header_2{'RUTSTART'} - 9.5333 ), '<', 0.0001, "RUTSTART is \"close\" to 9.5333, test_ prefix" );
