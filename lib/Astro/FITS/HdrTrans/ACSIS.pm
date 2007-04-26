# -*-perl-*-

package Astro::FITS::HdrTrans::ACSIS;

=head1 NAME

Astro::FITS::HdrTrans::ACSIS - class for translation of JCMT ACSIS headers

=head1 SYNOPSIS

  use Astro::FITS::HdrTrans::ACSIS;

=head1 DESCRIPTION

This class provides a set of translations for ACSIS at JCMT.

=cut

use 5.006;
use warnings;
use strict;
use Carp;

use Astro::Coords;
use Astro::Telescope;
use DateTime;

# inherit from the Base translation class and not HdrTrans
# itself (which is just a class-less wrapper)
use base qw/ Astro::FITS::HdrTrans::JAC /;

# Use the FITS standard DATE-OBS handling
#use Astro::FITS::HdrTrans::FITS;

# Speed of light in km/s.
use constant CLIGHT => 2.99792458e5;

use vars qw/ $VERSION /;

$VERSION = sprintf("%d.%03d", q$Revision$ =~ /(\d+)\.(\d+)/);

our $COORDS;

# in each class we have three sets of data.
#   - constant mappings
#   - unit mappings
#   - complex mappings

# for a constant mapping, there is no FITS header, just a generic
# header that is constant
my %CONST_MAP = (
		 INST_DHS          => 'ACSIS',
                 SUBSYSTEM_IDKEY   => 'SUBSYSNR',
                );

# unit mapping implies that the value propogates directly
# to the output with only a keyword name change

my %UNIT_MAP = (
		AIRMASS_START      => 'AMSTART',
		AIRMASS_END        => 'AMEND',
		AMBIENT_TEMPERATURE=> 'ATSTART',
    AZIMUTH_START      => 'AZSTART',
    AZIMUTH_END        => 'AZEND',
    BACKEND            => 'BACKEND',
    BANDWIDTH_MODE     => 'BWMODE',
		CHOP_ANGLE         => 'CHOP_PA',
    CHOP_COORDINATE_SYSTEM => 'CHOP_CRD',
    CHOP_FREQUENCY     => 'CHOP_FRQ',
		CHOP_THROW         => 'CHOP_THR',
		DR_RECIPE          => 'DRRECIPE',
    ELEVATION_START    => 'ELSTART',
    ELEVATION_END      => 'ELEND',
    FRONTEND           => 'INSTRUME',
    HUMIDITY           => 'HUMSTART',
    LATITUDE           => 'LAT-OBS',
    LONGITUDE          => 'LONG-OBS',
		MSBID              => 'MSBID',
    NUMBER_OF_CYCLES   => 'NUM_CYC',
		OBJECT             => 'OBJECT',
		OBSERVATION_NUMBER => 'OBSNUM',
		POLARIMETER        => 'POL_CONN',
		PROJECT            => 'PROJECT',
		SEEING             => 'SEEINGST',
		STANDARD           => 'STANDARD',
		SWITCH_MODE        => 'SW_MODE',
		TAU                => 'WVMTAUST',
    VELOCITY_TYPE      => 'DOPPLER',
               );

# Create the translation methods
__PACKAGE__->_generate_lookup_methods( \%CONST_MAP, \%UNIT_MAP );

=head1 METHODS

=over 4

=item B<can_translate>

Returns true if the supplied headers can be handled by this class.

  $cando = $class->can_translate( \%hdrs );

For this class, the method will return true if the B<BACKEND> header exists
and matches 'ACSIS'.

=cut

