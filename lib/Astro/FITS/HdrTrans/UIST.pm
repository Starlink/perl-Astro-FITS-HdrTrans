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

# Inherit from UKIRTNew
use base qw/ Astro::FITS::HdrTrans::UKIRTNew /;

use vars qw/ $VERSION /;

$VERSION = sprintf("%d.%03d", q$Revision$ =~ /(\d+)\.(\d+)/);

# for a constant mapping, there is no FITS header, just a generic
# header that is constant
my %CONST_MAP = (

		);

# NULL mappings used to override base class implementations
my @NULL_MAP = qw/ DETECTOR_INDEX /;

# unit mapping implies that the value propogates directly
# to the output with only a keyword name change

my %UNIT_MAP = (
		# UIST specific
		DEC_SCALE            => "PIXLSIZE",
		GRATING_NAME         => "GRISM",
		RA_SCALE             => "PIXLSIZE",
		# Not imaging
		GRATING_DISPERSION   => "DISPERSN",
		GRATING_WAVELENGTH   => "CENWAVL",
		SLIT_ANGLE           => "SLIT_PA",
		SLIT_WIDTH           => "SLITWID",
		# MICHELLE compatible
		DETECTOR_READ_TYPE   => "DET_MODE",
		NUMBER_OF_READS      => "NREADS",
		POLARIMETRY          => "POLARISE",
		SLIT_NAME            => "SLITNAME",
		OBSERVATION_MODE     => "INSTMODE",
		# MICHELLE + WFCAM compatible
		EXPOSURE_TIME        => "EXP_TIME",
		# CGS4 + MICHELLE + WFCAM
		CONFIGURATION_INDEX  => 'CNFINDEX',
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

Returns "UIST".

=cut

sub this_instrument {
  return "UIST";
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
