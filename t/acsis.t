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
  plan tests => 22;
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
is( $generic_header{'UTDATE'}->mon,      8, "UTDATE month is 8" );
is( $generic_header{'UTDATE'}->mday,    10, "UTDATE day is 10" );
is( $generic_header{'UTSTART'}->year, 2006, "UTSTART year is 2006" );
is( $generic_header{'UTSTART'}->mon,     8, "UTSTART month is 8" );
is( $generic_header{'UTSTART'}->mday,   10, "UTSTART day is 10" );
is( $generic_header{'UTSTART'}->hour,    2, "UTSTART hour is 7" );
is( $generic_header{'UTSTART'}->minute, 37, "UTSTART minute is 37" );
is( $generic_header{'UTSTART'}->second, 16, "UTSTART second is 16" );
is( $generic_header{'UTEND'}->year, 2006, "UTEND year is 2006" );
is( $generic_header{'UTEND'}->mon,     8, "UTEND month is 8" );
is( $generic_header{'UTEND'}->mday,   10, "UTEND day is 10" );
is( $generic_header{'UTEND'}->hour,    2, "UTEND hour is 2" );
is( $generic_header{'UTEND'}->minute, 39, "UTEND minute is 39" );
is( $generic_header{'UTEND'}->second, 59, "UTEND second is 59" );
is( $generic_header{'EXPOSURE_TIME'}, 163, "EXPOSURE_TIME is 163" );
is( $generic_header{'OBSERVATION_MODE'}, "grid_chop_focus", "OBSERVATION_MODE is grid_chop_focus" );
is( $generic_header{'OBSERVATION_ID'}, "acsis_14_20060810T023716", "OBSERVATION_ID is acsis_14_20060810T023716" );
is( $generic_header{'RA_BASE'},  "41.6952181504772", "RA_BASE is 41.6952181504772" );
is( $generic_header{'DEC_BASE'}, "89.2818976564226", "DEC_BASE is 89.2818976564226" );

sub readfits {
  my $file = shift;
  open my $fh, "<", $file or die "Error opening header file $file: $!";
  my @cards = <$fh>;
  close $fh;
  return new Astro::FITS::Header( Cards => \@cards );
}
