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

  use Astro::FITS::HdrTrans qw/ translate_from_FITS translate_to_FITS /;

  %generic_headers = translate_from_FITS(\%FITS_headers);

  %FITS_headers = translate_to_FITS(\%generic_headers);

=head1 DESCRIPTION

Converts information contained in instrument-specific FITS headers to
and from generic headers. A list of generic headers are given at the end
of the module documentation.

=cut

# L O A D   M O D U L E S --------------------------------------------------

use strict;

use warnings;
use warnings::register;

use Carp;
use Time::Piece ':override';

use vars qw/ $VERSION /;

$VERSION = '0.03';

require Exporter;

our @ISA = qw/Exporter/;
our @EXPORT_OK = qw( translate_from_FITS translate_to_FITS push_class @generic_headers _fix_local_date );

our %EXPORT_TAGS = (
                    'all' => [ qw( @EXPORT_OK ) ],
                    'variables' => [ qw( @generic_headers ) ],
                    );

my $DEBUG = 0;

# M E T H O D S ------------------------------------------------------------

=head1 REVISION

$Id$

=head1 PUBLIC VARIABLES

The following variables are not exported by default, but can be exported.

=over 4

=item B<@generic_headers>

Provides a list of generic headers that may or may not be available in the
generic header hash, depending on if translations were set up for these
headers in the instrument-specific subclasses.

Currently only the time-related headers (UTSTART, UTEND, and UTDATE) have
type-checking done; these three generic headers must be returned as
C<Time::Piece> objects when translating from FITS headers into generic
headers, and must be given as C<Time::Piece> objects when translating
from generic headers back into FITS headers. A warning is raised if any
of these headers are not C<Time::Piece> objects.

=back

=cut

our @generic_headers = qw( AIRMASS_START
                           AIRMASS_END
                           ALTITUDE
                           AMBIENT_TEMPERATURE
                           AZIMUTH_START
                           AZIMUTH_END
                           BACKEND
                           BACKEND_SECTIONS
                           BOLOMETERS
                           CAMERA
                           CHOP_ANGLE
                           CHOP_COORDINATE_SYSTEM
                           CHOP_FREQUENCY
                           CHOP_THROW
                           CONFIGURATION_INDEX
                           COORDINATE_SYSTEM
                           COORDINATE_UNITS
                           COORDINATE_TYPE
                           CYCLE_LENGTH
                           DEC_BASE
                           DEC_SCALE
                           DEC_SCALE_UNITS
                           DEC_TELESCOPE_OFFSET
                           DETECTOR_BIAS
                           DETECTOR_INDEX
                           DETECTOR_READ_TYPE
                           DR_GROUP
                           DR_RECIPE
                           ELEVATION_START
                           ELEVATION_END
                           EPOCH
                           EQUINOX
                           EXPOSURE_TIME
                           FILENAME
                           FILTER
                           GAIN
                           GALACTIC_LATITUDE
                           GALACTIC_LONGITUDE
                           GRATING_DISPERSION
                           GRATING_NAME
                           GRATING_ORDER
                           GRATING_WAVELENGTH
                           HUMIDITY
                           INSTRUMENT
                           INST_DHS
                           LATITUDE
                           LONGITUDE
                           MSBID
                           NSCAN_POSITIONS
                           NUMBER_OF_COADDS
                           NUMBER_OF_CYCLES
                           NUMBER_OF_DETECTORS
                           NUMBER_OF_EXPOSURES
                           NUMBER_OF_OFFSETS
                           NUMBER_OF_READS
                           NUMBER_OF_SUBFRAMES
                           NUMBER_OF_SUBSCANS
                           OBJECT
                           OBSERVATION_MODE
                           OBSERVATION_NUMBER
                           OBSERVATION_TYPE
                           POLARIMETER
                           POLARIMETRY
                           PROJECT
                           RA_BASE
                           RA_SCALE
                           RA_SCALE_UNITS
                           RA_TELESCOPE_OFFSET
                           RECEIVER_TEMPERATURE
                           REST_FREQUENCY
                           ROTATION
                           SAMPLING
                           SCAN_INCREMENT
                           SEEING
                           SLIT_ANGLE
                           SLIT_NAME
                           SLIT_WIDTH
                           SPEED_GAIN
                           STANDARD
                           SWITCH_MODE
                           SYSTEM_TEMPERATURE
                           SYSTEM_VELOCITY
                           TAU
                           TELESCOPE
			   TILE_NUMBER
                           USER_AZIMUTH_CORRECTION
                           USER_ELEVATION_CORRECTION
                           UTDATE
                           UTEND
                           UTSTART
                           VELOCITY
                           VELOCITY_REFERENCE_FRAME
                           VELOCITY_TYPE
                           WAVEPLATE_ANGLE
                           X_BASE
                           Y_BASE
                           X_OFFSET
                           Y_OFFSET
                           X_REQUESTED
                           Y_REQUESTED
                           X_SCALE
                           Y_SCALE
                           X_DIM
                           Y_DIM
                           X_LOWER_BOUND
                           X_UPPER_BOUND
                           Y_LOWER_BOUND
                           Y_UPPER_BOUND
                           ZENITH_DISTANCE_START
                           ZENITH_DISTANCE_END
                         );

