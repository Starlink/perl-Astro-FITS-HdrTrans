package Astro::FITS::HdrTrans::SCUBA;

# ---------------------------------------------------------------------------

#+
#  Name:
#    Astro::FITS::HdrTrans::SCUBA

#  Purposes:
#    Translates FITS headers into and from generic headers for the
#    SCUBA instrument.

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

Astro::FITS::HdrTrans::SCUBA - Translate FITS headers into generic
headers and back again

=head1 DESCRIPTION

Converts information contained in SCUBA FITS headers to and from
generic headers. See Astro::FITS::HdrTrans for a list of generic
headers.

=cut

# L O A D   M O D U L E S --------------------------------------------------

use strict;
use vars qw/ $VERSION /;

$VERSION = sprintf("%d.%03d", q$Revision$ =~ /(\d+)\.(\d+)/);

# P R E D E C L A R A T I O N S --------------------------------------------

our %hdr;

# M E T H O D S ------------------------------------------------------------

=head1 REVISION

$Id$

=head1 FUNCTIONS

These functions provide an interface to the class, allowing the base
class to determine if this class is the appropriate one to use for
the given headers.

=over 4

=item B<valid_class>

  $valid = valid_class( \%headers );

This function takes one argument: a reference to a hash containing
the untranslated headers.

This method returns true (1) or false (0) depending on if the headers
can be translated by this method.

For this class, the method will return true if the B<INSTRUME> header
exists, and its value matches the regular expression C</^scuba/i>, or
if the C<INSTRUMENT> header exists and its value matches the regular
expression C</^scuba$/i>.

=back

=cut

