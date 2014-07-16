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

use base qw/ Astro::FITS::HdrTrans::JCMT /;

use vars qw/ $VERSION /;

$VERSION = "1.56";

# For a constant mapping, there is no FITS header, just a generic
# header that is constant.
my %CONST_MAP = (
                 BACKEND    => 'SCUBA-2',
                 DATA_UNITS => 'pW',
                );

# NULL mappings used to override base class implementations
my @NULL_MAP = ();

# Unit mapping implies that the value propogates directly
# to the output with only a keyword name change.

my %UNIT_MAP = (
                FILTER               => "FILTER",
                INSTRUMENT           => "INSTRUME",
                DR_GROUP             => "DRGROUP",
                OBSERVATION_TYPE     => "OBS_TYPE",
                POLARIMETER          => 'POL_CONN',
                UTDATE               => "UTDATE",
                TELESCOPE            => "TELESCOP",
                AMBIENT_TEMPERATURE  => 'ATSTART',
               );

# Values that are derived from the last subheader entry
my %ENDOBS_MAP = (
                  AIRMASS_END         => 'AMEND',
                  AZIMUTH_END         => 'AZEND',
                  ELEVATION_END       => 'ELEND',
                 );

# Create the translation methods
__PACKAGE__->_generate_lookup_methods( \%CONST_MAP, \%UNIT_MAP, \@NULL_MAP, \%ENDOBS_MAP );

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

=head1 COMPLEX CONVERSIONS

These methods are more complicated than a simple mapping. We have to
provide both from- and to-FITS conversions All these routines are
methods and the to_ routines all take a reference to a hash and return
the translated value (a many-to-one mapping) The from_ methods take a
reference to a generic hash and return a translated hash (sometimes
these are many-to-many)

=over 4

=item B<to_OBSERVATION_MODE>

If Observation type is SCIENCE, return the sample mode, else
return the sample mode and observation type. For example, "STARE",
"SCAN", "SCAN_POINTING".

Do not currently take into account polarimeter or FTS.

=cut

sub to_OBSERVATION_MODE {
  my $self = shift;
  my $FITS_headers = shift;

  my $return;
  if ( exists( $FITS_headers->{'SAM_MODE'} ) &&
       exists( $FITS_headers->{'OBS_TYPE'} ) ) {
    my $sam_mode = $FITS_headers->{'SAM_MODE'};
    $sam_mode =~ s/\s//g;
    my $obs_type = $FITS_headers->{'OBS_TYPE'};
    $obs_type =~ s/\s//g;

    $return = $sam_mode;
    if ($obs_type !~ /science/i) {
      if ($obs_type =~ /(setup)/i) {
        $return = lc($1);
      } else {
        $return .= "_$obs_type";
      }
    }
  }
  return $return;
}

=item B<to_SUBSYSTEM_IDKEY>

=cut

sub to_SUBSYSTEM_IDKEY {
  my $self = shift;
  my $FITS_headers = shift;

  # Try the general headers first
  my $general = $self->SUPER::to_SUBSYSTEM_IDKEY( $FITS_headers );
  return ( defined $general ? $general : "FILTER" );
}

=item B<to_DR_RECIPE>

Fix up recipes that were incorrect in the early years of the
observing tool.

Converts SASSy survey data to use the SASSy recipe.

=cut

sub to_DR_RECIPE {
  my $class = shift;
  my $FITS_headers = shift;
  my $dr = $FITS_headers->{RECIPE};
  my $survey = $FITS_headers->{SURVEY};

  if (defined $survey && $survey =~ /sassy/i) {
    if ($dr !~ /sassy/i) {
      $dr = "REDUCE_SASSY";
    }
  }
  return $dr;
}

=back

=head1 SEE ALSO

C<Astro::FITS::HdrTrans>, C<Astro::FITS::HdrTrans::Base>

=head1 AUTHOR

Tim Jenness E<lt>t.jenness@jach.hawaii.eduE<gt>

=head1 COPYRIGHT

Copyright (C) 2007-2009,2011,2013 Science & Technology Facilities Council.
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