=head1 PRIVATE VARIABLES

The following variables are private to this module.

=over 4

=item B<@valid_classes>

This parameter is a list of valid classes for which translations
can be made. A class in this list does not include the
C<Astro::FITS::HdrTrans> prefix. For example, if the
C<Astro::FITS::HdrTrans::IRCAM> class were to be used for translations,
this list would include only C<IRCAM>.

Values in this list are case-sensitive.

Values in this list can be added to using the C<push_class> method.

=back

=cut

my @valid_classes = qw/ IRCAM CGS4 UIST UFTI JCMT_GSD JCMT_GSD_DB MICHELLE SCUBA SCUBA2 UKIRTDB WFCAM /;

=head1 PUBLIC METHODS

The following methods are not exported by default, but can be exported.

=over 4

=item B<translate_from_FITS>

Converts a hash containing instrument-specific FITS headers into a hash
containing generic headers.

  %generic_headers = translate_from_FITS(\%FITS_headers,
                                         class => \@classes,
                                         prefix => 'ORAC_',
                                        );

This method takes a reference to a hash containing untranslated headers,
and a hash reference containing the following optional keys:

=over 8

=item *

class - A reference to a list of subclasses to try to use for header
translations. This list overrides the default list. If left blank, the
default list will be used, as stored in C<@valid_classes>. This is sometimes
required to break degeneracy when you know you have a limited set of
valid instruments.

=item *

prefix - A string prefix to add to the front of every translated header name.
For example, if this prefix is set to 'ORAC_', then the translated header
for the instrument value, whose key is normally 'INSTRUMENT', will have a
key named 'ORAC_INSTRUMENT'. The original keys will not be in the
returned hash. If left blank, no prefix will be added.

=back

This method returns a hash of generic headers. This function dies if
the header translation fails in any way.

=cut

