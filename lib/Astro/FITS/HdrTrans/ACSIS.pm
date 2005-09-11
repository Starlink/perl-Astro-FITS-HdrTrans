# -*-perl-*-

package Astro::FITS::HdrTrans::ACSIS;

=head1 NAME

Astro::FITS::HdrTrans::ACSIS - class for translation of JCMT ACSIS headers

=head1 SYNOPSIS

  use Astro::FITS::HdrTrans::UKIRT;

=head1 DESCRIPTION

This class provides a generic set of translations that are common to
instrumentation from the United Kingdom Infrared Telescope. It should
not be used directly for translation of instrument FITS headers.

=cut

use 5.006;
use warnings;
use strict;
use Carp;

# inherit from the Base translation class and not HdrTrans
# itself (which is just a class-less wrapper)
use base qw/ Astro::FITS::HdrTrans::Base /;

# Use the FITS standard DATE-OBS handling
use Astro::FITS::HdrTrans::FITS;

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
		CHOP_ANGLE         => 'CHOP_PA',
		CHOP_THROW         => 'CHOP_THR',
		DR_RECIPE          => 'DRRECIPE',
		INST_DHS           => 'DHS',
		MSBID              => 'MSBID',
		OBJECT             => 'OBJECT',
		OBSERVATION_NUMBER => 'OBSNUM',
		POLARIMETER        => 'POL_CONN',
		PROJECT            => 'PROJECT',
		SEEING             => 'SEEINGST',
		STANDARD           => 'STANDARD',
		SWITCH_MODE        => 'SW_MODE',
		TAU                => 'WVMTAUST',
               );

# Create the translation methods
__PACKAGE__->_generate_lookup_methods( \%CONST_MAP, \%UNIT_MAP );

=head1 METHODS

=over 4

=item B<can_translate>

Returns true if the supplied headers can be handled by this class.

  $cando = $class->can_translate( \%hdrs );

For this class, the method will return true if the B<DHS> header exists
and matches 'ACSIS'.

=cut

sub can_translate {
  my $self = shift;
  my $headers = shift;

  if ( exists $headers->{DHS} &&
       defined $headers->{DHS} &&
       $headers->{DHS} =~ /^ACSIS/i
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

=item _to_SEEING


=back

=head1 REVISION

 $Id$

=head1 SEE ALSO

C<Astro::FITS::HdrTrans>, C<Astro::FITS::HdrTrans::Base>

=head1 AUTHOR

Tim Jenness E<lt>t.jenness@jach.hawaii.eduE<gt>.

=head1 COPYRIGHT

Copyright (C) 2005 Particle Physics and Astronomy Research Council.
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
