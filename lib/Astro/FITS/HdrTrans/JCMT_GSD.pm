package Astro::FITS::HdrTrans::JCMT_GSD;

# ---------------------------------------------------------------------------

#+
#  Name:
#    Astro::FITS::HdrTrans::JCMT_GSD

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

Astro::FITS::HdrTrans::JCMT_GSD - Translantes FITS headers into
generic headers and back again.

=head1 DESCRIPTION

Converts information contained in JCMT heterodyne instrument headers
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

For this class, the method will return true if the B<C1RCV> header exists
and matches the regular expression C</^rx(a|b|w)/i> or C</^fts/i>.

=back

=cut

sub valid_class {
  my $headers = shift;

  if( exists( $headers->{'C1RCV'} ) &&
      defined( $headers->{'C1RCV'} ) &&
      ( $headers->{'C1RCV'} =~ /^rx(a|b|w)/i ||
        $headers->{'C1RCV'} =~ /^fts/i ) ) {
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

  if( exists( $FITS_headers->{'C1RCV'} ) ) {
    $return = $FITS_headers->{'C1RCV'};
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

Translates the C<C3DAT> header into a C<Time::Piece> object.

=cut

sub to_UTDATE {
  my $FITS_headers = shift;
  my $return;

  if( exists( $FITS_headers->{'C3DAT'} ) ) {
    $FITS_headers->{'C3DAT'} =~ /(\d{4})\.(\d\d)(\d{1,2})/;
    my $day = (length($3) == 2) ? $3 : $3 . "0";
    my $ut = "$1-$2-$day";
    $return = Time::Piece->strptime( $ut, "%Y-%m-%d" );
  }
  return $return;
}

=item B<to_UTSTART>

Translates the C<C3DAT> and C<C3UT> headers into a C<Time::Piece> object.

=cut

sub to_UTSTART {
  my $FITS_headers = shift;

  my $return;
  if ( exists( $FITS_headers->{'C3DAT'} ) && defined( $FITS_headers->{'C3DAT'} ) &&
       exists( $FITS_headers->{'C3UT'} ) && defined( $FITS_headers->{'C3UT'} ) ) {
    my $hour = int( $FITS_headers->{'C3UT'} );
    my $minute = int ( ( $FITS_headers->{'C3UT'} - $hour ) * 60 );
    my $second = int ( ( ( ( $FITS_headers->{'C3UT'} - $hour ) * 60 ) - $minute ) * 60 );
    $FITS_headers->{'C3DAT'} =~ /(\d{4})\.(\d\d)(\d{1,2})/;
    my $day = (length($3) == 2) ? $3 : $3 . "0";
    $return = Time::Piece->strptime(sprintf("%4u-%02u-%02uT%02u:%02u:%02u", $1, $2, $day, $hour, $minute, $second ),
                                    "%Y-%m-%dT%T");
  }
  return $return;
}

=item B<to_UTEND>

Translates the C<C3DAT>, C<C3UT>, C<C3NIS>, C<C3CL>, C<C3NCP>, and C<C3NCI> headers
into a C<Time::Piece> object.

=cut

sub to_UTEND {
  my $FITS_headers = shift;
  my ($t, $expt);
  if( exists( $FITS_headers->{'C3DAT'} ) && defined( $FITS_headers->{'C3DAT'} ) &&
      exists( $FITS_headers->{'C3UT'} ) && defined( $FITS_headers->{'C3UT'} ) ) {
    my $hour = int( $FITS_headers->{'C3UT'} );
    my $minute = int ( ( $FITS_headers->{'C3UT'} - $hour ) * 60 );
    my $second = int ( ( ( ( $FITS_headers->{'C3UT'} - $hour ) * 60 ) - $minute ) * 60 );
    $FITS_headers->{'C3DAT'} =~ /(\d{4})\.(\d\d)(\d{1,2})/;
    my $day = (length($3) == 2) ? $3 : $3 . "0";
    $t = Time::Piece->strptime(sprintf("%4u-%02u-%02uT%02u:%02u:%02u", $1, $2, $day, $hour, $minute, $second ),
                              "%Y-%m-%dT%T");
  }

  $expt = to_EXPOSURE_TIME( $FITS_headers );

  $t += $expt;

  return $t;

}

=item B<to_EXPOSURE_TIME>

=cut

sub to_EXPOSURE_TIME {
  my $FITS_headers = shift;
  my $expt = 0;

  if( exists( $FITS_headers->{'C6ST'} ) && defined( $FITS_headers->{'C6ST'} ) ) {

    my $c6st = uc( $FITS_headers->{'C6ST'} );

    if( $c6st eq 'RASTER' ) {

      if( exists( $FITS_headers->{'C3NSAMPL'} ) && defined( $FITS_headers->{'C3NSAMPL'} ) &&
          exists( $FITS_headers->{'C3CL'} ) && defined( $FITS_headers->{'C3CL'} ) &&
          exists( $FITS_headers->{'C3NPP'} ) && defined( $FITS_headers->{'C3NPP'} ) ) {

        my $c3nsampl = $FITS_headers->{'C3NSAMPL'};
        my $c3cl = $FITS_headers->{'C3CL'};
        my $c3npp = $FITS_headers->{'C3NPP'};

        # raster.
        $expt = 15 + $c3nsampl * $c3cl * ( 1 + 1 / sqrt( $c3npp ) ) * 1.4;
      }
    } elsif( $c6st eq 'PATTERN' or $c6st eq 'GRID' ) {

      my $c6mode = '';

      if( exists( $FITS_headers->{'C6MODE'} ) && defined( $FITS_headers->{'C6MODE'} ) ) {
        $c6mode = $FITS_headers->{'C6MODE'};
      } else {
        $c6mode = 'BEAMSWITCH';
      }

      if( exists( $FITS_headers->{'C3NSAMPL'} ) && defined( $FITS_headers->{'C3NSAMPL'} ) &&
          exists( $FITS_headers->{'C3NCYCLE'} ) && defined( $FITS_headers->{'C3NCYCLE'} ) &&
          exists( $FITS_headers->{'C3CL'} ) && defined( $FITS_headers->{'C3CL'} ) ) {

        my $c3nsampl = $FITS_headers->{'C3NSAMPL'};
        my $c3ncycle = $FITS_headers->{'C3NCYCLE'};
        my $c3cl = $FITS_headers->{'C3CL'};

        if( $c6mode eq 'POSITION_SWITCH' ) {

          # position switch pattern/grid.
          $expt = 6 + $c3nsampl * $c3ncycle * $c3cl * 1.35;

        } elsif( $c6mode eq 'BEAMSWITCH' ) {

          # beam switch pattern/grid.
          $expt = 6 + $c3nsampl * $c3ncycle * $c3cl * 1.35;

        } elsif( $c6mode eq 'CHOPPING' ) {
          if( exists( $FITS_headers->{'C1RCV'} ) && defined( $FITS_headers->{'C1RCV'} ) ) {
            my $c1rcv = uc( $FITS_headers->{'C1RCV'} );
            if( $c1rcv eq 'RXA3I' ) {

              # fast frequency switch pattern/grid, receiver A.
              $expt = 15 + $c3nsampl * $c3ncycle * $c3cl * 1.20;

            } elsif( $c1rcv eq 'RXB' ) {

              # slow frequency switch pattern/grid, receiver B.
              $expt = 18 + $c3nsampl * $c3ncycle * $c3cl * 1.60;

            }
          }
        }
      }
    } else {

      my $c6mode;
      if( exists( $FITS_headers->{'C6MODE'} ) && defined( $FITS_headers->{'C6MODE'} ) ) {
        $c6mode = $FITS_headers->{'C6MODE'};
      } else {
        $c6mode = 'BEAMSWITCH';
      }

      if( exists( $FITS_headers->{'C3NSAMPL'} ) && defined( $FITS_headers->{'C3NSAMPL'} ) &&
          exists( $FITS_headers->{'C3NCYCLE'} ) && defined( $FITS_headers->{'C3NCYCLE'} ) &&
          exists( $FITS_headers->{'C3CL'} ) && defined( $FITS_headers->{'C3CL'} ) ) {

        my $c3nsampl = $FITS_headers->{'C3NSAMPL'};
        my $c3ncycle = $FITS_headers->{'C3NCYCLE'};
        my $c3cl = $FITS_headers->{'C3CL'};

        if( $c6mode eq 'POSITION_SWITCH' ) {

          # position switch sample.
          $expt = 4.8 + $c3nsampl * $c3ncycle * $c3cl * 1.10;

        } elsif( $c6mode eq 'BEAMSWITCH' ) {

          # beam switch sample.
          $expt = 4.8 + $c3nsampl * $c3ncycle * $c3cl * 1.25;

        } elsif( $c6mode eq 'CHOPPING' ) {
          if( exists( $FITS_headers->{'C1RCV'} ) && defined( $FITS_headers->{'C1RCV'} ) ) {
            my $c1rcv = uc( $FITS_headers->{'C1RCV'} );
            if( $c1rcv eq 'RXA3I' ) {

              # fast frequency switch sample, receiver A.
              $expt = 3 + $c3nsampl * $c3ncycle * $c3cl * 1.10;

            } elsif( $c1rcv eq 'RXB' ) {

              # slow frequency switch sample, receiver B.
              $expt = 3 + $c3nsampl * $c3ncycle * $c3cl * 1.40;
            }
          }
        }
      }
    }
  }

  return $expt;
}

=item B<to_SYSTEM_VELOCITY>

Translate the C<C12VREF> and C<C12VDEF> headers into one combined header.

=cut

sub to_SYSTEM_VELOCITY {
  my $FITS_headers = shift;
  my $return;
  if( exists( $FITS_headers->{'C12VREF'} ) && defined( $FITS_headers->{'C12VREF'} ) &&
      exists( $FITS_headers->{'C12VDEF'} ) && defined( $FITS_headers->{'C12VDEF'} ) ) {
    $return = substr( $FITS_headers->{'C12VDEF'}, 0, 3 ) . substr( $FITS_headers->{'C12VREF'}, 0, 3 );
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
        AMBIENT_TEMPERATURE => "C5AT",
        APERTURE => "C7AP",
        AZIMUTH_START => "C4AZ",
        BACKEND => "C1BKE",
        BACKEND_SECTIONS => "C3NRS",
        CHOP_FREQUENCY => "C4FRQ",
        CHOP_THROW => "C4THROW",
        COORDINATE_SYSTEM => "C4CSC",
        COORDINATE_TYPE => "C4LSC",
        CYCLE_LENGTH => "C3CL",
#        DEC_BASE => "",
        ELEVATION_START => "C4EL",
#        FILENAME => "GSDFILE",
        FILTER => "C7FIL",
        FREQUENCY_RESOLUTION => "C12FR",
        FRONTEND => "C1RCV",
        HUMIDITY => "C5RH",
        NUMBER_OF_CYCLES => "C3NCI",
        NUMBER_OF_SUBSCANS => "C3NIS",
        OBJECT => "C1SNA1",
        OBSERVATION_MODE => "C6ST",
        OBSERVATION_NUMBER => "C1SNO",
        PROJECT => "C1PID",
        RA_BASE => "C4RADATE",
        RECEIVER_TEMPERATURE => "C12RT",
        ROTATION => "CELL_V2Y",
        REST_FREQUENCY => "C12RF",
        SEEING => "C7SEEING",
        SWITCH_MODE => "C6MODE",
        SYSTEM_TEMPERATURE => "C12SST",
        TAU => "C7TAU225",
        USER_AZ_CORRECTION => "UAZ",
        USER_EL_CORRECTION => "UEL",
        VELOCITY => "C7VR",
        VELOCITY_REFERENCE_FRAME => "C12VREF",
        VELOCITY_TYPE => "C12VDEF",
        X_BASE => "C4RX",
        Y_BASE => "C4RY",
        X_DIM => "C6XNP",
        Y_DIM => "C6YNP",
        X_REQUESTED => "C4SX",
        Y_REQUESTED => "C4SY",
        X_SCALE => "C6DX",
        Y_SCALE => "C6DY",
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