sub translate_from_FITS {
  my $FITS_header = shift;
  my %options = @_;

  my $instrument;
  my %generic_header;

  my @classes;
  if( exists( $options{class} ) &&
      defined( $options{class} ) &&
      ref( $options{class} ) eq 'ARRAY' ) {
    @classes = @{$options{class}};
  } else {
    @classes = @valid_classes;
  }

  my $prefix;
  if( exists( $options{prefix} ) &&
      defined( $options{prefix} ) ) {
    $prefix = $options{prefix};
  } else {
    $prefix = '';
  }

  # Determine the instrument name so we can use the appropriate subclass
  # for header translations. We're going to use the "valid_class" method
  # in each subclass listed in @classes.
  my %result = ();
  foreach my $subclass ( @classes ) {

    my $class = "Astro::FITS::HdrTrans::".$subclass;

    print "Trying class $class\n" if $DEBUG;

    eval "require $class";
    next if ( $@ );
    my $method = $class."::valid_class";
    if( exists( &$method ) ) {
      no strict 'refs';
      if( &$method( $FITS_header ) ) {
        print "Class $class matches\n" if $DEBUG;
        $result{$subclass}++;
      }
    } else {
      # What to do, what to do?
    }
  }

  if( ( scalar keys %result ) > 1 ) {
    croak "Ambiguities in determining which header translations to use";
  }

  if( ( scalar keys %result ) == 0 ) {
    # We couldn't figure out which one to use.
    croak "Unable to determine header translation subclass";
  }

  my @subclasses = keys %result;

  # Do the translation.
  my $class = "Astro::FITS::HdrTrans::" . $subclasses[0];
  eval "require $class";
  if( $@ ) { croak "Could not load module $class"; }
  {
    no strict 'refs';

    for my $key ( @generic_headers ) {

      my $hdrkey = $prefix . $key;

      # Build the string to be eval'ed.
      my $evalstring = "if( exists( \${".$class."::hdr{$key}} ) ) {\n";
      $evalstring .=   "  \$generic_header{$hdrkey} = \$FITS_header->{\${" . $class . "::hdr{$key}}}\n";
      $evalstring .=   "} else {\n";
      $evalstring .=   "  my \$subname = \"".$class."::to_$key\";\n";
      $evalstring .=   "  if( exists ( &\$subname ) ) {\n";
      $evalstring .=   "    \$generic_header{$hdrkey} = &\$subname(\$FITS_header);\n";
      $evalstring .=   "  }\n";
      $evalstring .=   "}\n";

      eval $evalstring;
      if( $@ ) { croak "Could not run header translation eval: $@"; }
    }
  }

  # Do the check on UTSTART, UTEND, and UTDATE. These must
  # be Time::Piece objects.
  if( exists( $generic_header{'UTSTART'} ) &&
      defined( $generic_header{'UTSTART'} ) ) {
    if( ! UNIVERSAL::isa( $generic_header{'UTSTART'}, "Time::Piece" ) ) {
      warnings::warnif( "Warning: UTSTART generic header is not a Time::Piece object" );
    } else {
      $generic_header{'UTSTART'} = _fix_local_date( $generic_header{'UTSTART'} );
    }
  }

  if( exists( $generic_header{'UTEND'} ) &&
      defined( $generic_header{'UTEND'} ) ) {
    if( ! UNIVERSAL::isa( $generic_header{'UTEND'}, "Time::Piece" ) ) {
      warnings::warnif( "Warning: UTEND generic header is not a Time::Piece object" );
    } else {
      $generic_header{'UTEND'} = _fix_local_date( $generic_header{'UTEND'} );
    }
  }

  if( exists( $generic_header{'UTDATE'} ) &&
      defined( $generic_header{'UTDATE'} ) ) {
    if( ! UNIVERSAL::isa( $generic_header{'UTDATE'}, "Time::Piece" ) ) {
      warnings::warnif( "Warning: UTDATE generic header is not a Time::Piece object" );
    } else {
      $generic_header{'UTDATE'} = _fix_local_date( $generic_header{'UTDATE'} );
    }
  }

  return %generic_header;

}

=item B<translate_to_FITS>

Converts a hash containing generic headers into one containing
instrument-specific FITS headers.

  %FITS_headers = translate_to_FITS(\%generic_headers,
                                    class => \@classes,
                                   );

This method takes a reference to a hash containing untranslated
headers, and a hash reference containing the following optional
keys:

=over 8

=item *

class - A reference to a list of subclasses to try to use for header
translations. This list overrides the default list. If left blank, the
default list will be used.

=item *

prefix - A string prefix to remove from the generic header key
before doing header translation. Why you would want to do this
is if you've used a prefix in the C<translate_from_FITS> call, and
want to translate back from the generic headers returned from
that method. If left blank, no prefix will be removed.

=back

This method returns a hash of instrument-specific headers.  This
function dies if the header translation fails in any way.

=cut

