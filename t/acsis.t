#!perl

use 5.006;
use strict;
use warnings;

use Test::More;
use File::Spec;

# Load Astro::FITS::Header if we can.
eval {
  require Astro::FITS::Header;
};
if( $@ ) {
  plan skip_all => 'Test requires Astro::FITS::Header module';
} else {
  plan tests => 20;
}

# Test compilation.
require_ok( 'Astro::FITS::HdrTrans' );

# Read the header off disk.
my $datadir = File::Spec->catdir( 't', 'data' );
my $fits = readfits( File::Spec->catfile( $datadir, 'acsis.hdr' ) );
die "Error reading FITS headers from acsis.hdr"
  unless defined $fits;
my %hdr;
tie %hdr, "Astro::FITS::Header", $fits;

# Translate this header.
my %generic_header = Astro::FITS::HdrTrans::translate_from_FITS( \%hdr );

isa_ok( $generic_header{'UTDATE'}, "Time::Piece", "UTDATE is Time::Piece" );
is( $generic_header{'UTDATE'}->year, 2006, "UTDATE year is 2006" );
is( $generic_header{'UTDATE'}->mon,     7, "UTDATE month is 1" );
is( $generic_header{'UTDATE'}->mday,   14, "UTDATE day is 20" );
is( $generic_header{'UTSTART'}->year, 2006, "UTSTART year is 2006" );
is( $generic_header{'UTSTART'}->mon,     7, "UTSTART month is 1" );
is( $generic_header{'UTSTART'}->mday,   14, "UTSTART day is 20" );
is( $generic_header{'UTSTART'}->hour,    2, "UTSTART hour is 7" );
is( $generic_header{'UTSTART'}->minute, 17, "UTSTART minute is 47" );
is( $generic_header{'UTSTART'}->second, 15, "UTSTART second is 19" );
is( $generic_header{'UTEND'}->year, 2006, "UTEND year is 2006" );
is( $generic_header{'UTEND'}->mon,     7, "UTEND month is 1" );
is( $generic_header{'UTEND'}->mday,   14, "UTEND day is 20" );
is( $generic_header{'UTEND'}->hour,    2, "UTEND hour is 7" );
is( $generic_header{'UTEND'}->minute, 21, "UTEND minute is 51" );
is( $generic_header{'UTEND'}->second,  7, "UTEND second is 14" );
is( $generic_header{'EXPOSURE_TIME'}, 232, "EXPOSURE_TIME is 235" );
is( $generic_header{'OBSERVATION_MODE'}, "jiggle_chop", "OBSERVATION_MODE is jiggle_chop" );
is( $generic_header{'OBSERVATION_ID'}, "acsis_1_20060714T021715", "OBSERVATION_ID is acsis_1_20060714T021715" );



sub readfits {
  my $file = shift;
  open my $fh, "<", $file or die "Error opening header file $file: $!";
  my @cards = <$fh>;
  close $fh;
  return new Astro::FITS::Header( Cards => \@cards );
}
