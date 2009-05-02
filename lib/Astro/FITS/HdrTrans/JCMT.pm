package Astro::FITS::HdrTrans::JCMT;

use strict;
use warnings;

use Astro::FITS::HdrTrans::JAC;

BEGIN {

  our $JAC = 'Astro::FITS::HdrTrans::JAC';
}
our $JAC;

sub to_UTDATE {
  my $class = shift;
  my $FITS_headers = shift;

  $JAC->_fix_dates( $FITS_headers );
  return $class->SUPER::to_UTDATE( $FITS_headers, @_ );
}

sub to_UTEND {
  my $class = shift;
  my $FITS_headers = shift;

  $JAC->_fix_dates( $FITS_headers );
  return $class->SUPER::to_UTEND( $FITS_headers, @_ );
}

sub to_UTSTART {
  my $class = shift;
  my $FITS_headers = shift;

  $JAC->_fix_dates( $FITS_headers );
  return $class->SUPER::to_UTSTART( $FITS_headers, @_ );
}


1;

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