sub valid_class {
  my $headers = shift;

  if( exists( $headers->{'INSTRUME'} ) &&
      defined( $headers->{'INSTRUME'} ) &&
      $headers->{'INSTRUME'} =~ /^scuba/i ) {
    return 1;
  } elsif( exists( $headers->{'INSTRUMENT'} ) &&
           defined( $headers->{'INSTRUMENT'} ) &&
           $headers->{'INSTRUMENT'} =~ /^scuba$/i ) {
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
  return "SCUBA_SCUBA";
}


=item B<to_CHOP_COORDINATE_SYSTEM>

Uses the C<CHOP_CRD> FITS header to determine the chopper coordinate
system, and then places that coordinate type in the C<CHOP_COORDINATE_SYSTEM>
generic header.

A FITS header value of 'LO' translates to 'Tracking', 'AZ' translates to
'Alt/Az', and 'NA' translates to 'Focal Plane'. Any other values will return
undef.

=cut

sub to_CHOP_COORDINATE_SYSTEM {
  my $FITS_headers = shift;
  my $return;

  if(exists($FITS_headers->{'CHOP_CRD'})) {
    my $fits_eq = $FITS_headers->{'CHOP_CRD'};
    if( $fits_eq =~ /LO/i ) {
      $return = "Tracking";
    } elsif( $fits_eq =~ /AZ/i ) {
      $return = "Alt/Az";
    } elsif( $fits_eq =~ /NA/i ) {
      $return = "Focal Plane";
    }
  }
  return $return;
}

=item B<to_COORDINATE_TYPE>

Uses the C<CENT_CRD> FITS header to determine the coordinate type
(galactic, B1950, J2000) and then places that coordinate type in
the C<COORDINATE_TYPE> generic header.

=cut

sub to_COORDINATE_TYPE {
  my $FITS_headers = shift;
  my $return;
  if(exists($FITS_headers->{'CENT_CRD'})) {
    my $fits_eq = $FITS_headers->{'CENT_CRD'};
    if( $fits_eq =~ /RB/i ) {
      $return = "B1950";
    } elsif( $fits_eq =~ /RJ/i ) {
      $return = "J2000";
    } elsif( $fits_eq =~ /AZ/i ) {
      $return = "galactic";
    } elsif( $fits_eq =~ /planet/i ) {
      $return = "planet";
    }
  }
  return $return;
}

=item B<to_COORDINATE_UNITS>

Sets the C<COORDINATE_UNITS> generic header to "sexagesimal".

=cut

sub to_COORDINATE_UNITS {
  "sexagesimal";
}

=item B<to_EQUINOX>

Translates EQUINOX header into valid equinox value. The following
translation is done:

=over 4

=item * RB => 1950

=item * RJ => 2000

=item * RD => current

=item * AZ => AZ/EL

=back

=cut

sub to_EQUINOX {
  my $FITS_headers = shift;
  my $return;
  if(exists($FITS_headers->{'CENT_CRD'})) {
    my $fits_eq = $FITS_headers->{'CENT_CRD'};
    if( $fits_eq =~ /RB/i ) {
      $return = "1950";
    } elsif( $fits_eq =~ /RJ/i ) {
      $return = "2000";
    } elsif( $fits_eq =~ /RD/i ) {
      $return = "current";
    } elsif( $fits_eq =~ /AZ/i ) {
      $return = "AZ/EL";
    }
  }
  return $return;
}

=item B<from_EQUINOX>

Translates generic C<EQUINOX> values into SCUBA FITS
equinox values for the C<CENT_CRD> header.

=cut

sub from_EQUINOX {
  my $generic_headers = shift;
  my %return_hash;
  my $return;
  if(exists($generic_headers->{EQUINOX})) {
    my $equinox = $generic_headers->{EQUINOX};
    if( $equinox =~ /1950/ ) {
      $return = 'RB';
    } elsif( $equinox =~ /2000/ ) {
      $return = 'RJ';
    } elsif( $equinox =~ /current/ ) {
      $return = 'RD';
    } elsif( $equinox =~ /AZ\/EL/ ) {
      $return = 'AZ';
    } else {
      $return = $equinox;
    }
  }
  $return_hash{'CENT_CRD'} = $return;
  return %return_hash;
}

=item B<to_NUMBER_OF_OFFSETS>

Always returns 1.

=cut

sub to_NUMBER_OF_OFFSETS {
  1;
}

=item B<to_OBSERVATION_MODE>

Returns C<photometry> if the FITS header value for C<MODE>
is C<PHOTOM>, otherwise returns C<imaging>.

=cut

sub to_OBSERVATION_MODE {
  my $FITS_headers = shift;
  my $return;
  if( defined( $FITS_headers->{'MODE'} ) &&
      $FITS_headers->{'MODE'} =~ /PHOTOM/i ) {
    $return = "photometry";
  } else {
    $return = "imaging";
  }
  return $return;
}

=item B<to_OBSERVATION_TYPE>

Converts the observation type. If the FITS header is equal to
C<PHOTOM>, C<MAP>, C<POLPHOT>, or C<POLMAP>, then the generic
header value is C<OBJECT>. Else, the FITS header value is
copied directly to the generic header value.

=cut

sub to_OBSERVATION_TYPE {
  my $FITS_headers = shift;
  my $return;
  my $mode = $FITS_headers->{'MODE'};
  if( defined( $mode ) && $mode =~ /PHOTOM|MAP|POLPHOT|POLMAP/i) {
    $return = "OBJECT";
  } else {
    $return = $mode;
  }
  return $return;
}

=item B<to_POLARIMETRY>

Sets the C<POLARIMETRY> generic header to 'true' if the
value for the FITS header C<MODE> is 'POLMAP' or 'POLPHOT',
otherwise sets it to 'false'.

=cut

sub to_POLARIMETRY {
  my $FITS_headers = shift;
  my $return;
  my $mode = $FITS_headers->{'MODE'};
  if(defined( $mode ) && $mode =~ /POLMAP|POLPHOT/i) {
    $return = 1;
  } else {
    $return = 0;
  }
  return $return;
}

=item B<to_ROTATION>

Always returns 0.

=cut

sub to_ROTATION {
  0;
}

=item B<to_SLIT_ANGLE>

Always returns 0.

=cut

sub to_SLIT_ANGLE {
  0;
}

=item B<to_SPEED_GAIN>

Always returns C<normal>.

=cut

sub to_SPEED_GAIN {
  "normal";
}

=item B<to_TELESCOPE>

Always returns C<JCMT>.

=cut

sub to_TELESCOPE {
  "JCMT";
}

=item B<to_INSTRUMENT>

Always returns C<SCUBA>.

=cut

sub to_INSTRUMENT {
  "SCUBA";
}

=item B<to_UTDATE>

Converts either the C<UTDATE> or C<DATE> header into a C<Time::Piece> object.

=cut

sub to_UTDATE {
  my $FITS_headers = shift;
  my $return;
  if( exists( $FITS_headers->{'UTDATE'} ) &&
      defined( $FITS_headers->{'UTDATE'} ) ) {
    my $utdate = $FITS_headers->{'UTDATE'};
    $return = Time::Piece->strptime( $utdate, "%Y:%m:%d" );
  } elsif( exists( $FITS_headers->{'DATE'} ) &&
           defined( $FITS_headers->{'DATE'} ) ) {
    my $utdate = $FITS_headers->{'DATE'};
    $return = Time::Piece->strptime( $utdate, "%Y-%m-%dT%T" );
  }
  return $return;
}

=item B<from_UTDATE>

Converts UT date in C<Time::Piece> object into C<YYYY:MM:DD> format
for C<UTDATE> header.

=cut

sub from_UTDATE {
  my $generic_headers = shift;
  my %return_hash;
  if(exists($generic_headers->{UTDATE}) &&
     UNIVERSAL::isa( $generic_headers->{UTDATE}, "Time::Piece" ) ) {
    my $date = $generic_headers->{UTDATE};
    $return_hash{'UTDATE'} = join ':', $date->year, $date->mon, $date->mday;
  }
  return %return_hash;
}

=item B<to_UTSTART>

Combines C<UTDATE> and C<UTSTART> into a unified C<UTSTART>
generic header. If those headers do not exist, uses C<DATE>.

=cut

sub to_UTSTART {
  my $FITS_headers = shift;
  my $return;
  if( exists( $FITS_headers->{'UTDATE'} ) &&
      defined( $FITS_headers->{'UTDATE'} ) ) {

    my $ut = $FITS_headers->{'UTDATE'} . ":" . $FITS_headers->{'UTSTART'};

    # Strip off fractional seconds.
    $ut =~ s/\.\d+$//;

    $return = Time::Piece->strptime( $ut, "%Y:%m:%d:%T" );

  } elsif( exists( $FITS_headers->{'DATE'} ) &&
           defined( $FITS_headers->{'DATE'} ) &&
           $FITS_headers->{'DATE'} =~ /^\d{4}-\d\d-\d\dT\d\d:\d\d:\d\d$/ ) {

    $return = Time::Piece->strptime( $FITS_headers->{'DATE'}, "%Y-%m-%dT%T" );

  }

  return $return;
}

=item B<from_UTSTART>

Converts the unified C<UTSTART> generic header into C<UTDATE>
and C<UTSTART> FITS headers of the form C<YYYY:MM:DD> and C<HH:MM:SS>.

=cut

sub from_UTSTART {
  my $generic_headers = shift;
  my %return_hash;
  if(exists($generic_headers->{UTSTART}) &&
     UNIVERSAL::isa( $generic_headers->{UTSTART}, "Time::Piece" ) ) {
    my $ut = $generic_headers->{UTSTART};
    $return_hash{'UTDATE'} = join ':', $ut->year, $ut->mon, $ut->mday;
    $return_hash{'UTSTART'} = join ':', $ut->hour, $ut->minute, $ut->second;
    $return_hash{'DATE'} = $ut->datetime;
  }
  return %return_hash;
}

=item B<to_UTEND>

Converts the <UTDATE> and C<UTEND> headers into a combined
C<Time::Piece> object.

=cut

sub to_UTEND {
  my $FITS_headers = shift;
  my $return;

  if( exists( $FITS_headers->{'UTDATE'} ) &&
      defined( $FITS_headers->{'UTDATE'} ) ) {

    my $ut = $FITS_headers->{'UTDATE'} . ":" . $FITS_headers->{'UTEND'};

    # Strip off fractional seconds.
    $ut =~ s/\.\d+$//;

    $return = Time::Piece->strptime( $ut, "%Y:%m:%d:%T" );

  }
  return $return;
}

=item B<from_UTEND>

Converts the unified C<UTEND> generic header into C<UTDATE> and
C<UTEND> FITS headers of the form C<YYYY:MM:DD> and C<HH:MM:SS>.

=cut

sub from_UTEND {
  my $generic_headers = shift;
  my %return_hash;
  if(exists($generic_headers->{UTEND}) &&
     UNIVERSAL::isa( $generic_headers->{UTEND}, "Time::Piece" ) ) {
    my $ut = $generic_headers->{UTEND};
    $generic_headers->{UTEND} =~ /(\d{4})-(\d\d)-(\d\d)T(\d\d):(\d\d):(\d\d)/;
    $return_hash{'UTDATE'} = join ':', $ut->year, $ut->mon, $ut->mday;
    $return_hash{'UTEND'} = join ':', $ut->hour, $ut->minute, $ut->second;
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
            BOLOMETERS           => "BOLOMS",
            CHOP_ANGLE           => "CHOP_PA",
            CHOP_THROW           => "CHOP_THR",
            DEC_BASE             => "LAT",
            DEC_TELESCOPE_OFFSET => "MAP_Y",
            DETECTOR_READ_TYPE   => "MODE",
            DR_RECIPE            => "DRRECIPE",
            FILENAME             => "SDFFILE",
            FILTER               => "FILTER",
            GAIN                 => "GAIN",
            MSBID                => "MSBID",
            NUMBER_OF_EXPOSURES  => "EXP_NO",
            OBJECT               => "OBJECT",
            OBSERVATION_NUMBER   => "RUN",
            OBSERVATION_TYPE     => "OBSTYPE",
            POLARIMETER          => "POL_CONN",
            PROJECT              => "PROJ_ID",
            RA_TELESCOPE_OFFSET  => "MAP_X",
            SCAN_INCREMENT       => "SAMPLE_DX",
            SEEING               => "SEEING",
            STANDARD             => "STANDARD",
            TAU                  => "TAU_225",
            X_BASE               => "LONG",
            Y_BASE               => "LAT",
            X_OFFSET             => "MAP_X",
            Y_OFFSET             => "MAP_Y"
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
