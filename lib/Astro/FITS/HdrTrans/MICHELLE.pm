package Astro::FITS::HdrTrans::MICHELLE;

# ---------------------------------------------------------------------------

#+
#  Name:
#    Astro::FITS::HdrTrans::MICHELLE

#  Purposes:
#    Translates FITS headers into and from generic headers for the
#    MICHELLE instrument.

#  Language:
#    Perl module

#  Description:
#    This module converts information stored in a FITS header into
#    and from a set of generic headers

#  Authors:
#    Brad Cavanagh (b.cavanagh@jach.hawaii.edu)
#  Revision:
#     $Id$

#  Copyright:
#     Copyright (C) 2002 Particle Physics and Astronomy Research Council.
#     All Rights Reserved.

#-

# ---------------------------------------------------------------------------

=head1 NAME

Astro::FITS::HdrTrans::MICHELLE - Translate FITS headers into generic
headers and back again

=head1 SYNOPSIS

  %generic_headers = translate_from_FITS(\%FITS_headers);

  %FITS_headers = transate_to_FITS(\%generic_headers);

=head1 DESCRIPTION

Converts information contained in MICHELLE FITS headers to and from
generic headers. See Astro::FITS::HdrTrans for a list of generic
headers.

=cut

# L O A D   M O D U L E S --------------------------------------------------

use strict;
use vars qw/ $VERSION /;

'$Revision$ ' =~ /.*:\s(.*)\s\$/ && ($VERSION = $1);

# P R E D E C L A R A T I O N S --------------------------------------------

our %hdr;

# M E T H O D S ------------------------------------------------------------

=head1 REVISION

$Id$

=head1 METHODS

=over 4

=item B<translate_from_FITS>

Converts a hash containing MICHELLE FITS headers into a hash containing
generic headers.

  %generic_headers = translate_from_FITS(\%FITS_headers);

=back

=cut

sub translate_from_FITS {
  my $FITS_header = shift;
  my %generic_header;

  for my $key ( @Astro::FITS::HdrTrans::generic_headers ) {

    if(exists($hdr{$key}) ) {
      $generic_header{$key} = $FITS_header->{$hdr{$key}};
    } else {
      my $subname = "to_" . $key;
      if(exists(&$subname) ) {
        no strict 'refs'; # EEP!
        $generic_header{$key} = &$subname($FITS_header);
      }
    }
  }
  return %generic_header;

}

=over 4

=item B<translate_to_FITS>

Converts a hash containing generic headers into a hash containing
FITS headers

  %FITS_headers = translate_to_FITS(\%generic_headers);

=back

=cut

sub translate_to_FITS {
  my $generic_header = shift;
  my %FITS_header;

  for my $key ( @Astro::FITS::HdrTrans::generic_headers ) {

    if( exists($hdr{$key}) ) {
      $FITS_header{$hdr{$key}} = $generic_header->{$key};
    } else {
      no strict 'refs'; # EEP EEP!
      my $subname = "from_" . $key;
      if(exists(&$subname) ) {
        my %new = &$subname($generic_header);
        for my $newkey ( keys %new ) {
          $FITS_header{$newkey} = $new{$newkey};
        }
      }
    }
  }

  return %FITS_header;

}

=head1 TRANSLATION METHODS

These methods provide many-to-one mappings between FITS headers and
generic headers. An example of a method defined in this section would
be one that converts UT date and UT hour FITS headers into one combined
UT datetime generic header. These mappings can also use calculations,
for example converting a zenith distance to airmass.

These methods are named backwards from the C<translate_from_FITS> and
C<translate_to_FITS> methods in that we are translating to and from
generic headers. As an example, a method to convert to a generic airmass
header would be named C<to_AIRMASS>.

The format of these methods is C<to_HEADER> and C<from_HEADER>.
C<to_> methods accept a hash reference as an argument and return a scalar
value (typically a string). C<from_> methods accept a hash reference
as an argument and return a hash. All UT datetimes should be in
standard ISO 8601 datetime format, which is C<YYYY-MM-DDThh:mm:ss>.
See http://www.cl.cam.ac.uk/~mgk25/iso-time.html for a brief overview
of ISO 8601. Dates should be in YYYY-MM-DD format.

=over 4

=item B<to_UTSTART>

Converts FITS header values into one unified UT start date value.

=cut

sub to_UTDATE {
  my $FITS_headers = shift;
  my $return;
  if(exists($FITS_headers->{UTDATE})) {
    my $utdate = $FITS_headers->{UTDATE};
    $utdate =~ /(\d{4})(\d{2})(\d{2})/;
    $return = join '-', $1, $2, $3;
  }

  return $return;
}

