# -*-perl-*-

package Astro::FITS::HdrTrans::FITS;

=head1 NAME

Astro::FITS::HdrTrans::FITS - Standard FITS header translations

=head1 SYNOPSIS

  use Astro::FITS::HdrTrans::FITS;

  %gen = Astro::FITS::HdrTrans::FITS->translate_from_FITS( %hdr );

=head1 DESCRIPTION

This class provides a generic set of translations that are specific
to the (few) headers that are commonly standardised across most
FITS files.

Mainly deals with World Coordinate Systems and headers defined
in the FITS standards papers.

=cut

use 5.006;
use warnings;
use strict;
use Carp;

use base qw/ Astro::FITS::HdrTrans::Base /;

use vars qw/ $VERSION /;

$VERSION = sprintf("%d", q$Revision$ =~ /(\d+)/);

# for a constant mapping, there is no FITS header, just a generic
# header that is constant
my %CONST_MAP = (

                );

# unit mapping implies that the value propogates directly
# to the output with only a keyword name change

my %UNIT_MAP = (
                 DATA_UNITS           => 'BUNIT',
                 DEC_SCALE            => "CDELT2",
                 INSTRUMENT           => 'INSTRUME',
                 RA_SCALE             => "CDELT1",
                 ROTATION             => 'CROTA2',
                 TELESCOPE            => 'TELESCOP',
                 X_BASE               => "CRPIX1",
                 X_REFERENCE_PIXEL    => "CRPIX1",
                 Y_BASE               => "CRPIX2",
                 Y_REFERENCE_PIXEL    => "CRPIX2",
               );


# Create the translation methods
__PACKAGE__->_generate_lookup_methods( \%CONST_MAP, \%UNIT_MAP );

=head1 COMPLEX CONVERSIONS

These methods are more complicated than a simple mapping. We have to
provide both from- and to-FITS conversions All these routines are
methods and the to_ routines all take a reference to a hash and return
the translated value (a many-to-one mapping) The from_ methods take a
reference to a generic hash and return a translated hash (sometimes
these are many-to-many).

=over 4

=item B<to_UTDATE>

Converts the DATE-OBS keyword into a C<Time::Piece> object corresponding
to the date of observation (without the time).

There is no corresponding C<from_UTDATE> method since there is
no corresponding FITS keyword.

=cut

sub to_UTDATE {
  my $class = shift;
  my $FITS_headers = shift;
  my $utstart = $class->to_UTSTART( $FITS_headers );
  if (defined $utstart) {
    return $utstart->strftime( '%Y%m%d' );
  }
  return;
}


=item B<to_UTEND>

Converts UT date in C<DATE-END> header into C<Time::Piece> object.

=cut

sub to_UTEND {
  my $class = shift;
  my $FITS_headers = shift;
  my $return;
  if(exists($FITS_headers->{'DATE-END'})) {
    $return = $class->_parse_iso_date( $FITS_headers->{'DATE-END'});
  }
  return $return;
}

=item B<from_UTEND>

Returns the ending observation time in FITS restricted ISO8601 format:
YYYY-MM-DDThh:mm:ss.

=cut

sub from_UTEND {
  my $class = shift;
  my $generic_headers = shift;
  my %return_hash;
  if(exists($generic_headers->{UTEND})) {
    my $date = $generic_headers->{UTEND};
    $return_hash{'DATE-END'} = $date->datetime;
  }
  return %return_hash;
}


=item B<to_UTSTART>

Converts UT date in C<DATE-OBS> header into date object.

=cut

sub to_UTSTART {
  my $class = shift;
  my $FITS_headers = shift;
  my $return;
  if(exists($FITS_headers->{'DATE-OBS'})) {
    $return = $class->_parse_iso_date( $FITS_headers->{'DATE-OBS'});
  }
  return $return;
}

=item B<from_UTSTART>

Returns the starting observation time in FITS restricted ISO8601
format: YYYY-MM-DDThh:mm:ss.

=cut

sub from_UTSTART {
  my $class = shift;
  my $generic_headers = shift;
  my %return_hash;
  if(exists($generic_headers->{UTSTART})) {
    my $date = $generic_headers->{UTSTART};
    $return_hash{'DATE-OBS'} = $date->datetime;
  }
  return %return_hash;
}

=back

=head1 REVISION

 $Id$

=head1 SEE ALSO

C<Astro::FITS::HdrTrans>, C<Astro::FITS::HdrTrans::Base>.

=head1 AUTHOR

Brad Cavanagh E<lt>b.cavanagh@jach.hawaii.eduE<gt>,
Tim Jenness E<lt>t.jenness@jach.hawaii.eduE<gt>.

=head1 COPYRIGHT

Copyright (C) 2007-2008 Science and Technology Facilities Council.
Copyright (C) 2003-2007 Particle Physics and Astronomy Research Council.
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
