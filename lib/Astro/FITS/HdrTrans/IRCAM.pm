# -*-perl-*-

package Astro::FITS::HdrTrans::IRCAM;

=head1 NAME

Astro::FITS::HdrTrans::IRCAM - UKIRT IRCAM translations

=head1 SYNOPSIS

  use Astro::FITS::HdrTrans::IRCAM;

  %gen = Astro::FITS::HdrTrans::IRCAM->translate_from_FITS( %hdr );

=head1 DESCRIPTION

This class provides a generic set of translations that are specific
to the IRCAM camera of the United Kingdom Infrared Telescope.

=cut

use 5.006;
use warnings;
use strict;
use Carp;

# Inherit from UKIRT "Old"
use base qw/ Astro::FITS::HdrTrans::UKIRTOld /;

# Import ROTATION from FITS
use Astro::FITS::HdrTrans::FITS qw/ ROTATION /;

use vars qw/ $VERSION /;

$VERSION = sprintf("%d", q$Revision$ =~ /(\d+)/);

# for a constant mapping, there is no FITS header, just a generic
# header that is constant
my %CONST_MAP = (

		);

# unit mapping implies that the value propogates directly
# to the output with only a keyword name change

# Note that header merging fails with IRCAM in some cases because
# some items are duplicated in the .HEADER and .I1 but using different
# comment strings so the merging routine does not realise they are the
# same header. It is arguably an error that Astro::FITS::Header looks
# at comments.

my %UNIT_MAP = (
		# IRCAM Specific
                OBSERVATION_NUMBER   => 'RUN', # cf OBSNUM
		DEC_TELESCOPE_OFFSET => 'DECOFF',
                DETECTOR_BIAS        => 'DET_BIAS',
		RA_TELESCOPE_OFFSET  => 'RAOFF',
		# Also Michelle + UFTI
		SPEED_GAIN           => 'SPD_GAIN',
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

Returns a pattern match for /^IRCAM\d?/".

=cut

sub this_instrument {
  return qr/^IRCAM\d?/i;
}

=head1 COMPLEX CONVERSIONS

=item B<to_X_REFERENCE_PIXEL>

Specify the reference pixel, which is normally near the frame centre.
Note that offsets for polarimetry are undefined.

=cut

sub to_X_REFERENCE_PIXEL{
  my $self = shift;
  my $FITS_headers = shift;
  my $xref;
  use Data::Dumper; print Dumper($FITS_headers);
# Use the average of the bounds to define the centre.
  if ( exists $FITS_headers->{RDOUT_X1} && exists $FITS_headers->{RDOUT_X2} ) {
    my $xl = $FITS_headers->{RDOUT_X1};
    my $xu = $FITS_headers->{RDOUT_X2};
    $xref = $self->nint( ( $xl + $xu ) / 2 );

# Use a default of the centre of the full array.
  } else {
    $xref = 129;
  }
  return $xref;
}

=item B<from_X_REFERENCE_PIXEL>

Returns CRPIX1.

=cut

sub from_X_REFERENCE_PIXEL {
    my $self = shift;
    my $generic_headers = shift;
    return ("CRPIX1", $generic_headers->("X_REFERENCE_PIXEL"));
}

=item B<to_Y_REFERENCE_PIXEL>

Specify the reference pixel, which is normally near the frame centre.
Note that offsets for polarimetry are undefined.

=cut

sub to_Y_REFERENCE_PIXEL{
  my $self = shift;
  my $FITS_headers = shift;
  my $yref;

# Use the average of the bounds to define the centre.
  if ( exists $FITS_headers->{RDOUT_Y1} && exists $FITS_headers->{RDOUT_Y2} ) {
    my $yl = $FITS_headers->{RDOUT_Y1};
    my $yu = $FITS_headers->{RDOUT_Y2};
    $yref = $self->nint( ( $yl + $yu ) / 2 );

# Use a default of the centre of the full array.
  } else {
    $yref = 129;
  }
  return $yref;
}

=item B<from_X_REFERENCE_PIXEL>

Returns CRPIX2.

=cut

sub from_Y_REFERENCE_PIXEL {
    my $self = shift;
    my $generic_headers = shift;
    return ("CRPIX2", $generic_headers->("Y_REFERENCE_PIXEL"));
}

=item B<to_RA_SCALE>

Pixel scale in degrees.

=cut

sub to_RA_SCALE {
    my $self = shift;
    my $FITS_headers = shift;
    my $pixel_size = $FITS_headers->{PIXELSIZ};
    $pixel_size /= 3600; # arcsec to degrees
    return $pixel_size;
}

=item B<from_RA_SCALE>

Generate the PIXLSIZE header.

=cut

sub from_RA_SCALE {
    my $self = shift;
    my $generic_headers = shift;
    my $scale = abs($generic_headers->{RA_SCALE});
    $scale *= 3600;
    return ("PIXELSIZ", $scale );
}

=item B<to_DEC_SCALE>

Pixel scale in degrees.

=cut

sub to_DEC_SCALE {
    my $self = shift;
    my $FITS_headers = shift;
    my $pixel_size = $FITS_headers->{PIXELSIZ};
    $pixel_size /= 3600; # arcsec to degrees
    return $pixel_size;
}

=item B<from_DEC_SCALE>

Generate the PIXLSIZE header.

=cut

sub from_DEC_SCALE {
    my $self = shift;
    my $generic_headers = shift;
    my $scale = abs($generic_headers->{DEC_SCALE});
    $scale *= 3600;
    return ("PIXELSIZ", $scale );
}

=item B<to_AIRMASS_START>

Airmass at start of observation.

=cut

sub to_AIRMASS_START {
    my $self = shift;
    my $FITS_headers = shift;
    my @am = $self->via_subheader( $FITS_headers, "AMSTART" );
    return ($am[0]);
}

=item B<to_AIRMASS_END>

Airmass at start of observation.

=cut

sub to_AIRMASS_END {
    my $self = shift;
    my $FITS_headers = shift;
    my @am = $self->via_subheader( $FITS_headers, "AMEND" );
    return ($am[-1]);
}

=item B<to_NUMBER_OF_EXPOSURES>

Number of exposures is read from NEXP but this appears in both
the .HEADER and .I1.

=cut

sub to_NUMBER_OF_EXPOSURES {
    my $self = shift;
    my $FITS_headers = shift;
    my @n = $self->via_subheader( $FITS_headers, "NEXP" );
    return ($n[-1]);
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
