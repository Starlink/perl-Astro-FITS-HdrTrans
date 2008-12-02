# -*-perl-*-

package Astro::FITS::HdrTrans::CGS4;

=head1 NAME

Astro::FITS::HdrTrans::CGS4 - UKIRT CGS4 translations

=head1 SYNOPSIS

  use Astro::FITS::HdrTrans::CGS4;

  %gen = Astro::FITS::HdrTrans::CGS4->translate_from_FITS( %hdr );

=head1 DESCRIPTION

This class provides a generic set of translations that are specific
to the CGS4 spectrometer of the United Kingdom Infrared Telescope.

=cut

use 5.006;
use warnings;
use strict;
use Carp;

# Inherit from UKIRT "Old"
use base qw/ Astro::FITS::HdrTrans::UKIRTOld /;

use vars qw/ $VERSION /;

$VERSION = sprintf("%d", q$Revision$ =~ /(\d+)/);

# for a constant mapping, there is no FITS header, just a generic
# header that is constant
my %CONST_MAP = (

		);

# unit mapping implies that the value propogates directly
# to the output with only a keyword name change

my %UNIT_MAP = (
		# CGS4 Specific
		GRATING_DISPERSION   => "GDISP",
		GRATING_NAME         => "GRATING",
		GRATING_ORDER        => "GORDER",
		GRATING_WAVELENGTH   => "GLAMBDA",
		SLIT_ANGLE           => "SANGLE",
		SLIT_NAME            => "SLIT",
		SLIT_WIDTH           => "SWIDTH",
		# MICHELLE compatible
		NSCAN_POSITIONS      => "DETNINCR",
		SCAN_INCREMENT       => "DETINCR",
		# MICHELLE + UIST + WFCAM
		CONFIGURATION_INDEX  => 'CNFINDEX',
	       );


# Create the translation methods
__PACKAGE__->_generate_lookup_methods( \%CONST_MAP, \%UNIT_MAP );

# Im

=head1 METHODS

=over 4

=item B<this_instrument>

The name of the instrument required to match (case insensitively)
against the INSTRUME/INSTRUMENT keyword to allow this class to
translate the specified headers. Called by the default
C<can_translate> method.

  $inst = $class->this_instrument();

Returns "CGS4".

=cut

sub this_instrument {
  return "CGS4";
}

=back

=head1 COMPLEX CONVERSIONS

These methods are more complicated than a simple mapping. We have to
provide both from- and to-FITS conversions All these routines are
methods and the to_ routines all take a reference to a hash and return
the translated value (a many-to-one mapping) The from_ methods take a
reference to a generic hash and return a translated hash (sometimes
these are many-to-many)

=over 4

=item B<to_POLARIMETRY>

Checks the C<FILTER> FITS header keyword for the existance of
'prism'. If 'prism' is found, then the C<POLARIMETRY> generic
header is set to 1, otherwise 0.

=cut

sub to_POLARIMETRY {
  my $self = shift;
  my $FITS_headers = shift;
  my $return;
  if(exists($FITS_headers->{FILTER})) {
    $return = ( $FITS_headers->{FILTER} =~ /prism/i ? 1 : 0);
  }
  return $return;
}

=item B<to_DEC_TELESCOPE_OFFSET>

The header keyword for the Dec telescope offset changed from DECOFF to
TDECOFF on 20050315, so switch on this date to use the proper header.

=cut

sub to_DEC_TELESCOPE_OFFSET {
  my $self = shift;
  my $FITS_headers = shift;
  my $return;
  if( exists( $FITS_headers->{IDATE} ) && defined( $FITS_headers->{IDATE} ) ) {
    if( $FITS_headers->{IDATE} < 20050315 ) {
      $return = $FITS_headers->{DECOFF};
    } else {
      $return = $FITS_headers->{TDECOFF};
    }
  }
  return $return;
}

=item B<from_DEC_TELESCOPE_OFFSET>

The header keyword for the Dec telescope offset changed from DECOFF to
TDECOFF on 20050315, so return the proper keyword depending on observation
date.

=cut

