package Astro::FITS::HdrTrans;

# ---------------------------------------------------------------------------

#+
#  Name:
#    Astro::FITS::HdrTrans

#  Purposes:
#    Translates FITS headers into and from generic headers

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

Astro::FITS::HdrTrans - Translate FITS headers into generic headers and back again

=head1 SYNOPSIS

  %generic_headers = translate_from_FITS(\%FITS_headers);

  %FITS_headers = translate_to_FITS(\%generic_headers);

=head1 DESCRIPTION

Converts information contained in instrument-specific FITS headers to
and from generic headers. A list of generic headers are given at the end
of the module documentation.

=cut

# L O A D   M O D U L E S --------------------------------------------------

use strict;
use vars qw/ $VERSION @generic_headers /;

use Switch;

'$Revision$ ' =~ /.*:\s(.*)\s\$/ && ($VERSION = $1);

# M E T H O D S ------------------------------------------------------------

=head1 REVISION

$Id$

=head1 METHODS

=over 4

=item B<translate_from_FITS>

Converts a hash containing instrument-specific FITS headers into a hash
containing generic headers.

  %generic_headers = translate_from_FITS(\%FITS_headers);

=cut

sub translate_from_FITS {
  my $FITS_header = shift;

  my $instrument;
  my %generic_header;

  # Determine the instrument name so we can use the appropriate subclass
  # for header translations. We're going to apply a little bit of logic
  # in this determination set, since we're not entirely sure at this
  # point which header is going to contain the instrument name.

  # Start out looking at a header named INSTRUME

  if ( ( defined( $FITS_header->{INSTRUME} ) &&
         length( $FITS_header->{INSTRUME} . "" ) != 0 ) ) {
    $instrument = $FITS_header->{INSTRUME};
  } elsif ( ( defined( $FITS_header->{INST} ) &&
              length( $FITS_header->{INST} . "" ) != 0 ) ) {
    $instrument = $FITS_header->{INST};
  } else {

    # We couldn't find an instrument header, so we can't do header
    # translations. Alas.

    die "Could not find instrument header in FITS headers.\n";

  }

  # We should now have an instrument for which we can make header translations.

  # Let's do this in a giant switch statement instead of trying to
  # be fancy and tricky. Yes, this'll get messy when more instruments are
  # added later on...

  switch ( uc( $instrument ) ) {
    case "MICHELLE" {
                     require Astro::FITS::HdrTrans::MICHELLE;
                     %generic_header = Astro::FITS::HdrTrans::MICHELLE::translate_from_FITS($FITS_header);
                    }
    case "UFTI" {
                 require Astro::FITS::HdrTrans::UFTI;
                 %generic_header = Astro::FITS::HdrTrans::UFTI::translate_from_FITS($FITS_header);
                }
    case "CGS4" {
                 require Astro::FITS::HdrTrans::CGS4;
                 %generic_header = Astro::FITS::HdrTrans::CGS4::translate_from_FITS($FITS_header);
                }
    case "IRCAM" {
                  require Astro::FITS::HdrTrans::IRCAM;
                  %generic_header = Astro::FITS::HdrTrans::IRCAM::translate_from_FITS($FITS_header);
                 }
    case "IRIS2" {
                  require Astro::FITS::HdrTrans::IRIS2;
                  %generic_header = Astro::FITS::HdrTrans::IRIS2::translate_from_FITS($FITS_header);
                 }
    else {
      die "Instrument $instrument not currently supported.\n";
    }
  } # end SWITCH

  return %generic_header;

}

=item B<translate_to_FITS>

Converts a hash containing generic headers into one containing
instrument-specific FITS headers.

  %FITS_headers = translate_to_FITS(\%generic_headers);

=cut

sub translate_to_FITS {
  my $generic_header = shift;

  my $instrument;
  my %FITS_header;

  if( ( defined( $generic_header->{INSTRUMENT} ) ) &&
      ( length( $generic_header->{INSTRUMENT} . "" ) != 0 ) ) {

    $instrument = $generic_header->{INSTRUMENT};
  } else {
    die "Instrument not found in header.\n";
  }

  switch ( uc( $instrument ) ) {
    case "MICHELLE" {
                     require Astro::FITS::HdrTrans::MICHELLE;
                     %FITS_header = Astro::FITS::HdrTrans::MICHELLE::translate_to_FITS($generic_header);
                    }
    case "UFTI" {
                 require Astro::FITS::HdrTrans::UFTI;
                 %FITS_header = Astro::FITS::HdrTrans::UFTI::translate_to_FITS($generic_header);
                }
    case "CGS4" {
                 require Astro::FITS::HdrTrans::CGS4;
                 %FITS_header = Astro::FITS::HdrTrans::CGS4::translate_to_FITS($generic_header);
                }
    case "IRCAM" {
                  require Astro::FITS::HdrTrans::IRCAM;
                  %FITS_header = Astro::FITS::HdrTrans::IRCAM::translate_to_FITS($generic_header);
                 }
    case "IRIS2" {
                  require Astro::FITS::HdrTrans::IRIS2;
                  %FITS_header = Astro::FITS::HdrTrans::IRIS2::translate_to_FITS($generic_header);
                 }
    else {
      die "Instrument $instrument not currently supported.\n";
    }
  } # end SWITCH

  return %FITS_header;

}

=back

=head2 B<Variables>

The following variables may be exported, but are not by default.

=over 4

=item B<@generic_headers>

Provides a list of generic headers that may or may not be available in the
generic header hash, depending on if translations were set up for these
headers in the instrument-specific subclasses.

=cut

@generic_headers = qw( AIRMASS_START
                       AIRMASS_END
                       CHOP_ANGLE
                       CHOP_THROW
                       CONFIGURATION_INDEX
                       DEC_BASE
                       DEC_SCALE
                       DEC_TELESCOPE_OFFSET
                       DETECTOR_BIAS
                       DETECTOR_INDEX
                       DETECTOR_READ_TYPE
                       EQUINOX
                       EXPOSURE_TIME
                       FILTER
                       GAIN
                       GRATING_DISPERSION
                       GRATING_NAME
                       GRATING_ORDER
                       GRATING_WAVELENGTH
                       INSTRUMENT
                       MSBID
                       NSCAN_POSITIONS
                       NUMBER_OF_DETECTORS
                       NUMBER_OF_EXPOSURES
                       NUMBER_OF_OFFSETS
                       NUMBER_OF_READS
                       NUMBER_OF_SUBFRAMES
                       OBJECT
                       OBSERVATION_MODE
                       OBSERVATION_NUMBER
                       OBSERVATION_TYPE
                       POLARIMETRY
                       PROJECT
                       RA_BASE
                       RA_SCALE
                       RA_TELESCOPE_OFFSET
                       ROTATION
                       SCAN_INCREMENT
                       SLIT_ANGLE
                       SLIT_NAME
                       SPEED_GAIN
                       STANDARD
                       TELESCOPE
                       UTDATE
                       UTEND
                       UTSTART
                       WAVEPLATE_ANGLE
                       X_DIM
                       Y_DIM
                       X_LOWER_BOUND
                       X_UPPER_BOUND
                       Y_LOWER_BOUND
                       Y_UPPER_BOUND
                     );

=back

=head1 AUTHOR

Brad Cavanagh E<lt>b.cavanagh@jach.hawaii.eduE<gt>

=head1 COPYRIGHT

Copyright (C) 2002 Particle Physics and Astronomy Research Council.
All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
