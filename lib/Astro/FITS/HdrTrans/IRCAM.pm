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
#     Copyright (C) 2003 Particle Physics and Astronomy Research Council.
#     All Rights Reserved.

#-

# ---------------------------------------------------------------------------

=head1 NAME

Astro::FITS::HdrTrans::IRCAM - Translate FITS headers into generic
headers and back again

=head1 DESCRIPTION

Describes conversions between generic headers and those for the United
Kingdom Infrared Telescope IRCAM infrared camera.

=cut

# L O A D   M O D U L E S --------------------------------------------------

use strict;
use vars qw/ $VERSION /;

$VERSION = '0.02';

require Exporter;

our @ISA = qw/Exporter/;
our @EXPORT_OK = qw( valid_class );
our %EXPORT_TAGS = (
                    'all' => [ qw( @EXPORT_OK ) ],
                   );

# P R E D E C L A R A T I O N S --------------------------------------------

our %hdr;

# M E T H O D S ------------------------------------------------------------

=head1 REVISION

$Id$

=head1 METHODS

These methods provide an interface to the class, allowing the base
class to determine if this class is the appropriate one to use for
the given headers.

=over 4

=item B<valid_class>

  $valid = valid_class( \%headers );

This method takes one argument: a reference to a hash containing
the untranslated headers.

This method returns true (1) or false (0) depending on if the headers
can be translated by this method.

For this class, the method will return true if the B<INSTRUME> header
exists, and its value matches the regular expression C</^ircam/i>, or
if the C<INSTRUMENT> header exists and its value matches the regular
expression C</^ircam$/i>.

=back

=cut

sub valid_class {
  my $headers = shift;

  if( exists( $headers->{'INSTRUME'} ) &&
      defined( $headers->{'INSTRUME'} ) &&
      $headers->{'INSTRUME'} =~ /^ircam/i ) {
    return 1;
  } elsif( exists( $headers->{'INSTRUMENT'} ) &&
           defined( $headers->{'INSTRUMENT'} ) &&
           $headers->{'INSTRUMENT'} =~ /^ircam$/i ) {
    return 1;
  } else {
    return 0;
  }
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
as an argument and return a hash.

=over 4

=item B<to_INST_DHS>

Sets the INST_DHS header.

=cut

sub to_INST_DHS {
  my $FITS_headers = shift;
  my $return;

  if( exists( $FITS_headers->{DHSVER} ) ) {
    $FITS_headers->{DHSVER} =~ /^(\w+)/;
    my $dhs = uc($1);
    $return = $FITS_headers->{INSTRUME} . "_$dhs";
  }

  return $return;

}

=item B<to_COORDINATE_TYPE>

Converts the C<EQUINOX> FITS header into B1950 or J2000, depending
on equinox value, and sets the C<COORDINATE_TYPE> generic header.

=cut

sub to_COORDINATE_TYPE {
  my $FITS_headers = shift;
  my $return;
  if(exists($FITS_headers->{EQUINOX})) {
    if($FITS_headers->{EQUINOX} =~ /1950/) {
      $return = "B1950";
    } elsif ($FITS_headers->{EQUINOX} =~ /2000/) {
      $return = "J2000";
    }
  }
  return $return;
}

=item B<to_COORDINATE_UNITS>

Sets the C<COORDINATE_UNITS> generic header to "degrees".

=cut

sub to_COORDINATE_UNITS {
  "degrees";
}

=item B<to_POLARIMETRY>

=cut

sub to_POLARIMETRY {

}

=item B<to_UTDATE>

Converts FITS header values into C<Time::Piece> object.

=cut

sub to_UTDATE {
  my $FITS_headers = shift;
  my $return;
  if(exists($FITS_headers->{IDATE})) {
    my $utdate = $FITS_headers->{IDATE};
    $return = Time::Piece->strptime( $utdate, "%Y%m%d" );
  }

  return $return;
}

=item B<from_UTDATE>

Converts UT date in C<Time::Piece> object into C<YYYYMMDD> format
for IDATE header.

=cut

sub from_UTDATE {
  my $generic_headers = shift;
  my %return_hash;
  if(exists($generic_headers->{UTDATE})) {
    my $date = $generic_headers->{UTDATE};
    if( ! UNIVERSAL::isa( $date, "Time::Piece" ) ) { return; }
    $return_hash{IDATE} = sprintf("%4d%02d%02d", $date->year, $date->mon, $date->mday);
  }
  return %return_hash;
}

=item B<to_UTSTART>

Converts FITS header UT date/time values for the start of the observation
into a C<Time::Piece> object.

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
    my $uthour = int($utdechour);
    my $utminute = int( ( $utdechour - $uthour ) * 60 );
    my $utsecond = int( ( ( ( $utdechour - $uthour ) * 60 ) - $utminute ) * 60 );
    $uttime = join ':', $uthour, $utminute, $utsecond;
    $return = Time::Piece->strptime( $utdate . "T" . $uttime, "%Y-%m-%dT%T" );
  }
  return $return;
}

=item B<from_UTSTART>

Converts a C<Time::Piece> object into two FITS headers for IRCAM: IDATE
(in the format YYYYMMDD) and RUTSTART (decimal hours).

=cut