sub translate_to_FITS {
  my $generic_header = shift;
  my %options = @_;

  my $instrument;
  my %FITS_header;

  my @classes;
  if( exists( $options{class} ) &&
      defined( $options{class} ) &&
      ref( $options{class} ) eq 'ARRAY' ) {
    @classes = @{$options{class}};
  } else {
    @classes = @valid_classes;
  }

  my $prefix;
  if( exists( $options{prefix} ) &&
      defined( $options{prefix} ) ) {
    $prefix = $options{prefix};
  } else {
    $prefix = '';
  }

  # We need to strip off any prefix before figuring out what
  # class we need to use.
  my %stripped_header;
  while( my ( $key, $value ) = each( %{$generic_header} ) ) {
    $key =~ s/^$prefix//;
    $stripped_header{$key} = $value;
  }

  # Check the UTSTART, UTEND, and UTDATE headers to make sure they're
  # Time::Piece objects.
  if( exists( $stripped_header{'UTSTART'} ) &&
      defined( $stripped_header{'UTSTART'} ) &&
      ! UNIVERSAL::isa( $stripped_header{'UTSTART'}, "Time::Piece" ) ) {
    warnings::warnif( "Warning: UTSTART generic header is not a Time::Piece object" );
  }

  if( exists( $stripped_header{'UTEND'} ) &&
      defined( $stripped_header{'UTEND'} ) &&
      ! UNIVERSAL::isa( $stripped_header{'UTEND'}, "Time::Piece" ) ) {
    warnings::warnif( "Warning: UTEND generic header is not a Time::Piece object" );
  }

  if( exists( $stripped_header{'UTDATE'} ) &&
      defined( $stripped_header{'UTDATE'} ) &&
      ! UNIVERSAL::isa( $stripped_header{'UTDATE'}, "Time::Piece" ) ) {
    warnings::warnif( "Warning: UTDATE generic header is not a Time::Piece object" );
  }

  # Determine the instrument name so we can use the appropriate subclass
  # for header translations. We're going to use the "valid_class" method
  # in each subclass listed in @classes.
  my %result = ();
  foreach my $subclass ( @classes ) {

    my $class = "Astro::FITS::HdrTrans::".$subclass;

    print "Trying class $class\n" if $DEBUG;

    eval "require $class";
    next if ( $@ );
    my $method = $class."::valid_class";
    if( exists( &$method ) ) {
      no strict 'refs';
      if( &$method( \%stripped_header ) ) {
        print "Class $class is valid\n" if $DEBUG;
        $result{$subclass}++;
      }
    } else {
      # What to do, what to do?
    }
  }

  if( ( scalar keys %result ) > 1 ) {
    croak "Ambiguities in determining which header translations to use";
  }

  if( ( scalar keys %result ) == 0 ) {
    # We couldn't figure out which one to use.
    croak "Unable to determine header translation subclass";
  }

  my @subclasses = keys %result;

  # Do the translation.
  my $class = "Astro::FITS::HdrTrans::" . $subclasses[0];

  print "Using class $class for header translation.\n" if $DEBUG;

  eval "require $class";
  if( $@ ) { croak "Could not load module $class: $@"; }
  {
    no strict 'refs';

    for my $key ( @generic_headers ) {

      # Build the string to be eval'ed.
      my $evalstring = "if( exists( \${".$class."::hdr{$key}} ) ) {\n";
      $evalstring .=   "  \$FITS_header{\${".$class."::hdr{$key}}} = \$stripped_header{$key};\n";
      $evalstring .=   "} else {\n";
      $evalstring .=   "  my \$subname = \"".$class."::from_$key\";\n";
      $evalstring .=   "  if( exists( &\$subname ) ) {\n";
      $evalstring .=   "    my \%new = &\$subname(\\\%stripped_header);\n";
      $evalstring .=   "    for my \$newkey ( keys \%new ) {\n";
      $evalstring .=   "      \$FITS_header{\$newkey} = \$new{\$newkey};\n";
      $evalstring .=   "    }\n";
      $evalstring .=   "  }\n";
      $evalstring .=   "}\n";

      eval $evalstring;
      if( $@ ) { croak "Could not run header translation eval: $@"; };
    }
  }

  return %FITS_header;

}

=item B<push_class>

Allows another class to be pushed onto the list of valid classes.

  push_class( \@classes );
  push_class( $class );

If an array reference is passed, all classes contained in that array
will be added to the list. If a scalar is passed, that single class
will be added to the list.

=cut

sub push_class {
  my $class = shift;

  if( ref( $class ) eq 'ARRAY' ) {
    push @valid_classes, @$class;
  } else {
    push @valid_classes, $class;
  }

  return 1;

}

=back

=head1 PRIVATE METHODS

These methods are private.

=over 4

=item B<_fix_local_date>

Because of inconsistancies in Time::Piece, a returned date may be
in localtime rather than UTC. This method converts these dates into
UTC.

=cut

