package Astro::FITS::HdrTrans::JCMT_GSD_DB;

# ---------------------------------------------------------------------------

#+
#  Name:
#    Astro::FITS::HdrTrans::JCMT_GSD_DB

#  Purposes:
#    Translates FITS headers into and from generic headers for the
#    heterodyne instruments using the GSD file format at JCMT.

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

Astro::FITS::HdrTrans::JCMT_GSD_DB - Translantes FITS headers into
generic headers and back again.

=head1 DESCRIPTION

Converts information contained in JCMT heterodyne database headers
to and from generic headers. See Astro::FITS::HdrTrans for a list of
generic headers.

=cut

# L O A D   M O D U L E S --------------------------------------------------

use strict;
use vars qw/ $VERSION /;

$VERSION = '0.01';

use Time::Piece;

# P R E D E C L A R A T I O N S --------------------------------------------

our %hdr;

# M E T H O D S ------------------------------------------------------------

=head1 REVISION

$Id$

=head1 METHODS

These methods provide an interface to the class, allowing the base
class to determine if this class is the appropriate one to use for
the given headers

=over 4

=item B<valid_class>

  $valid = valid_class( \%headers );

This method takes one argument: a reference to a hash containing the
untranslated headers.

This method returns true (1) or false (0) depending on if the headers
can be translated by this method.

For this class, the method will return true if the B<FRONTEND> header exists
and matches the regular expression C</^rx(a|b|w)/i>.

=back

=cut

