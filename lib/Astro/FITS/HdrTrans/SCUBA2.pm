package Astro::FITS::HdrTrans::SCUBA2;

=head1 NAME

Astro::FITS::HdrTrans::SCUBA2 - JCMT SCUBA-2 translations

=head1 DESCRIPTION

Converts information contained in SCUBA-2 FITS headers to and from
generic headers. See L<Astro::FITS::HdrTrans> for a list of generic
headers.

=cut

use 5.006;
use warnings;
use strict;
use Carp;

# Inherit from generic JAC class.
use base qw/ Astro::FITS::HdrTrans::JAC /;

use vars qw/ $VERSION /;

$VERSION = sprintf("%d", q$Revision$ =~ /(\d+)/);

# For a constant mapping, there is no FITS header, just a generic
# header that is constant.
my %CONST_MAP = (
                );

# NULL mappings used to override base class implementations
my @NULL_MAP = ();

# Unit mapping implies that the value propogates directly
# to the output with only a keyword name change.

my %UNIT_MAP = (
                 AIRMASS_START        => "AMSTART",
                 AIRMASS_END          => "AMEND",
                 AZIMUTH_START        => 'AZSTART',
                 AZIMUTH_END          => 'AZEND',
                 INSTRUMENT           => "INSTRUME",
                 DR_GROUP             => "DRGROUP",
                 DR_RECIPE            => "RECIPE",
                 ELEVATION_START      => 'ELSTART',
                 ELEVATION_END        => 'ELEND',
                 FILENAME             => "FILE_ID",
                 HUMIDITY             => "HUMSTART",
                 LATITUDE             => 'LAT-OBS',
                 LONGITUDE            => 'LONG-OBS',
                 OBJECT               => "OBJECT",
                 OBSERVATION_MODE     => "OBSMODE",
                 OBSERVATION_NUMBER   => "OBSNUM",
                 OBSERVATION_TYPE     => "OBSTYPE",
                 POLARIMETER          => 'POL_CONN',
                 PROJECT              => 'PROJECT',
                 UTDATE               => "UTDATE",
                 STANDARD             => "STANDARD",
                 TAU                  => "WVMTAUST",
                 TELESCOPE            => "TELESCOP",
                 X_APERTURE           => "INSTAP_X",
                 Y_APERTURE           => "INSTAP_Y",
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

Returns "SCUBA-2".

=cut

sub this_instrument {
  return "SCUBA-2";
}

=back

=head1 REVISION

 $Id$

=head1 SEE ALSO

C<Astro::FITS::HdrTrans>, C<Astro::FITS::HdrTrans::Base>

=head1 AUTHOR

Tim Jenness E<lt>t.jenness@jach.hawaii.eduE<gt>

=head1 COPYRIGHT

Copyright (C) 2003-2005 Particle Physics and Astronomy Research Council.
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
