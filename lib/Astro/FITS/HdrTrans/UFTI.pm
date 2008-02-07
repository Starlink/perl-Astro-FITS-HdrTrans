# -*-perl-*-

package Astro::FITS::HdrTrans::UFTI;

=head1 NAME

Astro::FITS::HdrTrans::UFTI - UKIRT UFTI translations

=head1 SYNOPSIS

  use Astro::FITS::HdrTrans::UFTI;

  %gen = Astro::FITS::HdrTrans::UFTI->translate_from_FITS( %hdr );

=head1 DESCRIPTION

This class provides a generic set of translations that are specific to
the UFTI camera of the United Kingdom Infrared Telescope.

=cut

use 5.006;
use warnings;
use strict;
use Carp;

# Inherit from UKIRTNew
use base qw/ Astro::FITS::HdrTrans::UKIRTNew /;

# we also want to import a restrictive set of FITS functionality
use Astro::FITS::HdrTrans::FITS qw/ DEC_SCALE RA_SCALE ROTATION /;

use vars qw/ $VERSION /;

$VERSION = sprintf("%d", q$Revision$ =~ /(\d+)/);

# for a constant mapping, there is no FITS header, just a generic
# header that is constant
my %CONST_MAP = (

		);

# NULL mappings used to override base class implementations
my @NULL_MAP = qw/ DETECTOR_INDEX /;

# unit mapping implies that the value propogates directly
# to the output with only a keyword name change

my %UNIT_MAP = (
		# UFTI specific
		EXPOSURE_TIME        => "INT_TIME",
		# CGS4 + IRCAM
		DETECTOR_READ_TYPE   => "MODE",
		# MICHELLE + IRCAM compatible
		SPEED_GAIN           => "SPD_GAIN",

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

Returns "UFTI".

=cut

sub this_instrument {
  return "UFTI";
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

=item B<to_UTDATE>

Converts FITS header values into C<Time::Piece> object. This differs
from the base class in the use of the DATE rather than UTDATE header item
and the formatting of the DATE keyword is not an integer.

=cut

sub to_UTDATE {
  my $self = shift;
  my $FITS_headers = shift;
  my $return;
  if(exists($FITS_headers->{DATE})) {
    my $utdate = $FITS_headers->{DATE};
    $return = Time::Piece->strptime( $utdate, "%Y-%m-%d" );
    $return = $return->strftime('%Y%m%d');
  }

  return $return;
}

=item B<from_UTDATE>

Converts UT date in C<Time::Piece> object into C<YYYY-MM-DD> format
for DATE header. This differs from the base class in the use of the
DATE rather than UTDATE header item.

=cut

sub from_UTDATE {
  my $self = shift;
  my $generic_headers = shift;
  my %return_hash;
  if(exists($generic_headers->{UTDATE})) {
    my $date = $generic_headers->{UTDATE};
    $date = Time::Piece->strptime($date,'%Y%m%d');
    return () unless defined $date;
    $return_hash{DATE} = sprintf("%04d-%02d-%02d", 
                                 $date->year, $date->mon, $date->mday);
  }
  return %return_hash;
}

=back

=head1 REVISION

 $Id$

=head1 SEE ALSO

C<Astro::FITS::HdrTrans>, C<Astro::FITS::HdrTrans::UKIRT>.

=head1 AUTHOR

Brad Cavanagh E<lt>b.cavanagh@jach.hawaii.eduE<gt>,
Tim Jenness E<lt>t.jenness@jach.hawaii.eduE<gt>.

=head1 COPYRIGHT

Copyright (C) 2008 Science and Technology Facilities Council.
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
