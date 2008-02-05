# -*-perl-*-

package Astro::FITS::HdrTrans::UKIRTNew;

=head1 NAME

Astro::FITS::HdrTrans::UKIRTNew - Base class for translation of new UKIRT instruments

=head1 SYNOPSIS

  use Astro::FITS::HdrTrans::UKIRTNew;

=head1 DESCRIPTION

This class provides a generic set of translations that are common to
the newer generation of instruments from the United Kingdom Infrared
Telescope.  This includes MICHELLE, UIST, UFTI and WFCAM. It should
not be used directly for translation of instrument FITS headers.

=cut

use 5.006;
use warnings;
use strict;
use Carp;

# Inherit from UKIRT
use base qw/ Astro::FITS::HdrTrans::UKIRT /;

# Use the FITS standard DATE-OBS handling
use Astro::FITS::HdrTrans::FITS;

use vars qw/ $VERSION /;

$VERSION = sprintf("%d", q$Revision$ =~ /(\d+)/);

# for a constant mapping, there is no FITS header, just a generic
# header that is constant
my %CONST_MAP = (

		);

# unit mapping implies that the value propogates directly
# to the output with only a keyword name change

my %UNIT_MAP = (
		DEC_TELESCOPE_OFFSET => "TDECOFF",
		DR_RECIPE            => "RECIPE",
		GAIN                 => "GAIN",
		RA_TELESCOPE_OFFSET  => "TRAOFF",
                X_APERTURE           => "APER_X",
                Y_APERTURE           => "APER_Y",
	       );

# Create the translation methods
__PACKAGE__->_generate_lookup_methods( \%CONST_MAP, \%UNIT_MAP );

=head1 COMPLEX CONVERSIONS

These methods are more complicated than a simple mapping. We have to
provide both from- and to-FITS conversions All these routines are
methods and the to_ routines all take a reference to a hash and return
the translated value (a many-to-one mapping) The from_ methods take a
reference to a generic hash and return a translated hash (sometimes
these are many-to-many)

=over 4

=item B<to_UTDATE>

Converts FITS header values into one unified UT start date value.

=cut

sub to_UTDATE {
  my $self = shift;
  my $FITS_headers = shift;
  my $return;
  if(exists($FITS_headers->{UTDATE})) {
    my $utdate = $FITS_headers->{UTDATE};
    $return = Time::Piece->strptime( $utdate, "%Y%m%d" );
  }

  return $return;
}

=item B<from_UTDATE>

Converts UT date in the form C<yyyy-mm-dd> to C<yyyymmdd>.

=cut

sub from_UTDATE {
  my $self = shift;
  my $generic_headers = shift;
  my %return_hash;
  if( exists( $generic_headers->{UTDATE} ) ) {
    my $date = $generic_headers->{UTDATE};
    if( ! UNIVERSAL::isa( $date, "Time::Piece" ) ) { return; }
    $return_hash{UTDATE} = sprintf("%4d%02d%02d", $date->year, $date->mon, $date->mday);

  }
  return %return_hash;
}

=item B<to_UTSTART>

Converts UT date in C<DATE-OBS> header into C<Time::Piece> object.

=cut

sub to_UTSTART {
  my $self = shift;
  my $FITS_headers = shift;
  my $return;
  if(exists($FITS_headers->{'DATE-OBS'})) {
    my $utstart = $FITS_headers->{'DATE-OBS'};
    $utstart =~ s/Z//g;

    # use the standard FITS parser now that we have dropped the Z
    $return = Astro::FITS::HdrTrans::FITS->to_UTSTART( { 'DATE-OBS' => 
							   $utstart});
  }
  return $return;
}

=item B<from_UTSTART>

Returns the starting observation time in ISO8601 format:
YYYY-MM-DDThh:mm:ss.

=cut


sub from_UTSTART {
  my $self = shift;
  my $generic_headers = shift;

  # use the FITS standard parser
  my %return_hash = Astro::FITS::HdrTrans::FITS->from_UTSTART( $generic_headers);

  if (exists $return_hash{'DATE-OBS'}) {
    # prior to April 2005 the UKIRT FITS headers had a trailing Z
    # Part of the ISO8601 standard but not part of the FITS standard
    # (which always assumes UTC)
    $return_hash{'DATE-OBS'} .= "Z"
      if $generic_headers->{UTSTART}->epoch < 1112662116;
  }
  return %return_hash;
}

=item B<to_UTEND>

Converts UT date in C<DATE-END> header into C<Time::Piece> object.

=cut

sub to_UTEND {
  my $self = shift;
  my $FITS_headers = shift;
  my $return;
  if(exists($FITS_headers->{'DATE-END'})) {
    my $utstart = $FITS_headers->{'DATE-END'};
    $utstart =~ s/Z//g;

    # use the standard FITS parser now that we have dropped the Z
    $return = Astro::FITS::HdrTrans::FITS->to_UTEND( { 'DATE-END' => 
						       $utstart});
  }
  return $return;
}

=item B<from_UTEND>

Returns the starting observation time in ISO8601 format:
YYYY-MM-DDThh:mm:ss.

=cut


sub from_UTEND {
  my $self = shift;
  my $generic_headers = shift;

  # use the FITS standard parser
  my %return_hash = Astro::FITS::HdrTrans::FITS->from_UTEND( $generic_headers);

  if (exists $return_hash{'DATE-END'}) {
    # prior to April 2005 the UKIRT FITS headers had a trailing Z
    # Part of the ISO8601 standard but not part of the FITS standard
    # (which always assumes UTC)
    $return_hash{'DATE-END'} .= "Z"
      if $generic_headers->{UTEND}->epoch < 1112662116;
  }
  return %return_hash;
}

=item B<to_INST_DHS>

Sets the instrument data handling system header.

=cut

sub to_INST_DHS {
  my $self = shift;
  my $FITS_headers = shift;
  my $return;

  if( exists( $FITS_headers->{DHSVER} ) ) {
    $FITS_headers->{DHSVER} =~ /^(\w+)/;
    my $dhs = uc($1);
    $return = $FITS_headers->{INSTRUME} . "_$dhs";
  }

  return $return;

}

=back

=head1 REVISION

 $Id$

=head1 SEE ALSO

C<Astro::FITS::HdrTrans>, C<Astro::FITS::HdrTrans::UKIRT>

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
