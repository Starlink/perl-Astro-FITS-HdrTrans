#!perl

use strict;

use Test::More tests => 23;

# Test compilation.
require_ok( 'Astro::FITS::HdrTrans' );

# Set up a test ACSIS header.
my %header = ();
$header{'INSTRUME'} = 'FE_HARPB';
$header{'BACKEND'}  = 'ACSIS';
$header{'DATE-OBS'} = '2006-01-20T07:47:19';
$header{'DATE-END'} = '2006-01-20T07:51:14';
$header{'SAM_MODE'} = 'jiggle  ';
$header{'SW_MODE'}  = 'chop    ';
$header{'OBS_TYPE'} = 'science ';
$header{'DOPPLER'}  = 'radio';
$header{'ZSOURCE'}  = 3.335641063247e-5;
$header{'SPECSYS'}  = 'LSR';

# Translate this header.
my %generic_header = Astro::FITS::HdrTrans::translate_from_FITS( \%header );

isa_ok( $generic_header{'UTDATE'}, "Time::Piece", "UTDATE is Time::Piece" );
is( $generic_header{'UTDATE'}->year, 2006, "UTDATE year is 2006" );
is( $generic_header{'UTDATE'}->mon,     1, "UTDATE month is 1" );
is( $generic_header{'UTDATE'}->mday,   20, "UTDATE day is 20" );
is( $generic_header{'UTSTART'}->year, 2006, "UTSTART year is 2006" );
is( $generic_header{'UTSTART'}->mon,     1, "UTSTART month is 1" );
is( $generic_header{'UTSTART'}->mday,   20, "UTSTART day is 20" );
is( $generic_header{'UTSTART'}->hour,    7, "UTSTART hour is 7" );
is( $generic_header{'UTSTART'}->minute, 47, "UTSTART minute is 47" );
is( $generic_header{'UTSTART'}->second, 19, "UTSTART second is 19" );
is( $generic_header{'UTEND'}->year, 2006, "UTEND year is 2006" );
is( $generic_header{'UTEND'}->mon,     1, "UTEND month is 1" );
is( $generic_header{'UTEND'}->mday,   20, "UTEND day is 20" );
is( $generic_header{'UTEND'}->hour,    7, "UTEND hour is 7" );
is( $generic_header{'UTEND'}->minute, 51, "UTEND minute is 51" );
is( $generic_header{'UTEND'}->second, 14, "UTEND second is 14" );
is( $generic_header{'EXPOSURE_TIME'}, 235, "EXPOSURE_TIME is 235" );
is( $generic_header{'OBSERVATION_MODE'}, "jiggle_chop", "OBSERVATION_MODE is jiggle_chop" );
is( sprintf( "%.5f", $generic_header{'VELOCITY'} ), 9.99967, "VELOCITY (radio) is 9.99967" );
is( $generic_header{'SYSTEM_VELOCITY'}, 'RADLSR', "System velocity is RADLSR" );

# Test optical velocity calculation.
$header{'DOPPLER'}  = 'optical';
%generic_header = Astro::FITS::HdrTrans::translate_from_FITS( \%header );
is( sprintf( "%.5f", $generic_header{'VELOCITY'} ), "10.00000", "VELOCITY (optical) is 10.00000" );

# Test redshift.
$header{'DOPPLER'} = 'redshift';
%generic_header = Astro::FITS::HdrTrans::translate_from_FITS( \%header );
is( $generic_header{'VELOCITY'}, $header{'ZSOURCE'}, "VELOCITY (redshift) is 3.33564...e-5" );