sub from_UTSTART {
  my $generic_headers = shift;
  my %return_hash;
  if(exists($generic_headers->{UTSTART})) {
    my $date = $generic_headers->{UTSTART};
    if( ! UNIVERSAL::isa( $date, "Time::Piece" ) ) { return; }
    $return_hash{IDATE} = sprintf("%4d%02d%02d", $date->year, $date->mon, $date->mday);
    $return_hash{RUTSTART} = $date->hour + ( $date->minute / 60 ) + ( $date->second / 3600 );
  }
  return %return_hash;
}

=item B<to_UTEND>

Converts FITS header UT date/time values for the end of the observation into
a C<Time::Piece> object.

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
    my $uthour = int($utdechour);
    my $utminute = int( ( $utdechour - $uthour ) * 60 );
    my $utsecond = int( ( ( ( $utdechour - $uthour ) * 60 ) - $utminute ) * 60 );
    $uttime = join ':', $uthour, $utminute, $utsecond;
    $return = Time::Piece->strptime( $utdate . "T" . $uttime, "%Y-%m-%dT%T" );
  }
  return $return;
}

=item B<from_UTEND>

Converts a C<Time::Piece> object into two FITS headers for IRCAM: IDATE
(in the format YYYYMMDD) and RUTEND (decimal hours).

=cut

sub from_UTEND {
  my $generic_headers = shift;
  my %return_hash;
  if(exists($generic_headers->{UTEND})) {
    my $date = $generic_headers->{UTEND};
    if( ! UNIVERSAL::isa( $date, "Time::Piece" ) ) { return; }
    $return_hash{IDATE} = sprintf("%4d%02d%02d", $date->year, $date->mon, $date->mday);
    $return_hash{RUTEND} = $date->hour + ( $date->minute / 60 ) + ( $date->second / 3600 );
  }
  return %return_hash;
}

=item B<to_RA_BASE>

Converts the decimal hours in the FITS header C<RABASE> into
decimal degrees for the generic header C<RA_BASE>.

=cut

sub to_RA_BASE {
  my $FITS_headers = shift;
  my $return;
  if(exists($FITS_headers->{RABASE})) {
    $return = $FITS_headers->{RABASE} * 15;
  }
  return $return;
}

=item B<from_RA_BASE>

Converts the decimal degrees in the generic header C<RA_BASE>
into decimal hours for the FITS header C<RABASE>.

=cut

sub from_RA_BASE {
  my $generic_headers = shift;
  my %return_hash;
  if( exists( $generic_headers->{RA_BASE} ) &&
      defined( $generic_headers->{RA_BASE} ) ) {
    $return_hash{'RABASE'} = $generic_headers->{RA_BASE} / 15;
  }
  return %return_hash;
}

=back

=head1 VARIABLES

=over 4

=item B<%hdr>

Contains one-to-one mappings between FITS headers and generic headers.
Keys are generic headers, values are FITS headers.

=cut

%hdr = (
            AIRMASS_START        => "AMSTART",
            AIRMASS_END          => "AMEND",
            DEC_BASE             => "DECBASE",
            DEC_SCALE            => "PIXELSIZ",
            DEC_TELESCOPE_OFFSET => "DECOFF",
            DETECTOR_INDEX       => "DINDEX",
            DETECTOR_READ_TYPE   => "MODE",
            DR_GROUP             => "GRPNUM",
            DR_RECIPE            => "DRRECIPE",
            EQUINOX              => "EQUINOX",
            EXPOSURE_TIME        => "DEXPTIME",
            FILTER               => "FILTER",
            GAIN                 => "DEPERDN",
            INSTRUMENT           => "INSTRUME",
            MSBID                => "MSBID",
            NUMBER_OF_EXPOSURES  => "NEXP",
            NUMBER_OF_COADDS     => "NEXP",
            NUMBER_OF_OFFSETS    => "NOFFSETS",
            OBJECT               => "OBJECT",
            OBSERVATION_NUMBER   => "OBSNUM",
            OBSERVATION_TYPE     => "OBSTYPE",
            PROJECT              => "PROJECT",
            RA_SCALE             => "PIXELSIZ",
            RA_TELESCOPE_OFFSET  => "RAOFF",
            ROTATION             => "CROTA2",
            SPEED_GAIN           => "SPD_GAIN",
            STANDARD             => "STANDARD",
            TELESCOPE            => "TELESCOP",
            WAVEPLATE_ANGLE      => "WPLANGLE",
            X_DIM                => "DCOLUMNS",
            Y_DIM                => "DROWS",
            X_LOWER_BOUND        => "RDOUT_X1",
            X_UPPER_BOUND        => "RDOUT_X2",
            Y_LOWER_BOUND        => "RDOUT_Y1",
            Y_UPPER_BOUND        => "RDOUT_Y2"
          );

=back

=head1 AUTHOR

Brad Cavanagh E<lt>b.cavanagh@jach.hawaii.eduE<gt>

=head1 COPYRIGHT

Copyright (C) 2003-2005 Particle Physics and Astronomy Research Council.
All Rights Reserved.

This program is free software; you can redistribute it and/or modify it under
the terms of the GNU General Public License as published by the Free Software
Foundation; either version 2 of the License, or (at your option) any later
version.

This program is distributed in the hope that it will be useful,but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with
this program; if not, write to the Free Software Foundation, Inc., 59 Temple
Place,Suite 330, Boston, MA  02111-1307, USA

=cut

1;
