# -*-perl-*-

package Astro::FITS::HdrTrans::ClassicCam;

=head1 NAME

Astro::FITS::HdrTrans::ClassicCam - Magellan ClassicCam translations

=head1 SYNOPSIS

  use Astro::FITS::HdrTrans::ClassicCam;

  %gen = Astro::FITS::HdrTrans::ClassicCam->translate_from_FITS( %hdr );

=head1 DESCRIPTION

This class provides a generic set of translations that are specific to
Magellan ClassicCam observations.

=cut

use 5.006;
use warnings;
use strict;
use Carp;

# Inherit from GEMINI
use base qw/ Astro::FITS::HdrTrans::FITS /;

use vars qw/ $VERSION /;

$VERSION = sprintf("%d", q$Revision: 14879 $ =~ /(\d+)/);

# for a constant mapping, there is no FITS header, just a generic
# header that is constant
my %CONST_MAP = (
                  DETECTOR_READ_TYPE    => "NDSTARE",
                  GAIN                  => 7.5,
                  INSTRUMENT            => "ClassicCam",
                  NSCAN_POSITIONS       => 1,
                  NUMBER_OF_EXPOSURES   => 1,
                  OBSERVATION_MODE      => 'imaging',
                  ROTATION              => 0, # assume good alignment for now
                );

# NULL mappings used to override base class implementations
my @NULL_MAP = qw/ /;

# unit mapping implies that the value propogates directly
# to the output with only a keyword name change

