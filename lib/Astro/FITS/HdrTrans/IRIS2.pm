# -*-perl-*-

package Astro::FITS::HdrTrans::IRIS2;

=head1 NAME

Astro::FITS::HdrTrans::IRIS2 - IRIS-2 Header translations

=head1 SYNOPSIS

  %generic_headers = translate_from_FITS(\%FITS_headers, \@header_array);

  %FITS_headers = transate_to_FITS(\%generic_headers, \@header_array);

=head1 DESCRIPTION

Converts information contained in AAO IRIS2 FITS headers to and from
generic headers. See Astro::FITS::HdrTrans for a list of generic
headers.

=cut

use 5.006;
use warnings;
use strict;
use Carp;

use Math::Trig qw/ acos /;

# Inherit from Base
use base qw/ Astro::FITS::HdrTrans::Base /;

use vars qw/ $VERSION /;

# Note that we use %02 not %03 because of historical reasons
$VERSION = sprintf("%d.%02d", q$Revision$ =~ /(\d+)\.(\d+)/);


# for a constant mapping, there is no FITS header, just a generic
# header that is constant
my %CONST_MAP = (
		 COORDINATE_UNITS => 'degrees',
		);

# NULL mappings used to override base class implementations
my @NULL_MAP = ();

# unit mapping implies that the value propogates directly
# to the output with only a keyword name change

my %UNIT_MAP = (
		CONFIGURATION_INDEX  => "CNFINDEX",
		DEC_BASE             => "DECBASE",
		DEC_TELESCOPE_OFFSET => "DECOFF",
		DETECTOR_INDEX       => "DINDEX",
		DETECTOR_READ_TYPE   => "DETMODE",
		DR_GROUP             => "GRPNUM",
		DR_RECIPE            => "RECIPE",
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
		RA_TELESCOPE_OFFSET  => "RAOFF",
		SCAN_INCREMENT       => "DETINCR",
		SLIT_ANGLE           => "SANGLE",
		SLIT_NAME            => "SLIT",
		SPEED_GAIN           => "SPD_GAIN",
		STANDARD             => "STANDARD",
		TELESCOPE            => "TELESCOP",
		WAVEPLATE_ANGLE      => "WPLANGLE",
		Y_BASE               => "DECBASE",
		X_OFFSET             => "RAOFF",
		Y_OFFSET             => "DECOFF",
		X_DIM                => "DCOLUMNS",
		Y_DIM                => "DROWS",
		X_LOWER_BOUND        => "RDOUT_X1",
		X_UPPER_BOUND        => "RDOUT_X2",
		Y_LOWER_BOUND        => "RDOUT_Y1",
		Y_UPPER_BOUND        => "RDOUT_Y2"
	       );


# Create the translation methods
__PACKAGE__->_generate_lookup_methods( \%CONST_MAP, \%UNIT_MAP, \@NULL_MAP );


=head1 METHODS

=over 4

=item B<this_instrument>

The name of the instrument required to match (case insensitively)
against the INSTRUME/INSTRUMENT keyword to allow this class to
translate the specified headers. Called by the default
C<can_translate> method.

  $inst = $class->this_instrument();

Returns "UFTI".

=cut

sub this_instrument {
  return "IRIS2";
}

=head1 COMPLEX CONVERSIONS

These methods are more complicated than a simple mapping. We have to
provide both from- and to-FITS conversions All these routines are
methods and the to_ routines all take a reference to a hash and return
the translated value (a many-to-one mapping) The from_ methods take a
reference to a generic hash and return a translated hash (sometimes
these are many-to-many)

=over 4

=item B<to_AIRMASS_START>

Converts FITS header value of zenith distance into airmass value.

=cut

sub to_AIRMASS_START {
  my $self = shift;
  my $FITS_headers = shift;
  my $pi = atan2( 1, 1 ) * 4;
  my $return;
  if(exists($FITS_headers->{DSTART})) {
    $return = 1 /  cos( $FITS_headers->{DSTART} * $pi / 180 );
  }

  return $return;

}

=item B<from_AIRMASS_START>

Converts airmass into zenith distance.

=cut

sub from_AIRMASS_START {
  my $self = shift;
  my $generic_headers = shift;
  my %return_hash;
  if(exists($generic_headers->{AIRMASS_START})) {
    $return_hash{DSTART} = acos($generic_headers->{AIRMASS_START});
  }
  return %return_hash;
}

=item B<to_AIRMASS_END>

Converts FITS header value of zenith distance into airmass value.

=cut

sub to_AIRMASS_END {
  my $self = shift;
  my $FITS_headers = shift;
  my $pi = atan2( 1, 1 ) * 4;
  my $return;
  if(exists($FITS_headers->{DEND})) {
    $return = 1 /  cos( $FITS_headers->{DEND} * $pi / 180 );
  }

  return $return;

}

