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
  plan tests => 12;
}

# Test compilation.
require_ok( 'Astro::FITS::HdrTrans' );

# Read the header off disk.
my $datadir = File::Spec->catdir( 't', 'data' );
my $fits = readfits( File::Spec->catfile( $datadir, 'ircam.hdr' ) );
die "Error reading FITS headers from ircam.hdr"
  unless defined $fits;
my %hdr;
tie %hdr, "Astro::FITS::Header", $fits;

# Translate this header.
my %generic_header = Astro::FITS::HdrTrans::translate_from_FITS( \%hdr );

isa_ok( $generic_header{'UTSTART'}, "Time::Piece", "UTSTART is Time::Piece" );
isa_ok( $generic_header{'UTEND'}, "Time::Piece", "UTEND is Time::Piece" );
is( $generic_header{'UTDATE'}, 20020105, "UTDATE is 20020105" );
is( $generic_header{'X_REFERENCE_PIXEL'}, 129, "X_REFERENCE_PIXEL is 129" );
is( $generic_header{'Y_REFERENCE_PIXEL'}, 129, "Y_REFERENCE_PIXEL is 129" );
is( $generic_header{'RA_SCALE'}, -2.25e-5, "RA_SCALE is -2.25e-5" );
is( $generic_header{'DEC_SCALE'}, 2.25e-5, "DEC_SCALE is 2.25e-5" );
is( $generic_header{'AIRMASS_START'}, 1.142, "AIRMASS_START is 1.142" );
is( $generic_header{'AIRMASS_END'}, 1.142, "AIRMASS_END is 1.142" );
is( $generic_header{'NUMBER_OF_EXPOSURES'}, 75, "NUMBER_OF_EXPOSURES is 75" );
is( $generic_header{'SPEED_GAIN'}, "Deepwell", "SPEED_GAIN is \"Deepwell\"" );

sub readfits {
  my $file = shift;
  open my $fh, "<", $file or die "Error opening header file $file: $!";
  my @cards = <$fh>;
  close $fh;
  return new Astro::FITS::Header( Cards => \@cards );
}