sub can_translate {
  my $self = shift;
  my $headers = shift;

  if ( exists $headers->{BACKEND} &&
       defined $headers->{BACKEND} &&
       $headers->{BACKEND} =~ /^ACSIS/i
     ) {
    return 1;
  } else {
    return 0;
  }
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

=item B<to_EXPOSURE_TIME>

Uses the to_UTSTART and to_UTEND functions to calculate the exposure
time. Returns the exposure time as a scalar, not as a Time::Seconds
object.

=cut

sub to_EXPOSURE_TIME {
  my $self = shift;
  my $FITS_headers = shift;

  my $return;
  if( ( exists( $FITS_headers->{'DATE-OBS'} ) ||
        exists( $FITS_headers->{'LONGDATEOBS'} ) ) &&
      ( exists( $FITS_headers->{'DATE-END'} ) ||
        exists( $FITS_headers->{'LONGDATEEND'} ) ) ) {

    if( ! exists( $FITS_headers->{'DATE-OBS'} ) ) {
      my $date = _convert_sybase_date( $FITS_headers->{'LONGDATEOBS'} );
      $FITS_headers->{'DATE-OBS'} = $date->datetime;
    }
    if( ! exists( $FITS_headers->{'DATE-END'} ) ) {
      my $date = _convert_sybase_date( $FITS_headers->{'LONGDATEEND'} );
      $FITS_headers->{'DATE-END'} = $date->datetime;
    }

    my $start = $self->to_UTSTART( $FITS_headers );
    my $end = $self->to_UTEND( $FITS_headers );
    my $duration = $end - $start;
    $return = $duration->seconds;
  }
  return $return;
}

=item B<to_INSTRUMENT>

Converts the C<INSTRUME> header into the C<INSTRUMENT> header. If the
C<INSTRUME> header begins with "HARP" or "FE_HARP", then the
C<INSTRUMENT> header will be set to "HARP".

=cut

sub to_INSTRUMENT {
  my $self = shift;
  my $FITS_headers = shift;
  my $return;
  if( exists( $FITS_headers->{'INSTRUME'} ) ) {
    if( $FITS_headers->{'INSTRUME'} =~ /^HARP/ ||
        $FITS_headers->{'INSTRUME'} =~ /^FE_HARP/ ) {
      $return = "HARP";
    } else {
      $return = $FITS_headers->{'INSTRUME'};
    }
  }
  return $return;
}

=item B<to_OBSERVATION_ID>

Converts the C<OBSID> header directly into the C<OBSERVATION_ID>
generic header, or if that header does not exist, converts the
C<BACKEND>, C<OBSNUM>, and C<DATE-OBS> headers into C<OBSERVATION_ID>.

=cut

sub to_OBSERVATION_ID {
  my $self = shift;
  my $FITS_headers = shift;
  my $return;
  if( exists( $FITS_headers->{'OBSID'} ) &&
      defined( $FITS_headers->{'OBSID'} ) ) {
    $return = $FITS_headers->{'OBSID'};
  } else {

    my $backend = lc( $self->to_BACKEND( $FITS_headers ) );
    my $obsnum = $self->to_OBSERVATION_NUMBER( $FITS_headers );
    my $dateobs = $self->to_UTSTART( $FITS_headers );

    my $datetime = $dateobs->datetime;
    $datetime =~ s/-//g;
    $datetime =~ s/://g;

    $return = join '_', $backend, $obsnum, $datetime;
  }

  return $return;
}

=item B<to_OBSERVATION_MODE>

Concatenates the SAM_MODE, SW_MODE, and OBS_TYPE header keywords into
the OBSERVATION_MODE generic header, with spaces removed and joined
with underscores. For example, if SAM_MODE is 'jiggle ', SW_MODE is
'chop ', and OBS_TYPE is 'science ', then the OBSERVATION_MODE generic
header will be 'jiggle_chop_science'.

=cut

sub to_OBSERVATION_MODE {
  my $self = shift;
  my $FITS_headers = shift;

  my $return;
  if( exists( $FITS_headers->{'SAM_MODE'} ) &&
      exists( $FITS_headers->{'SW_MODE'} ) &&
      exists( $FITS_headers->{'OBS_TYPE'} ) ) {
    my $sam_mode = $FITS_headers->{'SAM_MODE'};
    $sam_mode =~ s/\s//g;
    my $sw_mode = $FITS_headers->{'SW_MODE'};
    $sw_mode =~ s/\s//g;
    my $obs_type = $FITS_headers->{'OBS_TYPE'};
    $obs_type =~ s/\s//g;

    $return = ( ( $obs_type =~ /science/i )
              ? join '_', $sam_mode, $sw_mode
              : join '_', $sam_mode, $sw_mode, $obs_type );
  }
  return $return;
}

=item B<to_RA_BASE>

Uses the elevation, azimuth, telescope name, and observation start
time headers (ELSTART, AZSTART, TELESCOP, and DATE-OBS headers,
respectively) to calculate the base RA.

Returns the RA in degrees.

=cut

sub to_RA_BASE {
  my $self = shift;
  my $FITS_headers = shift;

  my $coords = $self->_calc_coords( $FITS_headers );
  return $coords->ra( format => 'deg' );

}

=item B<to_DEC_BASE>

Uses the elevation, azimuth, telescope name, and observation start
time headers (ELSTART, AZSTART, TELESCOP, and DATE-OBS headers,
respectively) to calculate the base declination.

Returns the declination in degrees.

=cut

sub to_DEC_BASE {
  my $self = shift;
  my $FITS_headers = shift;

  my $coords = _calc_coords( $FITS_headers );

  return $coords->dec( format => 'deg' );
}

=item B<to_REST_FREQUENCY>

=cut

sub to_REST_FREQUENCY {
  my $self = shift;
  my $FITS_headers = shift;
  my $frameset = shift;

  if( ! defined( $frameset ) ||
      ! UNIVERSAL::isa( $frameset, "Starlink::AST::FrameSet" ) ) {

    return 0;

  }

  my $frequency = $frameset->Get( "restfreq" );

  return $frequency;

}

=item B<to_SYSTEM_VELOCITY>

Converts the DOPPLER and SPECSYS headers into one combined
SYSTEM_VELOCITY header. The first three characters of each specific
header are used and concatenated. For example, if DOPPLER is 'radio'
and SPECSYS is 'LSR', then the resulting SYSTEM_VELOCITY generic
header will be 'RADLSR'. The results are always returned in capital
letters.

=cut

sub to_SYSTEM_VELOCITY {
  my $self = shift;
  my $FITS_headers = shift;
  my $frameset = shift;

  my $return;
  if( exists( $FITS_headers->{'DOPPLER'} ) &&
      defined( $frameset ) &&
      UNIVERSAL::isa( $frameset, "Starlink::AST::FrameSet" ) ) {
    my $doppler = $FITS_headers->{'DOPPLER'};
    my $sourcevrf = $frameset->Get( "sourcevrf" );

    $return = substr( uc( $doppler ), 0, 3 ) . substr( uc( $sourcevrf ), 0, 3 );
  }
  return $return;
}

=item B<to_VELOCITY>

Converts the ZSOURCE header into an appropriate system velocity,
depending on the value of the DOPPLER header. If the DOPPLER header is
'redshift', then the VELOCITY generic header will be returned
as a redshift. If the DOPPLER header is 'optical', then the
VELOCITY generic header will be returned as an optical
velocity. If the DOPPLER header is 'radio', then the VELOCITY
generic header will be returned as a radio velocity. Note that
calculating the radio velocity from the zeropoint (which is the
ZSOURCE header) gives accurates results only if the radio velocity is
a small fraction (~0.01) of the speed of light.

=cut

sub to_VELOCITY {
  my $self = shift;
  my $FITS_headers = shift;
  my $frameset = shift;

  my $velocity = 0;
  if( defined( $frameset ) &&
      UNIVERSAL::isa( $frameset, "Starlink::AST::FrameSet" ) ) {

    my $sourcesys = "VRAD";
    if( defined( $FITS_headers->{'DOPPLER'} ) ) {
      if( $FITS_headers->{'DOPPLER'} =~ /rad/i ) {
        $sourcesys = "VRAD";
      } elsif( $FITS_headers->{'DOPPLER'} =~ /opt/i ) {
        $sourcesys = "VOPT";
      } elsif( $FITS_headers->{'DOPPLER'} =~ /red/i ) {
        $sourcesys = "REDSHIFT";
      }
    }
    $frameset->Set( sourcesys => $sourcesys );
    $velocity = $frameset->Get( "sourcevel" );
  }

  return $velocity;
}

=back

=head1 PRIVATE METHODS

=over 4

=item B<_calc_coords>

Calculates the coordinates at the start of the observation by using
the elevation, azimuth, telescope, and observation start time. Caches
the result if it's already been calculated.

Returns an Astro::Coords object.

=cut

sub _calc_coords {
  my $FITS_headers = shift;

  if( defined( $COORDS ) &&
      UNIVERSAL::isa( $COORDS, "Astro::Coords" ) ) {
    return $COORDS;
  }

  if( exists( $FITS_headers->{'TELESCOP'} ) &&
      exists( $FITS_headers->{'AZSTART'} )  &&
      exists( $FITS_headers->{'ELSTART'} ) ) {

    my $dateobs;
    if( ! exists( $FITS_headers->{'DATE-OBS'} ) ) {
      if( exists( $FITS_headers->{'LONGDATEOBS'} ) ) {
        my $date = _convert_sybase_date( $FITS_headers->{'LONGDATEOBS'} );
        $FITS_headers->{'DATE-OBS'} = $date->datetime;
        $dateobs = $FITS_headers->{'DATE-OBS'};
      } else {
        return undef;
      }
    } else {
      $dateobs = $FITS_headers->{'DATE-OBS'};
    }

    my $telescope = $FITS_headers->{'TELESCOP'};
    my $az_start  = $FITS_headers->{'AZSTART'};
    my $el_start  = $FITS_headers->{'ELSTART'};

    my $coords = new Astro::Coords( az => $az_start,
                                    el => $el_start,
                                  );
    $coords->telescope( new Astro::Telescope( $telescope ) );

    $dateobs =~ /^(\d{4})-(\d\d)-(\d\d)T(\d\d):(\d\d):(\d\d)$/;

    my $dt = DateTime->new( year      => $1,
                            month     => $2,
                            day       => $3,
                            hour      => $4,
                            minute    => $5,
                            second    => $6,
                            time_zone => "UTC",
                          );

    $coords->datetime( $dt );

    $COORDS = $coords;
    return $COORDS;
  }

}

sub _convert_sybase_date {
  my $sybase_date = shift;

  $sybase_date =~ s/:\d\d\d//;
  $sybase_date =~ s/\s*$//;

  $sybase_date =~ /\s*(\w+)\s+(\d{1,2})\s+(\d{4})\s+(\d{1,2}):(\d\d):(\d\d)(AM|PM)/;

  my $hour = $4;
  if( uc($7) eq 'PM' && $hour < 12 ) {
    $hour += 12;
  }

  my %mon_lookup = ( 'Jan' => 1,
                     'Feb' => 2,
                     'Mar' => 3,
                     'Apr' => 4,
                     'May' => 5,
                     'Jun' => 6,
                     'Jul' => 7,
                     'Aug' => 8,
                     'Sep' => 9,
                     'Oct' => 10,
                     'Nov' => 11,
                     'Dec' => 12 );
  my $month = $mon_lookup{$1};

  my $return = DateTime->new( year => $3,
                              month => $month,
                              day => $2,
                              hour => $hour,
                              minute => $5,
                              second => $6,
                            );

  return $return;
}

=head1 REVISION

 $Id$

=head1 SEE ALSO

C<Astro::FITS::HdrTrans>, C<Astro::FITS::HdrTrans::Base>

=head1 AUTHORS

Tim Jenness E<lt>t.jenness@jach.hawaii.eduE<gt>,
Brad Cavanagh E<lt>b.cavanagh@jach.hawaii.eduE<gt>.

=head1 COPYRIGHT

Copyright (C) 2005-2007 Particle Physics and Astronomy Research Council.
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