sub from_DEC_TELESCOPE_OFFSET {
  my $self = shift;
  my $generic_headers = shift;
  my %return;
  if( exists( $generic_headers->{UTDATE} ) &&
      defined( $generic_headers->{UTDATE} ) ) {
    my $ut = $generic_headers->{UTDATE};
    if( exists( $generic_headers->{DEC_TELESCOPE_OFFSET} ) &&
        defined( $generic_headers->{DEC_TELESCOPE_OFFSET} ) ) {
      if( $ut < 20050315 ) {
        $return{'DECOFF'} = $generic_headers->{DEC_TELESCOPE_OFFSET};
      } else {
        $return{'TDECOFF'} = $generic_headers->{DEC_TELESCOPE_OFFSET};
      }
    }
  } else {
    if( exists( $generic_headers->{DEC_TELESCOPE_OFFSET} ) &&
        defined( $generic_headers->{DEC_TELESCOPE_OFFSET} ) ) {
      $return{'TDECOFF'} = $generic_headers->{DEC_TELESCOPE_OFFSET};
    }
  }
  return %return;
}

=item B<to_RA_TELESCOPE_OFFSET>

The header keyword for the RA telescope offset changed from RAOFF to
TRAOFF on 20050315, so switch on this date to use the proper header.

=cut

sub to_RA_TELESCOPE_OFFSET {
  my $self = shift;
  my $FITS_headers = shift;
  my $return;
  if( exists( $FITS_headers->{IDATE} ) && defined( $FITS_headers->{IDATE} ) ) {
    if( $FITS_headers->{IDATE} < 20050315 ) {
      $return = $FITS_headers->{RAOFF};
    } else {
      $return = $FITS_headers->{TRAOFF};
    }
  }
  return $return;
}

=item B<from_RA_TELESCOPE_OFFSET>

The header keyword for the RA telescope offset changed from RAOFF to
TRAOFF on 20050315, so return the proper keyword depending on observation
date.

=cut

sub from_RA_TELESCOPE_OFFSET {
  my $self = shift;
  my $generic_headers = shift;
  my %return;
  if( exists( $generic_headers->{UTDATE} ) &&
      defined( $generic_headers->{UTDATE} ) ) {
    my $ut = $generic_headers->{UTDATE};
    if( exists( $generic_headers->{RA_TELESCOPE_OFFSET} ) &&
        defined( $generic_headers->{RA_TELESCOPE_OFFSET} ) ) {
      if( $ut < 20050315 ) {
        $return{'RAOFF'} = $generic_headers->{RA_TELESCOPE_OFFSET};
      } else {
        $return{'TRAOFF'} = $generic_headers->{RA_TELESCOPE_OFFSET};
      }
    }
  } else {
    if( exists( $generic_headers->{RA_TELESCOPE_OFFSET} ) &&
        defined( $generic_headers->{RA_TELESCOPE_OFFSET} ) ) {
      $return{'TRAOFF'} = $generic_headers->{RA_TELESCOPE_OFFSET};
    }
  }
  return %return;
}

=item B<to_DR_RECIPE>

The DR_RECIPE header keyword changed from DRRECIPE to RECIPE on
20081115.

=cut

sub to_DR_RECIPE {
  my $self = shift;
  my $FITS_headers = shift;

  my $recipe = $FITS_headers->{DRRECIPE};

  my $utdate = $self->to_UTDATE( $FITS_headers );

  if( $utdate > 20081115 ) {
    $recipe = $FITS_headers->{RECIPE};
  }
  return $recipe;
}

=item B<from_DR_RECIPE>

The DR_RECIPE header keyword changed from DRRECIPE to RECIPE on
20081115.

=cut

sub from_DR_RECIPE {
  my $self = shift;
  my $generic_headers = shift;

  my $recipe = $generic_headers->{DR_RECIPE};
  my $utdate = $generic_headers->{UTDATE};

  if( $utdate > 20081115 ) {
    return ( "RECIPE" => $recipe );
  } else {
    return ( "DRRECIPE" => $recipe );
  }
}

=item B<to_SAMPLING>

Converts FITS header values in C<DETINCR> and C<DETNINCR> to a single
descriptive string.

=cut

sub to_SAMPLING {
  my $self = shift;
  my $FITS_headers = shift;
  my $return;
  if(exists($FITS_headers->{DETINCR}) && exists($FITS_headers->{DETNINCR})) {
    my $detincr = $FITS_headers->{DETINCR} || 1;
    my $detnincr = $FITS_headers->{DETNINCR} || 1;
    $return = int ( 1 / $detincr ) . 'x' . int ( $detincr * $detnincr );
  }
  return $return;
}

=item B<from_TELESCOPE>

Returns 'UKIRT, Mauna Kea, HI' for the C<TELESCOP> FITS header.

=cut

sub from_TELESCOPE {
  my %return = ( "TELESCOP", "UKIRT, Mauna Kea, HI" );
  return %return;
}

=back

=head1 REVISION

 $Id$

=head1 SEE ALSO

C<Astro::FITS::HdrTrans>, C<Astro::FITS::HdrTrans::UKIRT>.

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
