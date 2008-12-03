# -*-perl-*-

package Astro::FITS::HdrTrans::UIST;

=head1 NAME

Astro::FITS::HdrTrans::UIST - UKIRT UIST translations

=head1 SYNOPSIS

  use Astro::FITS::HdrTrans::UIST;

  %gen = Astro::FITS::HdrTrans::UIST->translate_from_FITS( %hdr );

=head1 DESCRIPTION

This class provides a generic set of translations that are specific to
the UIST camera and spectrometer of the United Kingdom Infrared
Telescope.

=cut

use 5.006;
use warnings;
use strict;
use Carp;

# Inherit from UIST
use base qw/ Astro::FITS::HdrTrans::UIST /;

use vars qw/ $VERSION /;

$VERSION = sprintf("%d", q$Revision: 15060 $ =~ /(\d+)/);

my %UNIT_MAP = ( DEC_SCALE => "CDELT3",
                 RA_SCALE =>  "CDELT2",


# Create the translation methods
__PACKAGE__->_generate_lookup_methods( \%CONST_MAP, \%UNIT_MAP, \@NULL_MAP );

=head1 METHODS

=over 4

=item B<can_translate>

Returns true if the supplied headers can be handled by this class.

  $cando = $class->can_translate( \%hdrs );

This method returns tru if the INSTRUME header exists and is equal to
'CGS4', and if the DHSVER header exists and is equal to 'UKDHS 2008
Dec 1'.

=cut

sub can_translate {
  my $self = shift;
  my $headers = shift;

  if( exists( $headers->{INSTRUME} ) &&
      uc( $headers->{INSTRUME} ) eq 'CGS4' &&
      exists( $headers->{DHSVER} ) &&
      uc( $headers->{DHSVER} ) eq 'UKDHS 2008 DEC 1' ) {
    return 1;
  }
  return 0;
}

=back

=head1 COMPLEX CONVERSIONS

=over 4

=item B<to_ROTATION>

ROTATION comprises the rotation matrix with respect to flipped axes,
i.e. x corresponds to declination and Y to right ascension.  For other
UKIRT instruments this was not the case, the rotation being defined
in CROTA2.  Here the effective rotation is that evaluated from the
PC matrix with a 90-degree counter-clockwise rotation for the rotated
axes. If there is a PC3_2 header, we assume that we're in spectroscopy
mode and use that instead.

=cut

sub to_ROTATION {
  my $self = shift;
  my $FITS_headers = shift;
  my $rotation;
  if ( exists( $FITS_headers->{PC1_1} ) && exists( $FITS_headers->{PC2_1}) ) {
    my $pc11;
    my $pc21;
    if ( exists ($FITS_headers->{PC3_2} ) && exists( $FITS_headers->{PC2_2} ) ) {

      # We're in spectroscopy mode.
      $pc11 = $FITS_headers->{PC3_2};
      $pc21 = $FITS_headers->{PC2_2};
    } else {

      # We're in imaging mode.
      $pc11 = $FITS_headers->{PC1_1};
      $pc21 = $FITS_headers->{PC2_1};
    }
    my $rad = 57.2957795131;
    $rotation = $rad * atan2( -$pc21 / $rad, $pc11 / $rad ) + 90.0;

  } elsif ( exists $FITS_headers->{CROTA2} ) {
    $rotation =  $FITS_headers->{CROTA2} + 90.0;
  } else {
    $rotation = 90.0;
  }
  return $rotation;
}


=item B<to_X_REFERENCE_PIXEL>

Use the nominal reference pixel if correctly supplied, failing that
take the average of the bounds, and if these headers are also absent,
use a default which assumes the full array.

=cut

sub to_X_REFERENCE_PIXEL{
   my $self = shift;
   my $FITS_headers = shift;
   my $xref;
   if ( exists $FITS_headers->{CRPIX1} ) {
      $xref = $FITS_headers->{CRPIX1};
   } elsif ( exists $FITS_headers->{RDOUT_X1} &&
             exists $FITS_headers->{RDOUT_X2} ) {
      my $xl = $FITS_headers->{RDOUT_X1};
      my $xu = $FITS_headers->{RDOUT_X2};
      $xref = $self->nint( ( $xl + $xu ) / 2 );
   } else {
      $xref = 480;
   }
   return $xref;
}

=item B<from_X_REFERENCE_PIXEL>

Always returns the value as CRPIX1.

=cut

sub from_X_REFERENCE_PIXEL {
   my $self = shift;
   my $generic_headers = shift;
   return ( "CRPIX1", $generic_headers->{"X_REFERENCE_PIXEL"} );
}

=item B<to_Y_REFERENCE_PIXEL>

Use the nominal reference pixel if correctly supplied, failing that
take the average of the bounds, and if these headers are also absent,
use a default which assumes the full array.

=cut

sub to_Y_REFERENCE_PIXEL{
   my $self = shift;
   my $FITS_headers = shift;
   my $yref;
   if ( exists $FITS_headers->{CRPIX2} ) {
      $yref = $FITS_headers->{CRPIX2};
   }  elsif ( exists $FITS_headers->{RDOUT_Y1} && 
              exists $FITS_headers->{RDOUT_Y2} ) {
      my $yl = $FITS_headers->{RDOUT_Y1};
      my $yu = $FITS_headers->{RDOUT_Y2};
      $yref = $self->nint( ( $yl + $yu ) / 2 );
   } else {
      $yref = 480;
   }
   return $yref;
}

=item B<from_Y_REFERENCE_PIXEL>

Always returns the value as CRPIX2.

=cut

sub from_Y_REFERENCE_PIXEL {
   my $self = shift;
   my $generic_headers = shift;
   return ( "CRPIX2", $generic_headers->{"Y_REFERENCE_PIXEL"} );
}

=back

=head1 REVISION

 $Id: UIST.pm 15060 2008-03-15 05:18:41Z mjc $

=head1 SEE ALSO

C<Astro::FITS::HdrTrans>, C<Astro::FITS::HdrTrans::UKIRT>.

=head1 AUTHOR

Malcolm J. Currie E<lt>mjc@star.rl.ac.ukE<gt>
Brad Cavanagh E<lt>b.cavanagh@jach.hawaii.eduE<gt>,
Tim Jenness E<lt>t.jenness@jach.hawaii.eduE<gt>.

=head1 COPYRIGHT

Copyright (C) 2008 Science and Technology Facilities Council.
Copyright (C) 2003-2005 Particle Physics and Astronomy Research Council.
All Rights Reserved.

This program is free software; you can redistribute it and/or modify it under
the terms of the GNU General Public License as published by the Free Software
Foundation; either Version 2 of the License, or (at your option) any later
version.

This program is distributed in the hope that it will be useful,but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with
this program; if not, write to the Free Software Foundation, Inc., 59 Temple
Place, Suite 330, Boston, MA  02111-1307, USA.

=cut

1;