sub _fix_local_date {
  my $date = shift;

  if( ! UNIVERSAL::isa( $date, "Time::Piece" ) ) {
    croak "Must pass Time::Piece object to _fix_local_date";
  }

  if( $date->[Time::Piece::c_islocal] ) {
    my $epoch = $date->epoch;
    my $tzoffset = $date->tzoffset;
    $epoch += $tzoffset->seconds;
    $date = gmtime( $epoch );
  }

  return $date;
}

=back

=head1 GENERIC HEADERS

The following is a list of currently-supported generic headers.
If no type is defined for the header, then it is assumed to be
a scalar in any format.

=over 8

=item AIRMASS_START - Airmass at the start of the observation.

=item AIRMASS_END - Airmass at the end of the observation.

=item ALTITUDE - Telescope altitude. Must be in meters above mean
sea level.

=item AMBIENT_TEMPERATURE - Ambient temperature at the telescope.

=item APERTURE - Aperture.

=item AZIMUTH_START - Telescope azimuth at the start of the observation.

=item AZIMUTH_END - Telescope azimuth at the end of the observation.

=item BACKEND - Backend used.

=item BACKEND_SECTIONS - Number of backend sections.

=item BOLOMETERS - Number of bolometers used in array.

=item CAMERA - Camera used for observation.

=item CHOP_ANGLE - Chop angle.

=item CHOP_COORDINATE_SYSTEM - Coordinate system used for chopping.

=item CHOP_FREQUENCY - Frequency of chop.

=item CHOP_THROW - Distance of chop throw.

=item CONFIGURATION_INDEX - Unique identifier for hardware configuration.

=item COORDINATE_UNITS - Units of coordinate system.

=item COORDINATE_TYPE - Type of coordinate (typically B1950 or J2000).

=item CYCLE_LENGTH - Length of observation cycle.

=item DEC_BASE - Base declination position of observation. Must be
a string in colon-delimited sexagesimal format (ie. +41:16:09.4), where
the degrees, minutes, and seconds are zero-padded to two digits.

=item DEC_SCALE - Pixel scale in declination.

=item DEC_SCALE_UNITS - Units for declination pixel scale.

=item DEC_TELESCOPE_OFFSET - Offset in declination from base position. Must
be in arcseconds.

=item DETECTOR_BIAS - Detector bias.

=item DETECTOR_INDEX - Position number in detector scan.

=item DETECTOR_READ_TYPE - Read type of detector.

=item DR_GROUP - Data reduction group to which observation belongs.

=item DR_RECIPE - Data reduction recipe to be used.

=item ELEVATION_START - Telescope elevation at the start of the observation.
Must be in degrees. 90 is zenith, 0 is horizon.

=item ELEVATION_END - Telescope elevation at the end of the observation.
Must be in degrees. 90 is zenith, 0 is horizon.

=item EPOCH - Epoch in which observation was taken.

=item EQUINOX - Equinox in which observation was taken.

=item EXPOSURE_TIME - Exposure time of observation. Must be in
decimal seconds.

=item FILENAME - Name of data file.

=item FILTER - Filter in which observation was taken.

=item FRONTEND - Name of frontend used.

=item FREQUENCY_RESOLUTION - Frequency resolution.

=item GAIN - Detector gain.

=item GALACTIC_LATITUDE - Galactic latitude of observation. Must be a
colon-separated sexagesimal string (ie. 121:10:12).

=item GALACTIC_LONGITUDE - Galactic longitude of observation. Must be
a colon-separated sexagesimal string (ie. -21:34:12).

=item GRATING_DISPERSION - Wavelength dispersion.

=item GRATING_NAME - Name of grating/grism used.

=item GRATING_ORDER - Order of grating/grism used.

=item GRATING_WAVELENGTH - Central wavelength of grating/grism used.

=item HUMIDITY - Relative humidity.

=item INSTRUMENT - Instrument name.

=item INST_DHS - Unique combination of instrument name and data handling
system.

=item LATITUDE - Latitude of telescope. Must be a colon-separated
sexagesimal string (ie. 19:49:20.75).

=item LONGITUDE - Longitude of telescope. Must be a colon-separated
sexagesimal string (ie. -155:28:13.18).

=item MSBID - Unique identifier for minimum schedulable block.

=item NSCAN_POSITIONS - Number of scan positions.

=item NUMBER_OF_COADDS - Number of coadds.

=item NUMBER_OF_CYCLES - Number of cycles.