=item B<from_AIRMASS_END>

Converts airmass into zenith distance.

=cut

sub from_AIRMASS_END {
  my $self = shift;
  my $generic_headers = shift;
  my %return_hash;
  if(exists($generic_headers->{AIRMASS_END})) {
    $return_hash{DEND} = acos($generic_headers->{AIRMASS_END});
  }
  return %return_hash;
}

=item B<to_COORDINATE_TYPE>

Converts the C<EQUINOX> FITS header into B1950 or J2000, depending
on equinox value, and sets the C<COORDINATE_TYPE> generic header.

=cut

sub to_COORDINATE_TYPE {
  my $self = shift;
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

=item B<to_UTDATE>

Converts FITS header values into standard UT date value of the form
YYYY-MM-DD.

=cut

sub to_UTDATE {
  my $self = shift;
  my $FITS_headers = shift;
  my $return;
  if(exists($FITS_headers->{UTDATE})) {
    my $utdate = $FITS_headers->{UTDATE};
    $utdate =~ s/:/-/;
    $return = $utdate;
  }

  return $return;
}

=item B<from_UTDATE>

Converts UT date in the form C<yyyy-mm-dd> to C<yyyymmdd>.

=cut

sub from_UTDATE {
  my $self = shift;
  my $generic_headers = shift;
  my %return_hash;
  if(exists($generic_headers->{UTDATE})) {
    my $date = $generic_headers->{UTDATE};
    $date =~ s/-/:/g;
    $return_hash{UTDATE} = $date;
  }
  return %return_hash;
}

=item B<to_OBSERVATION_MODE>

Determines the observation mode from the IR2_SLIT FITS header value. If
this value is equal to "OPEN1", then the observation mode is imaging.
Otherwise, the observation mode is spectroscopy.

=cut

sub to_OBSERVATION_MODE {
  my $self = shift;
  my $FITS_headers = shift;
  my $return;
  if(exists($FITS_headers->{IR2_SLIT})) {
    $return = ($FITS_headers->{IR2_SLIT} eq "OPEN1") ? "imaging" : "spectroscopy";
  }
  return $return;
}

=item B<to_UTSTART>

Converts FITS header UT date/time values for the start of the observation
into an ISO 8601 formatted date.

=cut

sub to_UTSTART {
  my $self = shift;
  my $FITS_headers = shift;
  my $return;
  if(exists($FITS_headers->{UTDATE}) && exists($FITS_headers->{UTSTART})) {
    my $utdate = $FITS_headers->{UTDATE};
    $utdate =~ s/:/-/g;
    $return = $utdate . "T" . $FITS_headers->{UTSTART} . "";
  }
  return $return;
}

=item B<from_UTSTART>

Converts an ISO 8601 formatted date into two FITS headers for IRIS2: IDATE
(in the format YYYYMMDD) and RUTSTART (decimal hours).

=cut

sub from_UTSTART {
  my $self = shift;
  my $generic_headers = shift;
  my %return_hash;
  if(exists($generic_headers->{UTSTART})) {
    my $date = $generic_headers->{UTSTART};
    $date =~ /(\d{4})-(\d\d)-(\d\d)T(\d\d):(\d\d):(\d\d)/;
    my ($year, $month, $day, $hour, $minute, $second) = ($1, $2, $3, $4, $5, $6);
    $return_hash{UTDATE} = join ':', $year, $month, $date;
    $return_hash{UTSTART} = join ':', $hour, $minute, $second;
  }
  return %return_hash;
}

=item B<to_UTEND>

Converts FITS header UT date/time values for the end of the observation into
an ISO 8601-formatted date.

=cut

sub to_UTEND {
  my $self = shift;
  my $FITS_headers = shift;
  my $return;
  if(exists($FITS_headers->{UTDATE}) && exists($FITS_headers->{UTEND})) {
    my $utdate = $FITS_headers->{UTDATE};
    $utdate =~ s/:/-/g;
    $return = $utdate . "T" . $FITS_headers->{UTEND};
  }
  return $return;
}

=item B<from_UTEND>

Converts an ISO 8601 formatted date into two FITS headers for IRIS2: IDATE
(in the format YYYYMMDD) and RUTEND (decimal hours).

=cut

sub from_UTEND {
  my $self = shift;
  my $generic_headers = shift;
  my %return_hash;
  if(exists($generic_headers->{UTEND})) {
    my $date = $generic_headers->{UTEND};
    $date =~ /(\d{4})-(\d\d)-(\d\d)T(\d\d):(\d\d):(\d\d)/;
    my ($year, $month, $day, $hour, $minute, $second) = ($1, $2, $3, $4, $5, $6);
    $return_hash{UTDATE} = join ':', $year, $month, $date;
    $return_hash{UTEND} = join ':', $hour, $minute, $second;
  }
  return %return_hash;
}

=item B<to_X_BASE>

Converts the decimal hours in the FITS header C<RABASE> into
decimal degrees for the generic header C<X_BASE>.

=cut

sub to_X_BASE {
  my $self = shift;
  my $FITS_headers = shift;
  my $return;
  if(exists($FITS_headers->{RABASE})) {
    $return = $FITS_headers->{RABASE} * 15;
  }
  return $return;
}

=item B<from_X_BASE>

Converts the decimal degrees in the generic header C<X_BASE>
into decimal hours for the FITS header C<RABASE>.

=cut

sub from_X_BASE {
  my $self = shift;
  my $generic_headers = shift;
  my %return_hash;
  if(exists($generic_headers->{X_BASE})) {
    $return_hash{'RABASE'} = $generic_headers->{X_BASE} / 15;
  }
  return %return_hash;
}

=item B<to_RA_BASE>

Converts the decimal hours in the FITS header C<RABASE> into
decimal degrees for the generic header C<RA_BASE>.

=cut

sub to_RA_BASE {
  my $self = shift;
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
  my $self = shift;
  my $generic_headers = shift;
  my %return_hash;
  if(exists($generic_headers->{RA_BASE})) {
    $return_hash{'RABASE'} = $generic_headers->{RA_BASE} / 15;
  }
  return %return_hash;
}

=item B<to_ROTATION>

Converts a linear transformation matrix into a single rotation angle. This angle
is measured counter-clockwise from the positive x-axis.

=cut

# ROTATION, X_SCALE, and Y_SCALE conversions courtesy Micah Johnson, from
# the cdelrot.pl script supplied for use with XIMAGE.

sub to_ROTATION {
  my $self = shift;
  my $FITS_headers = shift;
  my $return;
  if(exists($FITS_headers->{CD1_1}) &&
     exists($FITS_headers->{CD1_2}) &&
     exists($FITS_headers->{CD2_1}) &&
     exists($FITS_headers->{CD2_2}) ) {
    my $cd11 = $FITS_headers->{CD1_1};
    my $cd12 = $FITS_headers->{CD1_2};
    my $cd21 = $FITS_headers->{CD2_1};
    my $cd22 = $FITS_headers->{CD2_2};
    my $sgn;
    if( ( $cd11 * $cd22 - $cd12 * $cd21 ) < 0 ) { $sgn = -1; } else { $sgn = 1; }
    my $cdelt1 = $sgn * sqrt( $cd11**2 + $cd21**2 );
    my $sgn2;
    if( $cdelt1 < 0 ) { $sgn2 = -1; } else { $sgn2 = 1; }
    my $rad = 57.2957795131;
    $return = $rad * atan2( -$cd21 / $rad, $sgn2 * $cd11 / $rad );
  }
  return $return;
}

=item B<to_Y_SCALE>

Converts a linear transformation matrix into a pixel scale in the declination
axis. Results are in arcseconds per pixel.

=cut

sub to_Y_SCALE {
  my $self = shift;
  my $FITS_headers = shift;
  my $return;
  if(exists($FITS_headers->{CD1_1}) &&
     exists($FITS_headers->{CD1_2}) &&
     exists($FITS_headers->{CD2_1}) &&
     exists($FITS_headers->{CD2_2}) ) {
    my $cd11 = $FITS_headers->{CD1_1};
    my $cd12 = $FITS_headers->{CD1_2};
    my $cd21 = $FITS_headers->{CD2_1};
    my $cd22 = $FITS_headers->{CD2_2};
    my $sgn;
    if( ( $cd11 * $cd22 - $cd12 * $cd21 ) < 0 ) { $sgn = -1; } else { $sgn = 1; }
    $return = $sgn * sqrt( $cd11**2 + $cd21**2 ) * 3600;
  }
  return $return;
}

=item B<to_X_SCALE>

Converts a linear transformation matrix into a pixel scale in the right
ascension axis. Results are in arcseconds per pixel.

=cut

sub to_X_SCALE {
  my $self = shift;
  my $FITS_headers = shift;
  my $return;
  if(exists($FITS_headers->{CD1_2}) &&
     exists($FITS_headers->{CD2_2}) ) {
    my $cd12 = $FITS_headers->{CD1_2};
    my $cd22 = $FITS_headers->{CD2_2};
    $return = sqrt( $cd12**2 + $cd22**2 ) * 3600;
  }
  return $return;
}

=back

=head1 REVISION

 $Id$

=head1 SEE ALSO

C<Astro::FITS::HdrTrans>, C<Astro::FITS::HdrTrans::Base>.

=head1 AUTHOR

Brad Cavanagh E<lt>b.cavanagh@jach.hawaii.eduE<gt>,
Tim Jenness E<lt>t.jenness@jach.hawaii.eduE<gt>

=head1 COPYRIGHT

Copyright (C) 2002-2005 Particle Physics and Astronomy Research Council.
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
