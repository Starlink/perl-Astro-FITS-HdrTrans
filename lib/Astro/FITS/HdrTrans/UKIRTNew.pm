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
                UTDATE               => "UTDATE",
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

=item B<to_UTSTART>

Converts UT date in C<DATE-OBS> header into C<Time::Piece> object.

=cut

sub to_UTSTART {
  my $self = shift;
  my $FITS_headers = shift;
  my $dateobs = (exists $FITS_headers->{"DATE-OBS"} ?
                 $FITS_headers->{"DATE-OBS"} : undef );
  my @rutstart = sort {$a<=>$b} $self->via_subheader( $FITS_headers, "UTSTART" );
  my $utstart = $rutstart[0];
  return $self->_parse_date_info( $dateobs,
                                  $self->to_UTDATE( $FITS_headers ),
                                  $utstart );
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
  my $dateend = (exists $FITS_headers->{"DATE-END"} ?
                 $FITS_headers->{"DATE-END"} : undef );

  my @rutend = sort {$a<=>$b} $self->via_subheader( $FITS_headers, "UTEND" );
  use Data::Dumper; print Dumper(\@rutend, $FITS_headers);
  my $utend = $rutend[-1];
  return $self->_parse_date_info( $dateend,
                                  $self->to_UTDATE( $FITS_headers ),
                                  $utend );
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

Copyright (C) 2007-2008 Science and Technology Facilities Council.
Copyright (C) 2003-2007 Particle Physics and Astronomy Research Council.
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
