# -*-perl-*-

package Astro::FITS::HdrTrans::UKIRT;

=head1 NAME

Astro::FITS::HdrTrans::UKIRT - Base class for translation of UKIRT instruments

=head1 SYNOPSIS

  use Astro::FITS::HdrTrans::UKIRT;

=head1 DESCRIPTION

This class provides a generic set of translations that are common to
instrumentation from the United Kingdom Infrared Telescope. It should
not be used directly for translation of instrument FITS headers.

=cut

use 5.006;
use warnings;
use strict;
use Carp;

# inherit from the Base translation class and not HdrTrans
# itself (which is just a class-less wrapper)
use base qw/ Astro::FITS::HdrTrans::Base /;

use vars qw/ $VERSION /;

$VERSION = sprintf("%d.%03d", q$Revision$ =~ /(\d+)\.(\d+)/);

# in each class we have three sets of data.
#   - constant mappings
#   - unit mappings
#   - complex mappings

# for a constant mapping, there is no FITS header, just a generic
# header that is constant
my %CONST_MAP = (
		 COORDINATE_UNITS => 'degrees',
		);

# unit mapping implies that the value propogates directly
# to the output with only a keyword name change

my %UNIT_MAP = (
		AIRMASS_START        => "AMSTART",
		AIRMASS_END          => "AMEND",
		DEC_BASE             => "DECBASE",
		DETECTOR_INDEX       => "DINDEX", # Needs subheader
		DR_GROUP             => "GRPNUM",
		EQUINOX              => "EQUINOX",
		FILTER               => "FILTER",
		INSTRUMENT           => "INSTRUME",
		MSBID                => "MSBID",
		NUMBER_OF_EXPOSURES  => "NEXP",
		NUMBER_OF_OFFSETS    => "NOFFSETS",
		OBJECT               => "OBJECT",
		OBSERVATION_NUMBER   => "OBSNUM",
		OBSERVATION_TYPE     => "OBSTYPE",
		PROJECT              => "PROJECT",
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

# Create the translation methods
__PACKAGE__->_generate_lookup_methods( \%CONST_MAP, \%UNIT_MAP );

=head1 COMPLEX CONVERSIONS

These methods are more complicated than a simple mapping. We have to
provide both from- and to-FITS conversions All these routines are
methods and the to_ routines all take a reference to a hash and return
the translated value (a many-to-one mapping) The from_ methods take a
reference to a generic hash and return a translated hash (sometimes
these are many-to-many)

=over 4

=item B<to_COORDINATE_TYPE>

Converts the C<EQUINOX> FITS header into B1950 or J2000, depending
on equinox value, and sets the C<COORDINATE_TYPE> generic header.

  $class->to_COORDINATE_TYPE( \%hdr );

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

=item B<from_COORDINATE_TYPE>

A null translation since EQUINOX is translated separately.

=cut

sub from_COORDINATE_TYPE {
  return ();
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

  %fits = $class->from_RA_BASE( \%generic );

=cut

sub from_RA_BASE {
  my $self = shift;
  my $generic_headers = shift;
  my %return_hash;
  if( exists( $generic_headers->{RA_BASE} ) &&
      defined( $generic_headers->{RA_BASE} ) ) {
    $return_hash{'RABASE'} = $generic_headers->{RA_BASE} / 15;
  }
  return %return_hash;
}

=back

=head1 REVISION

 $Id$

=head1 SEE ALSO

C<Astro::FITS::HdrTrans>, C<Astro::FITS::HdrTrans::Base>

=head1 AUTHOR

Brad Cavanagh E<lt>b.cavanagh@jach.hawaii.eduE<gt>,
Tim Jenness E<lt>t.jenness@jach.hawaii.eduE<gt>.

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
