package Astro::FITS::HdrTrans::JCMT;

use strict;
use warnings;

use Astro::Coords;
use Astro::Telescope;
use DateTime;
use DateTime::TimeZone;

use base qw/ Astro::FITS::HdrTrans::JAC /;

# Unit mapping implies that the value propogates directly
# to the output with only a keyword name change.
my %UNIT_MAP =
  (
    AIRMASS_START        => 'AMSTART',
    AZIMUTH_START        => 'AZSTART',
    ELEVATION_START      => 'ELSTART',
    FILENAME             => 'FILE_ID',
    HUMIDITY             => 'HUMSTART',
    LATITUDE             => 'LAT-OBS',
    LONGITUDE            => 'LONG-OBS',
    OBJECT               => 'OBJECT',
    OBSERVATION_NUMBER   => 'OBSNUM',
    PROJECT              => 'PROJECT',
    STANDARD             => 'STANDARD',
    X_APERTURE           => 'INSTAP_X',
    Y_APERTURE           => 'INSTAP_Y',
  );

my %CONST_MAP = ();

# Create the translation methods
__PACKAGE__->_generate_lookup_methods( \%CONST_MAP, \%UNIT_MAP );

our $COORDS;

=item B<translate_from_FITS>

This routine overrides the base class implementation to enable the
caches to be cleared for target location.

This means that some conversion methods (in particular those using time in
a base class) may not work properly outside the context of a full translation
unless they have been subclassed locally.

Date fixups are handled in a super class.

=cut

sub translate_from_FITS {
  my $class = shift;
  my $headers = shift;

  # clear cache
  $COORDS = undef;

  # Go to the base class
  return $class->SUPER::translate_from_FITS( $headers, @_ );
}

sub to_UTDATE {
  my $class = shift;
  my $FITS_headers = shift;

  $class->_fix_dates( $FITS_headers );
  return $class->SUPER::to_UTDATE( $FITS_headers, @_ );
}

sub to_UTEND {
  my $class = shift;
  my $FITS_headers = shift;

  $class->_fix_dates( $FITS_headers );
  return $class->SUPER::to_UTEND( $FITS_headers, @_ );
}

sub to_UTSTART {
  my $class = shift;
  my $FITS_headers = shift;

  $class->_fix_dates( $FITS_headers );
  return $class->SUPER::to_UTSTART( $FITS_headers, @_ );
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
  return undef unless defined $coords;
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

  my $coords = $self->_calc_coords( $FITS_headers );

  return undef unless defined $coords;
  return $coords->dec( format => 'deg' );
}

=item B<to_TAU>

Use the average WVM tau measurements.

=cut

sub to_TAU {
  my $self = shift;
  my $FITS_headers = shift;

  my $tau = 0.0;
  for my $src (qw/ TAU225 WVMTAU /) {
    my $st = $src . "ST";
    my $en = $src . "EN";

    my @startvals = $self->via_subheader_undef_check( $FITS_headers, $st );
    my @endvals   = $self->via_subheader_undef_check( $FITS_headers, $en );
    my $startval = $startvals[0];
    my $endval = $endvals[-1];

    if (defined $startval && defined $endval) {
      $tau = ($startval + $endval) / 2;
      last;
    } elsif (defined $startval) {
      $tau = $startval;
    } elsif (defined $endval) {
      $tau = $endval;
    }
  }
  return $tau;
}

=item B<to_OBSERVATION_ID_SUBSYSTEM>

Returns the subsystem observation IDs associated with the header.
Returns a reference to an array. Will be empty if the OBSIDSS header
is missing.

=cut

sub to_OBSERVATION_ID_SUBSYSTEM {
  my $self = shift;
  my $FITS_headers = shift;
  # Try multiple headers since the database is different to the file
  my @obsidss;
  for my $h (qw/ OBSIDSS OBSID_SUBSYSNR /) {
    my @found = $self->via_subheader( $FITS_headers, $h );
    if (@found) {
      @obsidss = @found;
      last;
    }
  }
  my @all;
  if (@obsidss) {
    # Remove duplicates
    my %seen;
    @all = grep { ! $seen{$_}++ } @obsidss;
  }
  return \@all;
}

=head1 PRIVATE METHODS

=over 4

=item B<_calc_coords>

Function to calculate the coordinates at the start of the observation by using
the elevation, azimuth, telescope, and observation start time. Caches
the result if it's already been calculated.

Returns an Astro::Coords object.

=cut

sub _calc_coords {
  my $self = shift;
  my $FITS_headers = shift;

  # Force dates to be standardized
  $self->_fix_dates( $FITS_headers );

  # Here be dragons. Possibility that cache will not be cleared properly
  # if a user comes in outside of the translate_from_FITS() method.
  if ( defined( $COORDS ) &&
       UNIVERSAL::isa( $COORDS, "Astro::Coords" ) ) {
    return $COORDS;
  }

  if ( exists( $FITS_headers->{'TELESCOP'} ) &&
       exists( $FITS_headers->{'DATE-OBS'} ) &&
       exists( $FITS_headers->{'AZSTART'} )  &&
       exists( $FITS_headers->{'ELSTART'} )  &&
       defined $FITS_headers->{AZSTART} &&
       defined $FITS_headers->{ELSTART}
     ) {

    my $dateobs   = $FITS_headers->{'DATE-OBS'};
    my $telescope = $FITS_headers->{'TELESCOP'};
    my $az_start  = $FITS_headers->{'AZSTART'};
    my $el_start  = $FITS_headers->{'ELSTART'};

    my $coords = new Astro::Coords( az => $az_start,
                                    el => $el_start,
                                  );
    $coords->telescope( new Astro::Telescope( $telescope ) );

    # convert ISO date to object
    my $dt = Astro::FITS::HdrTrans::Base->_parse_iso_date( $dateobs );
    return unless defined $dt;

    $coords->datetime( $dt );

    $COORDS = $coords;
    return $COORDS;
  }

  return undef;
}

=back

=pod

=head1 NAME

Astro::FITS::HdrTrans::JCMT - class combining common behaviour for mordern JCMT
instruments

=head2 SYNOPSIS

XXX To be supplied.

=head1 DESCRIPTION

XXX To be supplied.

=head2 METHODS

=over 4

=item B<to_UTDATE>

Converts the date in a date-obs header into a number of form YYYYMMDD.

=item B<to_UTEND>

Converts UT date in a date-end header into C<Time::Piece> object

=item B<to_UTSTART>

Converts UT date in a date-obs header into C<Time::Piece> object.

=back

=head1 SEE ALSO

C<Astro::FITS::HdrTrans>,
C<Astro::FITS::HdrTrans::Base>,
C<Astro::FITS::HdrTrans::JAC>.

=head1 AUTHORS

Anubhav E<lt>a.agarwal@jach.hawawii.eduE<gt>,
Brad Cavanagh E<lt>b.cavanagh@jach.hawaii.eduE<gt>,
Tim Jenness E<lt>t.jenness@jach.hawaii.eduE<gt>.

=head1 COPYRIGHT

Copyright (C) 2009 Science and Technology Facilities Council.
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