sub valid_class {
  my $headers = shift;

  if( exists( $headers->{'FRONTEND'} ) &&
      defined( $headers->{'FRONTEND'} ) &&
      ( $headers->{'FRONTEND'} =~ /^rx(a|b|w)/i ||
        $headers->{'FRONTEND'} =~ /^fts/i ) ) {
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
  return "HET_GSD";
}

=item B<to_INSTRUMENT>

Sets the C<INSTRUMENT> generic header. For RxA3i, sets the value
to RXA3.

=cut

sub to_INSTRUMENT {
  my $FITS_headers = shift;
  my $return;

  if( exists( $FITS_headers->{'FRONTEND'} ) ) {
    $return = $FITS_headers->{'FRONTEND'};
    if( $return =~ /^rxa3/i ) {
      $return = "RXA3";
    } elsif( $return =~ /^rxb/i ) {
      $return = "RXB3";
    }
  }
  return $return;
}

=item B<to_COORDINATE_UNITS>

Sets the C<COORDINATE_UNITS> generic header to "decimal".

=cut

sub to_COORDINATE_UNITS {
  "decimal";
}

=item B<to_EQUINOX>

Sets the C<EQUINOX> generic header to "current".

=cut

sub to_EQUINOX {
  "current";
}

=item B<to_TELESCOPE>

Sets the C<TELESCOPE> generic header to "JCMT".

=cut

sub to_TELESCOPE {
  "JCMT";
}

=item B<to_UTDATE>

Translates the C<LONGDATE> header into a C<Time::Piece> object.

=cut

sub to_UTDATE {
  my $FITS_headers = shift;

  # The UT header is in Sybase format, which is something like
  # "Mar 15 2002  7:04:35:234AM   ". We first need to remove the number
  # of milliseconds, then the whitespace at the end, then use the
  # "%b%t%d%t%Y%t%T%p" format.

  my $return;

  if( exists( $FITS_headers->{'LONGDATE'} ) ) {
    my $longdate = $FITS_headers->{'LONGDATE'};
    $longdate =~ s/:\d\d\d//;
    $longdate =~ s/\s*$//;
    $return = Time::Piece->strptime( $longdate,
                                     "%b%t%d%t%Y%t%I:%M:%S%p" );
  }

 return $return;
}

=item B<to_UTSTART>

Translates the C<LONGDATE> header into a C<Time::Piece> object.

=cut

sub to_UTSTART {
  my $FITS_headers = shift;

  # The UT header is in Sybase format, which is something like
  # "Mar 15 2002  7:04:35:234AM   ". We first need to remove the number
  # of milliseconds, then the whitespace at the end, then use the
  # "%b%t%d%t%Y%t%I:%M:%S%p" format.

  my $return;

  if( exists( $FITS_headers->{'LONGDATE'} ) ) {
    my $longdate = $FITS_headers->{'LONGDATE'};
    $longdate =~ s/:\d\d\d//;
    $longdate =~ s/\s*$//;
    $return = Time::Piece->strptime( $longdate,
                                     "%b%t%d%t%Y%t%I:%M:%S%p" );
  }

  return $return;
}

=item B<to_UTEND>

Translates the C<LONGDATE> header into a C<Time::Piece> object.

=cut

sub to_UTEND {
  my $FITS_headers = shift;

  # The UT header is in Sybase format, which is something like
  # "Mar 15 2002  7:04:35:234AM   ". We first need to remove the number
  # of milliseconds, then the whitespace at the end, then use the
  # "%b%t%d%t%Y%t%I:%M:%S%p" format.

  my ($return, $expt);

  if( exists( $FITS_headers->{'LONGDATE'} ) ) {
    my $longdate = $FITS_headers->{'LONGDATE'};
    $longdate =~ s/:\d\d\d//;
    $longdate =~ s/\s*$//;
    $return = Time::Piece->strptime( $longdate,
                                     "%b%t%d%t%Y%t%I:%M:%S%p" );
  }

  $expt = to_EXPOSURE_TIME( $FITS_headers );

  $return += $expt;

  return $return;

}

=item B<to_EXPOSURE_TIME>

=cut

sub to_EXPOSURE_TIME {
  my $FITS_headers = shift;
  my $expt = 0;

  if( exists( $FITS_headers->{'OBSMODE'} ) && defined( $FITS_headers->{'OBSMODE'} ) ) {

    my $obsmode = uc( $FITS_headers->{'OBSMODE'} );

    if( $obsmode eq 'RASTER' ) {

      if( exists( $FITS_headers->{'NSCAN'} ) && defined( $FITS_headers->{'NSCAN'} ) &&
          exists( $FITS_headers->{'CYCLLEN'} ) && defined( $FITS_headers->{'CYCLLEN'} ) &&
          exists( $FITS_headers->{'NOCYCPTS'} ) && defined( $FITS_headers->{'NOCYCPTS'} ) ) {

        my $nscan = $FITS_headers->{'NSCAN'};
        my $cycllen = $FITS_headers->{'CYCLLEN'};
        my $nocycpts = $FITS_headers->{'NOCYCPTS'};

        # raster.
        $expt = 15 + $nscan * $cycllen * ( 1 + 1 / sqrt( $nocycpts ) ) * 1.4;
      }
    } elsif( $obsmode eq 'PATTERN' or $obsmode eq 'GRID' ) {

      my $swmode = '';

      if( exists( $FITS_headers->{'SWMODE'} ) && defined( $FITS_headers->{'SWMODE'} ) ) {
        $swmode = $FITS_headers->{'SWMODE'};
      } else {
        $swmode = 'BEAMSWITCH';
      }

      if( exists( $FITS_headers->{'NSCAN'} ) && defined( $FITS_headers->{'NSCAN'} ) &&
          exists( $FITS_headers->{'NCYCLE'} ) && defined( $FITS_headers->{'NCYCLE'} ) &&
          exists( $FITS_headers->{'CYCLLEN'} ) && defined( $FITS_headers->{'CYCLLEN'} ) ) {

        my $nscan = $FITS_headers->{'NSCAN'};
        my $ncycle = $FITS_headers->{'NCYCLE'};
        my $cycllen = $FITS_headers->{'CYCLLEN'};

        if( $swmode eq 'POSITION_SWITCH' ) {

          # position switch pattern/grid.
          $expt = 6 + $nscan * $ncycle * $cycllen * 1.35;

        } elsif( $swmode eq 'BEAMSWITCH' ) {

          # beam switch pattern/grid.
          $expt = 6 + $nscan * $ncycle * $cycllen * 1.35;

        } elsif( $swmode eq 'CHOPPING' ) {
          if( exists( $FITS_headers->{'FRONTEND'} ) && defined( $FITS_headers->{'FRONTEND'} ) ) {
            my $frontend = uc( $FITS_headers->{'FRONTEND'} );
            if( $frontend eq 'RXA3I' ) {

              # fast frequency switch pattern/grid, receiver A.
              $expt = 15 + $nscan * $ncycle * $cycllen * 1.20;

            } elsif( $frontend eq 'RXB' ) {

              # slow frequency switch pattern/grid, receiver B.
              $expt = 18 + $nscan * $ncycle * $cycllen * 1.60;

            }
          }
        }
      }
    } else {

      my $swmode;
      if( exists( $FITS_headers->{'SWMODE'} ) && defined( $FITS_headers->{'SWMODE'} ) ) {
        $swmode = $FITS_headers->{'SWMODE'};
      } else {
        $swmode = 'BEAMSWITCH';
      }

      if( exists( $FITS_headers->{'NSCAN'} ) && defined( $FITS_headers->{'NSCAN'} ) &&
          exists( $FITS_headers->{'NCYCLE'} ) && defined( $FITS_headers->{'NCYCLE'} ) &&
          exists( $FITS_headers->{'CYCLLEN'} ) && defined( $FITS_headers->{'CYCLLEN'} ) ) {

        my $nscan = $FITS_headers->{'NSCAN'};
        my $ncycle = $FITS_headers->{'NCYCLE'};
        my $cycllen = $FITS_headers->{'CYCLLEN'};

        if( $swmode eq 'POSITION_SWITCH' ) {

          # position switch sample.
          $expt = 4.8 + $nscan * $ncycle * $cycllen * 1.10;

        } elsif( $swmode eq 'BEAMSWITCH' ) {

          # beam switch sample.
          $expt = 4.8 + $nscan * $ncycle * $cycllen * 1.25;

        } elsif( $swmode eq 'CHOPPING' ) {
          if( exists( $FITS_headers->{'FRONTEND'} ) && defined( $FITS_headers->{'FRONTEND'} ) ) {
            my $frontend = uc( $FITS_headers->{'FRONTEND'} );
            if( $frontend eq 'RXA3I' ) {

              # fast frequency switch sample, receiver A.
              $expt = 3 + $nscan * $ncycle * $cycllen * 1.10;

            } elsif( $frontend eq 'RXB' ) {

              # slow frequency switch sample, receiver B.
              $expt = 3 + $nscan * $ncycle * $cycllen * 1.40;
            }
          }
        }
      }
    }
  }

  return $expt;
}

=item B<to_SYSTEM_VELOCITY>

Translate the C<VREF> and C<C12VDEF> headers into one combined header.

=cut

sub to_SYSTEM_VELOCITY {
  my $FITS_headers = shift;
  my $return;
  if( exists( $FITS_headers->{'VREF'} ) && defined( $FITS_headers->{'VREF'} ) &&
      exists( $FITS_headers->{'VDEF'} ) && defined( $FITS_headers->{'VDEF'} ) ) {
    $return = substr( $FITS_headers->{'VDEF'}, 0, 3 ) . substr( $FITS_headers->{'VREF'}, 0, 3 );
  }
  return $return;
}

=back

=head1 VARIABLES

=over 4

=item B<%hdr>

Contains one-to-one mappings between FITS headers and generic headers.
Keys are generic headers, values are FITS headers.

=cut

%hdr = (
        AMBIENT_TEMPERATURE => "TAMB",
        APERTURE => "APERTURE",
        AZIMUTH_START => "AZ",
        BACKEND => "BACKEND",
        BACKEND_SECTIONS => "NORSECT",
        CHOP_FREQUENCY => "CHOPFREQ",
        CHOP_THROW => "CHOPTHRW",
        COORDINATE_SYSTEM => "COORDCD",
#        COORDINATE_TYPE => "C4LSC",
        CYCLE_LENGTH => "CYCLLEN",
#        DEC_BASE => "",
        ELEVATION_START => "EL",
        FILENAME => "GSDFILE",
        FILTER => "FILTER",
        FREQUENCY_RESOLUTION => "FREQRES",
        FRONTEND => "FRONTEND",
        HUMIDITY => "HUMIDITY",
        NUMBER_OF_CYCLES => "NOCYCLES",
        NUMBER_OF_SUBSCANS => "NOSCANS",
        OBJECT => "OBJECT",
        OBSERVATION_MODE => "OBSMODE",
        OBSERVATION_NUMBER => "SCAN",
        PROJECT => "PROJID",
#        RA_BASE => "C4RADATE",
        RECEIVER_TEMPERATURE => "TRX",
        ROTATION => "YPOSANG",
        REST_FREQUENCY => "RESTFRQ1",
        SEEING => "PHA",
        SWITCH_MODE => "SWMODE",
        SYSTEM_TEMPERATURE => "STSYS",
        TAU => "TAU",
        USER_AZ_CORRECTION => "UXPNT",
        USER_EL_CORRECTION => "UYPNT",
        VELOCITY => "VELOCITY",
        VELOCITY_REFERENCE_FRAME => "VREF",
        VELOCITY_TYPE => "VDEF",
        X_BASE => "XREF",
        Y_BASE => "YREF",
        X_DIM => "NOXPTS",
        Y_DIM => "NOYPTS",
        X_REQUESTED => "XSOURCE",
        Y_REQUESTED => "YSOURCE",
        X_SCALE => "DELTAX",
        Y_SCALE => "DELTAY",
       );

=back

=head1 AUTHOR

Brad Cavanagh E<lt>b.cavanagh@jach.hawaii.eduE<gt>

=head1 COPYRIGHT

Copyright (C) 2003 Particle Physics and Astronomy Research Council.
All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
