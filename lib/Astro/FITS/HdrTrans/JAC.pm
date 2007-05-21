# -*-perl-*-

package Astro::FITS::HdrTrans::JAC;

=head1 NAME

Astro::FITS::HdrTrans::JAC - Base calss for translation of Joint
Astronomy Centre instruments.

=head1 SYNOPSIS

  use Astro::FITS::HdrTrans::JAC;

=head1 DESCRIPTION

This class provides a generic set of translations that are common to
instrumentation from the Joint Astronomy Centre. It should not be used
directly for translation of instrument FITS headers.

=cut

use 5.006;
use warnings;
use strict;
use Carp;

# Inherit from the Base translation class and not HdrTrans itself
# (which is just a class-less wrapper).

use base qw/ Astro::FITS::HdrTrans::FITS /;

use Astro::FITS::HdrTrans::FITS;

use vars qw/ $VERSION /;

$VERSION = sprintf("%d", q$Revision$ =~ /(\d+)/);

# in each class we have three sets of data.
#   - constant mappings
#   - unit mappings
#   - complex mappings

# for a constant mapping, there is no FITS header, just a generic
# header that is constant
my %CONST_MAP = (
                );

# unit mapping implies that the value propogates directly
# to the output with only a keyword name change

my %UNIT_MAP = (
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

=item B<to_OBSERVATION_ID>

Converts the C<OBSID> header directly into the C<OBSERVATION_ID>
generic header, or if that header does not exist, converts the
C<INSTRUME>, C<RUNNR>, and C<DATE-OBS> headers into C<OBSERVATION_ID>.

=cut

sub to_OBSERVATION_ID {
  my $self = shift;
  my $FITS_headers = shift;

  my $return;
  if( exists( $FITS_headers->{'OBSID'} ) &&
      defined( $FITS_headers->{'OBSID'} ) ) {
    $return = $FITS_headers->{'OBSID'};
  } else {

    my $instrume = lc( $self->to_INSTRUMENT( $FITS_headers ) );
    my $obsnum = $self->to_OBSERVATION_NUMBER( $FITS_headers );
    my $dateobs = $self->to_UTSTART( $FITS_headers );

    my $datetime = $dateobs->datetime;
    $datetime =~ s/-//g;
    $datetime =~ s/://g;

    $return = join '_', $instrume, $obsnum, $datetime;
  }

  return $return;

}

=back

=head1 REVISION

$Id$

=head1 SEE ALSO

C<Astro::FITS::HdrTrans>, C<Astro::FITS::HdrTrans::Base>.

=head1 AUTHOR

Brad Cavanagh E<lt>b.cavanagh@jach.hawaii.eduE<gt>.

=head1 COPYRIGHT

Copyright (C) 2006 Particle Physics and Astronomy Research Council.
All Rights Reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or (at
your option) any later version.

This program is distributed in the hope that it will be useful,but
WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place,Suite 330, Boston, MA 02111-1307,
USA

=cut

1;