=item B<from_UTDATE>

Converts UT date in the form C<yyyy-mm-dd> to C<yyyymmdd>.

=back

=cut

sub from_UTDATE {
  my $generic_headers = shift;
  my %return_hash;
  my $date = $generic_headers->{UTDATE};
  $date =~ s/-//g;
  $return_hash{UTDATE} = $date;
  return %return_hash;
}

=item B<to_UTSTART>

Removes the 'Z' from the end of the beginning observation time.

=cut

sub to_UTSTART {
  my $FITS_headers = shift;
  my $return;
  if(exists($FITS_headers->{'DATE-OBS'})) {
    ($return = $FITS_headers->{'DATE-OBS'}) =~ s/Z//;
  }
  return $return;
}

=item B<from_UTSTART>

Adds a 'Z' to the end of the beginning observation time.

=cut

sub from_UTSTART {
  my $generic_headers = shift;
  my %return_hash;
  if(exists($generic_headers->{UTSTART})) {
    $return_hash{'DATE-OBS'} = $generic_headers->{UTSTART} . "Z";
  }
  return %return_hash;
}

=item B<to_UTEND>

Removes the 'Z' from the end of the ending observation time.

=cut

sub to_UTEND {
  my $FITS_headers = shift;
  my $return;
  if(exists($FITS_headers->{'DATE-END'})) {
    ($return = $FITS_headers->{'DATE-END'}) =~ s/Z//;
  }
  return $return;
}

=item B<from_UTEND>

Adds a 'Z' to the end of the ending observation time.

=cut

sub from_UTEND {
  my $generic_headers = shift;
  my %return_hash;
  if(exists($generic_headers->{UTEND})) {
    $return_hash{'DATE-END'} = $generic_headers->{UTEND} . "Z";
  }
  return %return_hash;
}

=head1 VARIABLES

=over 4

=item B<%hdr>

Contains one-to-one mappings between FITS headers and generic headers.
Keys are generic headers, values are FITS headers.

=back

=cut

our %hdr = (
            AIRMASS_START        => "AMSTART",
            AIRMASS_END          => "AMEND",
            CHOP_ANGLE           => "CHPANGLE",
            CHOP_THROW           => "CHPTHROW",
            CONFIGURATION_INDEX  => "CNFINDEX",
            DEC_SCALE            => "PIXELSI",
            DEC_TELESCOPE_OFFSET => "TDECOFF",
            DETECTOR_INDEX       => "DINDEX",
            DETECTOR_READ_TYPE   => "DETMODE",
            EQUINOX              => "EQUINOX",
            EXPOSURE_TIME        => "EXP_TIME",
            FILTER               => "FILTER",
            GAIN                 => "GAIN",
            GRATING_DISPERSION   => "GRATDISP",
            GRATING_NAME         => "GRATNAME",
            GRATING_ORDER        => "GRATORD",
            GRATING_WAVELENGTH   => "GRATPOS",
            INSTRUMENT           => "INSTRUME",
            NSCAN_POSITIONS      => "DETNINCR",
            NUMBER_OF_EXPOSURES  => "NEXP",
            NUMBER_OF_OFFSETS    => "NOFFSETS",
            NUMBER_OF_READS      => "NREADS",
            OBJECT               => "OBJECT",
            OBSERVATION_MODE     => "CAMERA",
            OBSERVATION_NUMBER   => "OBSNUM",
            OBSERVATION_TYPE     => "OBSTYPE",
            RA_SCALE             => "PIXELSI",
            RA_TELESCOPE_OFFSET  => "TRAOFF",
            ROTATION             => "CROTA2",
            SCAN_INCREMENT       => "DETINCR",
            SLIT_ANGLE           => "SLITANG",
            SLIT_NAME            => "SLITNAME",
            SPEED_GAIN           => "SPD_GAIN",
            STANDARD             => "STANDARD",
            TELESCOPE            => "TELESCOP",
            WAVEPLATE_ANGLE      => "WPLANGLE",
            X_DIM                => "DCOLUMNS",
            Y_DIM                => "DROWS",
            X_LOWER_BOUND        => "RDOUT_X1",
            X_UPPER_BOUND        => "RDOUT_X2",
            Y_LOWER_BOUND        => "RDOUT_Y1",
            Y_LOWER_BOUND        => "RDOUT_Y2"
          );

1;
