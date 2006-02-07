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

# inherit from the Base translation class and not HdrTrans
# itself (which is just a class-less wrapper)
use base qw/ Astro::FITS::HdrTrans::FITS /;

# Use the FITS standard DATE-OBS handling
use Astro::FITS::HdrTrans::FITS;

# Speed of light in km/s.
use constant CLIGHT => 2.99792458e5;

use vars qw/ $VERSION /;

$VERSION = sprintf("%d.%03d", q$Revision$ =~ /(\d+)\.(\d+)/);

# in each class we have three sets of data.
#   - constant mappings
#   - unit mappings
#   - complex mappings

# for a constant mapping, there is no FITS header, just a generic
# header that is constant
my %CONST_MAP = (
		 INST_DHS          => 'ACSIS',
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
    DEC_BASE           => 'CRVAL2',
    DEC_SCALE_UNITS    => 'CUNIT2',
		DR_RECIPE          => 'DRRECIPE',
    ELEVATION_START    => 'ELSTART',
    ELEVATION_END      => 'ELEND',
    EQUINOX            => 'EQUINOX',
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
    RA_BASE            => 'CRVAL1',
    RA_SCALE_UNITS     => 'CUNIT1',
    REST_FREQUENCY     => 'RESTFREQ',
		SEEING             => 'SEEINGST',
		STANDARD           => 'STANDARD',
		SWITCH_MODE        => 'SW_MODE',
		TAU                => 'WVMTAUST',
    VELOCITY_REFERENCE_FRAME => 'SPECSYS',
    VELOCITY_TYPE      => 'DOPPLER',
    WAVEPLATE_ANGLE    => 'SKYANG',
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
  if( exists( $FITS_headers->{'DATE-OBS'} ) &&
      exists( $FITS_headers->{'DATE-END'} ) ) {

    my $start = $self->to_UTSTART( $FITS_headers );
    my $end = $self->to_UTEND( $FITS_headers );
    my $duration = $end - $start;
    $return = $duration->seconds;
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

  my $return;
  if( exists( $FITS_headers->{'DOPPLER'} ) &&
      exists( $FITS_headers->{'SPECSYS'} ) ) {
    my $doppler = $FITS_headers->{'DOPPLER'};
    my $specsys = $FITS_headers->{'SPECSYS'};

    $return = substr( uc( $doppler ), 0, 3 ) . substr( uc( $specsys ), 0, 3 );
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

  my $return;
  if( exists( $FITS_headers->{'DOPPLER'} ) &&
      exists( $FITS_headers->{'ZSOURCE'} ) ) {
    my $doppler = uc( $FITS_headers->{'DOPPLER'} );
    my $zsource = $FITS_headers->{'ZSOURCE'};

    if( $doppler eq 'REDSHIFT' ) {
      $return = $zsource;
    } elsif( $doppler eq 'OPTICAL' ) {
      $return = $zsource * CLIGHT;
    } elsif( $doppler eq 'RADIO' ) {
      $return = ( CLIGHT * $zsource ) / ( 1 + $zsource );
    }
  }
  return $return;
}

=back

=head1 REVISION

 $Id$

=head1 SEE ALSO

C<Astro::FITS::HdrTrans>, C<Astro::FITS::HdrTrans::Base>

=head1 AUTHORS

Tim Jenness E<lt>t.jenness@jach.hawaii.eduE<gt>,
Brad Cavanagh E<lt>b.cavanagh@jach.hawaii.eduE<gt>.

=head1 COPYRIGHT

Copyright (C) 2005-2006 Particle Physics and Astronomy Research Council.
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
