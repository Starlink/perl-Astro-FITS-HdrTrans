package Astro::FITS::HdrTrans::IRCAM;

# ---------------------------------------------------------------------------

#+
#  Name:
#    Astro::FITS::HdrTrans::IRCAM

#  Purposes:
#    Translates FITS headers into and from generic headers for the
#    IRCAM instrument.

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

Astro::FITS::HdrTrans::IRCAM - Translate FITS headers into generic
headers and back again

=head1 SYNOPSIS

  %generic_headers = translate_from_FITS(\%FITS_headers);

  %FITS_headers = transate_to_FITS(\%generic_headers);

=head1 DESCRIPTION

Converts information contained in IRCAM FITS headers to and from
generic headers. See Astro::FITS::HdrTrans for a list of generic
headers.

=cut

# L O A D   M O D U L E S --------------------------------------------------

use strict;
use vars qw/ $VERSION /;

use Data::Dumper;

'$Revision$ ' =~ /.*:\s(.*)\s\$/ && ($VERSION = $1);

# P R E D E C L A R A T I O N S --------------------------------------------

our %hdr;

# M E T H O D S ------------------------------------------------------------

=head1 REVISION

$Id$

=head1 METHODS

=over 4

=item B<translate_from_FITS>

Converts a hash containing IRCAM FITS headers into a hash containing
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

=item B<to_UTDATE>

Converts FITS header values into standard UT date value of the form
YYYY-MM-DD.

=cut

sub to_UTDATE {
  my $FITS_headers = shift;
  my $return;
  if(exists($FITS_headers->{IDATE})) {
    my $utdate = $FITS_headers->{IDATE};
    $utdate =~ /(\d{4})(\d{2})(\d{2})/;
    $return = join '-', $1, $2, $3;
  }

  return $return;
}

=item B<from_UTDATE>

Converts UT date in the form C<yyyy-mm-dd> to C<yyyymmdd>.

=cut

sub from_UTDATE {
  my $generic_headers = shift;
  my %return_hash;
  if(exists($generic_header->{UTDATE})) {
    my $date = $generic_headers->{UTDATE};
    $date =~ s/-//g;
    $return_hash{IDATE} = $date;
  }
  return %return_hash;
}

=item B<to_UTSTART>

Converts FITS header UT date/time values for the start of the observation
into an ISO 8601 formatted date.

=cut

sub to_UTSTART {
  my $FITS_headers = shift;
  my $return;
  if(exists($FITS_headers->{IDATE}) && exists($FITS_headers->{RUTSTART})) {
    my $uttime;
    my $utdate = $FITS_headers->{IDATE};
    my $utdechour = $FITS_headers->{RUTSTART};
    $utdate =~ /(\d{4})(\d{2})(\d{2})/;
    $utdate = join '-', $1, $2, $3;
    $uthour = int($utdechour);
    $utminute = int( ( $utdechour - $uthour ) * 60 );
    $utsecond = int( ( ( ( $utdechour - $uthour ) * 60 ) - $utminute ) * 60 );
    $uttime = join ':', $uthour, $utminute, $utsecond;
    $return = $utdate . "T" . $uttime;
  }
  return $return;
}

=item B<from_UTSTART>

Converts an ISO 8601 formatted date into two FITS headers for IRCAM: IDATE
(in the format YYYYMMDD) and RUTSTART (decimal hours).

=cut

sub from_UTSTART {
  my $generic_headers = shift;
  my %return_hash;
  if(exists($generic_headers->{UTSTART})) {
    my $date = $generic_headers->{UTSTART};
    $date =~ /(\d{4})-(\d\d)-(\d\d)T(\d\d):(\d\d):(\d\d)/
    my ($year, $month, $day, $hour, $minute, $second) = ($1, $2, $3, $4, $5, $6);
    $return_hash{IDATE} = join '', $year, $month, $date;
    $return_hash{RUTSTART} = $hour + ( $minute / 60 ) + ( $second / 3600 );
  }
  return %return_hash;
}

=item B<to_UTEND>

Converts FITS header UT date/time values for the end of the observation into
an ISO 8601-formatted date.

=cut

sub to_UTEND {
  my $FITS_headers = shift;
  my $return;
  if(exists($FITS_headers->{IDATE}) && exists($FITS_headers->{RUTEND})) {
    my $uttime;
    my $utdate = $FITS_headers->{IDATE};
    my $utdechour = $FITS_headers->{RUTEND};
    $utdate =~ /(\d{4})(\d{2})(\d{2})/;
    $utdate = join '-', $1, $2, $3;
    $uthour = int($utdechour);
    $utminute = int( ( $utdechour - $uthour ) * 60 );
    $utsecond = int( ( ( ( $utdechour - $uthour ) * 60 ) - $utminute ) * 60 );
    $uttime = join ':', $uthour, $utminute, $utsecond;
    $return = $utdate . "T" . $uttime;
  }
  return $return;
}

=item B<from_UTEND>

Converts an ISO 8601 formatted date into two FITS headers for IRCAM: IDATE
(in the format YYYYMMDD) and RUTEND (decimal hours).

=cut

sub from_UTEND {
  my $generic_headers = shift;
  my %return_hash;
  if(exists($generic_headers->{UTEND})) {
    my $date = $generic_headers->{UTEND};
    $date =~ /(\d{4})-(\d\d)-(\d\d)T(\d\d):(\d\d):(\d\d)/
    my ($year, $month, $day, $hour, $minute, $second) = ($1, $2, $3, $4, $5, $6);
    $return_hash{IDATE} = join '', $year, $month, $date;
    $return_hash{RUTEND} = $hour + ( $minute / 60 ) + ( $second / 3600 );
  }
  return %return_hash;
}

=back

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
            CONFIGURATION_INDEX  => "CNFINDEX",
            DEC_BASE             => "DECBASE",
            DEC_TELESCOPE_OFFSET => "DECOFF",
            DETECTOR_INDEX       => "DINDEX",
            DETECTOR_READ_TYPE   => "DETMODE",
            EQUINOX              => "EQUINOX",
            EXPOSURE_TIME        => "DEXPTIME",
            FILTER               => "FILTER",
            GAIN                 => "DEPERDN",
            GRATING_DISPERSION   => "GDISP",
            GRATING_NAME         => "GRATING",
            GRATING_ORDER        => "GORD",
            GRATING_WAVELENGTH   => "GLAMBDA",
            INSTRUMENT           => "INSTRUME",
            NSCAN_POSITIONS      => "DETNINCR",
            NUMBER_OF_EXPOSURES  => "NEXP",
            NUMBER_OF_OFFSETS    => "NOFFSETS",
            OBJECT               => "OBJECT",
            OBSERVATION_NUMBER   => "OBSNUM",
            OBSERVATION_TYPE     => "OBSTYPE",
            RA_BASE              => "RABASE",
            RA_TELESCOPE_OFFSET  => "RAOFF",
            ROTATION             => "CROTA2",
            SCAN_INCREMENT       => "DETINCR",
            SLIT_ANGLE           => "SANGLE",
            SLIT_NAME            => "SLIT",
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