my %UNIT_MAP = (
                 AIRMASS_END            => "AIRMASS",
                 DEC_TELESCOPE_OFFSET   => "DSECS",
                 EQUINOX                => "EQUINOX",
                 EXPOSURE_TIME          => "EXPTIME",
                 FILTER                 => "FILTER",
                 OBJECT                 => "OBJECT",
                 OBSERVATION_NUMBER     => "IRPICNO",
                 RA_TELESCOPE_OFFSET    => "ASECS",
                 SPEED_GAIN             => "SPEED",
                 X_DIM                  => "NAXIS1",
                 Y_DIM                  => "NAXIS2"
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

Returns "ClassicCam".

=cut

sub this_instrument {
  return qr/^ClassicCam/i;
}

=back

=head1 COMPLEX CONVERSIONS

=over 4

=cut

sub to_AIRMASS_START {
   my $self = shift;
   my $FITS_headers = shift;
   my $airmass = 1.0;
   if ( defined( $FITS_headers->{AIRMASS} ) ) {
      $airmass = $FITS_headers->{AIRMASS};
   }
   return $airmass;
}

# Convert from sexagesimal d:m:s to decimal degrees.
sub to_DEC_BASE {
   my $self = shift;
   my $FITS_headers = shift;
   my $dec = 0.0;
   my $sexa = $FITS_headers->{"DEC"};
   if ( defined( $sexa ) ) {
      $dec = $self->dms_to_degrees( $sexa );
   }
   return $dec;
}

# This is N to the top, i.e increasing with pixel index, for
# declinations south of -29 degrees.  It is flipped north of
# -29 degrees.
sub to_DEC_SCALE {
   my $self = shift;
   my $FITS_headers = shift;
   my $scale = 0.115;
   my $sexa = $FITS_headers->{"DEC"};
   if ( defined( $sexa ) ) {
      my $dec = $self->dms_to_degrees( $sexa );
      if ( $dec > -29 ) {
         $scale *= -1;
      }
   }
   return $scale;
}

sub to_NUMBER_OF_OFFSETS {
   my $self = shift;
   my $FITS_headers = shift;
# Allow for the UKIRT convention of the final offset to 0,0, and a
# default dither pattern of 5.
   my $noffsets = 6;

# The number of gripu members appears to be given by keyword LOOP.
   if ( defined $FITS_headers->{NOFFSETS} ) {
      $noffsets = $FITS_headers->{NOFFSETS};
   }

   return $noffsets;
}

sub to_NUMBER_OF_READS {
   my $self = shift;
   my $FITS_headers = shift;
   my $reads = 2;
   if ( defined $FITS_headers->{READS_EP} && $FITS_headers->{PRE_EP} ) {
      $reads = $FITS_headers->{READS_EP} + $FITS_headers->{PRE_EP};
   }
   return $reads;
}

sub to_OBSERVATION_TYPE {
   my $self = shift;
   my $FITS_headers = shift;
   my $type = "OBJECT";
   if ( defined $FITS_headers->{OBJECT} ) {
      my $object = uc( $FITS_headers->{OBJECT} );
      if ( $object eq "DARK" ) {
         $type = $object;
      } elsif ( $object =~ /FLAT/ ) {
         $type = "FLAT";
      }
   }
   return $type;
}

# Convert from sexagesimal h:m:s to decimal degrees.
sub to_RA_BASE {
   my $self = shift;
   my $FITS_headers = shift;
   my $ra = 0.0;
   my $sexa = $FITS_headers->{"RA"};
   if ( defined( $sexa ) ) {
      $ra = $self->hms_to_degrees( $sexa );
   }
   return $ra;
}

# This is E to the right, i.e increasing with pixel index, for
# declinations south of -29 degrees.  It is flipped north of
# -29 degrees.
sub to_RA_SCALE {
   my $self = shift;
   my $FITS_headers = shift;
   my $scale = 0.115;
   my $sexa = $FITS_headers->{"DEC"};
   if ( defined( $sexa ) ) {
      my $dec = $self->dms_to_degrees( $sexa );
      if ( $dec > -29 ) {
         $scale *= -1;
      }
   }
   return $scale;
}

sub to_DR_RECIPE {
   my $self = shift;
   my $FITS_headers = shift;
   my $type = "OBJECT";
   my $recipe = "QUICK_LOOK";
   if ( defined $FITS_headers->{OBJECT} ) {
      my $object = uc( $FITS_headers->{OBJECT} );
      if ( $object eq "DARK" ) {
         $recipe = "REDUCE_DARK";
      } elsif ( $object =~ /SKY*FLAT/ ) {
         $recipe = "SKY_FLAT_MASKED";
      } elsif ( $object =~ /DOME*FLAT/ ) {
         $recipe = "SKY_FLAT";
      } else {
         $recipe = "JITTER_SELF_FLAT";
      }
   }
   return $recipe;
}

# Cope with non-standard format in DATE-OBS.  Guessing format is
# ddmmmyy, not supported by Time::DateParse, so parse it.
sub to_UTDATE {
   my $self = shift;
   my $FITS_headers = shift;
   return $self->get_UT_date($FITS_headers);
}

# UT header gives end of observation in HH:MM:SS format

sub to_UTEND {
   my $self = shift;
   my $FITS_headers = shift;

   # get the UTDATE in YYYYMMDD format
   my $ymd = $self->to_UTDATE( $FITS_headers );
   my $iso = sprintf("%04d-%02d-%02dT%s",
                     substr($ymd,0,4),
                     substr($ymd,4,2),
                     substr($ymd,6,2),
                     $FITS_headers->{UT});
   return $self->_parse_iso_date( $iso );
}

sub from_UTEND {
   my $self = shift;
   my $generic_headers = shift;
   my $utend = $generic_headers->{"UTEND"};
   if (defined $utend) {
       return $utend->strftime("%T");
   }
   return;
}

# Derive from the end time, less the exposure time and some
# allowance for the read time.
sub to_UTSTART {
   my $self = shift;
   my $FITS_headers = shift;

   my $utend = $self->to_UTEND( $FITS_headers );

   my $nreads = $self->to_NUMBER_OF_READS($FITS_headers);
   my $speed = $self->get_speed_sec($FITS_headers);
   if ( defined $FITS_headers->{EXPTIME} ) {
       my $offset = -1 * ( $FITS_headers->{EXPTIME} + $speed * $nreads );
       $utend = $self->_add_seconds( $utend, $offset );
   }
   return $utend;
}

sub to_X_LOWER_BOUND {
   my $self = shift;
   my $FITS_headers = shift;
   my @bounds = $self->quad_bounds($FITS_headers);
   return $bounds[ 0 ];
}

sub to_X_REFERENCE_PIXEL {
   my $self = shift;
   my $FITS_headers = shift;
   my @bounds = $self->quad_bounds($FITS_headers);
   return int( ( $bounds[ 0 ] + $bounds[ 2 ] ) / 2 ) + 1;
}

sub to_X_UPPER_BOUND {
   my $self = shift;
   my $FITS_headers = shift;
   my @bounds = $self->quad_bounds($FITS_headers);
   return $bounds[ 2 ];
}

sub to_Y_LOWER_BOUND {
   my $self = shift;
   my $FITS_headers = shift;
   my @bounds = $self->quad_bounds($FITS_headers);
   return $bounds[ 1 ];
}

sub to_Y_REFERENCE_PIXEL {
   my $self = shift;
   my $FITS_headers = shift;
   my @bounds = $self->quad_bounds($FITS_headers);
   return int( ( $bounds[ 1 ] + $bounds[ 3 ] ) / 2 ) + 1;
}

sub to_Y_UPPER_BOUND {
   my $self = shift;
   my $FITS_headers = shift;
   my @bounds = $self->quad_bounds($FITS_headers);
   return $bounds[ 3 ];
}


# Supplementary methods for the translations
# ------------------------------------------

# Converts a sky angle specified in d:m:s format into decimal degrees.
# Argument is the sexagesimal format angle.
sub dms_to_degrees {
   my $self = shift;
   my $sexa = shift;
   my $dms;
   if ( defined( $sexa ) ) {
      my @pos = split( /:/, $sexa );
      $dms = $pos[ 0 ] + $pos[ 1 ] / 60.0 + $pos [ 2 ] / 3600.;
   }
   return $dms;
}

# Returns the UT date in YYYYMMDD format.
sub get_speed_sec {
   my $self = shift;
   my $FITS_headers = shift;
   my $speed = 0.743;
   if ( exists $FITS_headers->{SPEED} ) {
      my $s_speed = $FITS_headers->{SPEED};
      $speed = 2.01 if ( $s_speed eq "2.0s" );
      $speed = 1.005 if ( $s_speed eq "1.0s" );
      $speed = 0.743 if ( $s_speed eq "743ms" );
      $speed = 0.405 if ( $s_speed eq "405ms" );
   }
   return $speed;
}

# Returns the detector speed in seconds.
sub get_UT_date {
   my $self = shift;
   my $FITS_headers = shift;
   my @months = qw( Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec );
   my $junk = $FITS_headers->{"DATE-OBS"};
   my $day = substr( $junk, 0, 2 );
   my $smonth = substr( $junk, 2, 3 );
   my $mindex = 0;
   while ( $mindex < 11 && uc( $smonth ) ne uc( $months[ $mindex ] ) ) {
      $mindex++;
   }
   $mindex++;
   my $month = "0" x ( 2 - length( $mindex ) ) . $mindex;
   my $year = substr( $junk, 5, 2 );
   if ( $year > 90 ) {
      $year += 1900;
   } else {
      $year += 2000;
   }
   return join "", $year, $month, $day;
}

# Returns the UT time of observation in decimal hours.
sub get_UT_hours {
   my $self = shift;
   my $FITS_headers = shift;
   if ( exists $FITS_headers->{UT} && $FITS_headers->{UT} =~ /:/ ) {
      my ($hour, $minute, $second) = split( /:/, $FITS_headers->{UT} );
      return $hour + ($minute / 60) + ($second / 3600);
   } else {
      return $FITS_headers->{UT};
   }
}

# Converts a sky angle specified in h:m:s format into decimal degrees.
# It takes no account of latitude.  Argument is the sexagesimal format angle.
sub hms_to_degrees {
   my $self = shift;
   my $sexa = shift;
   my $hms;
   if ( defined( $sexa ) ) {
      my @pos = split( /:/, $sexa );
      $hms = 15.0 * ( $pos[ 0 ] + $pos[ 1 ] / 60.0 + $pos [ 2 ] / 3600. );
   }
   return $hms;
}

# Guess for the moment that QUAD 1,2,3,4 correspond to LL, LR, UL, UR
# quadrants, and 5 is thw whole 256x256-pixel array.
sub quad_bounds {
   my $self = shift;
   my $FITS_headers = shift;
   my @bounds = ( 1, 1, 256, 256 );
   my $quad = $FITS_headers->{"QUAD"};
   if ( defined( $quad ) ) {
      if ( $quad < 5 ) {
         $bounds[ 0 ] += 128 * ( $quad + 1 ) % 2;
         $bounds[ 2 ] -= 128 * $quad % 2;
         if ( $quad > 2 ) {
            $bounds[ 1 ] += 128;
         } else {
            $bounds[ 3 ]-= 128;
         }
      }
   }
   return @bounds;
}


=back

=head1 REVISION

 $Id: SOFI.pm 14879 2008-02-13 21:51:31Z timj $

=head1 SEE ALSO

C<Astro::FITS::HdrTrans>, C<Astro::FITS::HdrTrans::UKIRT>.

=head1 AUTHOR

Malcolm J. Currie E<lt>mjc@jach.hawaii.eduE<gt>
Tim Jenness E<lt>t.jenness@jach.hawaii.eduE<gt>.

=head1 COPYRIGHT

Copyright (C) 2008 Science and Technology Facilities Council.
Copyright (C) 1998-2007 Particle Physics and Astronomy Research Council.
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