=item NUMBER_OF_DETECTORS - Number of detectors.

=item NUMBER_OF_EXPOSURES - Number of exposures.

=item NUMBER_OF_OFFSETS - Number of offsets in dither pattern.

=item NUMBER_OF_READS - Number of reads.

=item NUMBER_OF_SUBFRAMES - Number of subframes.

=item NUMBER_OF_SUBSCANS - Number of subscans.

=item OBJECT - Object name.

=item OBSERVATION_MODE - Mode of observation for multi-mode instruments.

=item OBSERVATION_NUMBER - Number of observation.

=item OBSERVATION_TYPE - Type of observation (ie. DARK, FLAT, etc.)

=item POLARIMETER - Is the polarimeter in the beam?

=item POLARIMETRY - Polarimetry mode?

=item PROJECT - Project name.

=item RA_BASE - Base right ascension position of observation. Must be
a colon-delimited sexagesimal string (ie. 00:42:44.31).

=item RA_SCALE - Pixel scale in right ascension.

=item RA_SCALE_UNITS - Units for right ascension pixel scale.

=item RA_TELESCOPE_OFFSET - Offset in right ascension from base position.
Must be in arcseconds.

=item RECEIVER_TEMPERATURE - Receiver temperature.

=item REST_FREQUENCY - Rest frequency of spectral line.

=item ROTATION - Angle of the declination axis with respect to the
frame's y axis, measured counter-clockwise.

=item SAMPLING - Sampling type.

=item SCAN_INCREMENT - Increment of scan.

=item SEEING - Seeing when observation was taken.

=item SLIT_ANGLE - Angle of slit on sky.

=item SLIT_NAME - Name of slit used.

=item SLIT_WIDTH - Width of slit.

=item SPEED_GAIN - Readout speed.

=item STANDARD - Is observation of a standard?

=item SWITCH_MODE - Switching mode.

=item SYSTEM_TEMPERATURE - System temperature.

=item SYSTEM_VELOCITY - System velocity.

=item TAU - Atmospheric extinction at time of observation.

=item TELESCOPE - Name of telescope.

=item USER_AZIMUTH_CORRECTION - Correction in azimuth input by
the user.

=item USER_ELEVATION_CORRECTION - Correction in elevation input
by the user.

=item UTDATE - UT date on which observation was taken. Must be
a Time::Piece object.

=item UTEND - End time of observation. Must be a Time::Piece
object.

=item UTSTART - Start time of observation. Must be a Time::Piece
object.

=item VELOCITY - Radial velocity of the source.

=item VELOCITY_REFERENCE_FRAME - Velocity frame of reference.

=item VELOCITY_TYPE - Type of velocity, typically radio, optical,
or relativistic.

=item WAVEPLATE_ANGLE - Polarimetry waveplate angle.

=item X_BASE - Base x-position of observation.

=item Y_BASE - Base y-position of observation.

=item X_OFFSET - Offset in x-direction from base position.

=item Y_OFFSET - Offset in y-direction from base position.

=item X_REQUESTED - Requested x-position of observation.

=item Y_REQUESTED - Requested y-position of observation.

=item X_SCALE - Pixel scale in x-direction.

=item Y_SCALE - Pixel scale in y-direction.

=item X_DIM - Size of array in x-direction.

=item Y_DIM - Size of array in y-direction.

=item X_LOWER_BOUND - Lower bound of array in x-direction.

=item X_UPPER_BOUND - Upper bound of array in x-direction.

=item Y_LOWER_BOUND - Lower bound of array in y-direction.

=item Y_UPPER_BOUND - Upper bound of array in y-direction.

=item ZENITH_DISTANCE_START - Zenith distance at start of observation.

=item ZENITH_DISTANCE_END - Zenith distance at end of observation.

=back

=head1 NOTES

=over 4

=item *

A number of the generic headers are more easily represented by
objects. For example, all headers to do with the object coordinates
(DEC_BASE, COORDINATE_UNITS, COORDINATE_TYPE, EPOCH, EQUINOX, and
RA_BASE) are be better represented with a single C<Astro::Coords>
object. Such headers will at some point be merged into a single object
header, but for backwards compatibility will be retained.

=back

=head1 AUTHOR

Brad Cavanagh E<lt>b.cavanagh@jach.hawaii.eduE<gt>

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
