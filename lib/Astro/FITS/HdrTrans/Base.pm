# -*-perl-*-

package Astro::FITS::HdrTrans::Base;

=head1 NAME

Astro::FITS::HdrTrans::Base - Base class for header translation

=head1 SYNOPSIS

  use base qw/ Astro::FITS::HdrTrans::Base /;

  %generic = Astro::FITS::HdrTrans::Base->translate_from_FITS( \%fits );
  %fits = Astro::FITS::HdrTrans::Base->translate_to_FITS( \%gen );

=head1 DESCRIPTION

This is the header translation base class. Not to be confused with
C<Astro::FITS::HdrTrans> itself, which is a high level abstraction
class. In general users should use C<Astro::FITS::HdrTrans>
for initiating header translations unless they know what they are
doing. Also C<Astro::FITS::HdrTrans> is the only public interface
to the header translation.

=cut

use 5.006;
use strict;
use warnings;
use Carp;

use vars qw/ $VERSION /;
use Astro::FITS::HdrTrans (); # for the generic header list

$VERSION = sprintf("%d.%03d", q$Revision$ =~ /(\d+)\.(\d+)/);

=head1 PUBLIC METHODS

All methods in this class are CLASS METHODS. No state is retained
outside of the hash argument.

=over 4

=item B<translate_from_FITS>

Do the header translation from FITS for the specified class.

  %generic = $class->translate_to_FITS( \%fitshdr, $prefix );

Prefix is attached to the keys in the returned hash if it
is defined.

=cut

sub translate_from_FITS {
  my $class = shift;
  my $FITS = shift;
  my $prefix = shift || '';

  croak "translate_to_FITS: Not a hash reference!"
    unless (ref($FITS) && ref($FITS) eq 'HASH');

  # Now we need to loop over the known generic headers
  # which we obtain from Astro::FITS::HdrTrans
  my @GEN = Astro::FITS::HdrTrans->generic_headers;

  my %generic;
  for my $g (@GEN) {
    my $method = "to_$g";
    if ($class->can( $method )) {
      $generic{"$prefix$g"} = $class->$method( $FITS );
    }

  }

  return %generic;
}

=item B<translate_to_FITS>

Do the header translation from generic headers to FITS
for the specified class.

  %fits = $class->translate_to_FITS( \%generic );

=cut

sub translate_to_FITS {
  my $class = shift;
  my $generic = shift;

  croak "translate_to_FITS: Not a hash reference!"
    unless (ref($generic) && ref($generic) eq 'HASH');

  # Now we need to loop over the known generic headers
  # which we obtain from Astro::FITS::HdrTrans
  my @GEN = Astro::FITS::HdrTrans->generic_headers;

  my %FITS;
  for my $g (@GEN) {
    my $method = "from_$g";
    if ($class->can( $method )) {
      %FITS = (%FITS,$class->$method( $generic ));
    }

  }

  return %FITS;
}

=back

=head1 PROTECTED METHODS

These methods are available to translation subclasses and should
not be used by external classes.

=over 4

=item B<can_translate>

Returns true if the supplied headers can be handled by this class.

  $cando = $class->can_translate( \%hdrs );

The base class version of this method returns true if either the C<INSTRUME>
or C<INSTRUMENT> key exist and match the value returned by the
C<ref_instrument> method. Comparisons are case-insensitive.

=cut

sub can_translate {
  my $class = shift;
  my $headers = shift;

  # get the reference instrument string
  my $ref = $class->this_instrument();
  return 0 unless defined $ref;
  $ref = lc($ref);

  #print "Checking against $ref\n";

  # check against the FITS and Generic versions.
  if( exists( $headers->{'INSTRUME'} ) &&
      defined( $headers->{'INSTRUME'} ) ) {
    my $h = lc($headers->{INSTRUME});
    return 1 if $h eq $ref;
  } elsif( exists( $headers->{'INSTRUMENT'} ) &&
           defined( $headers->{'INSTRUMENT'} ) ) {
    my $h = lc($headers->{INSTRUMENT});
    return 1 if $h eq $ref;
  } else {
    return 0;
  }
  return 0;
}

=item B<this_instrument>

Name of the instrument that can be translated by this class.
Defaults to an empty string. The method must be subclassed.

 $inst = $class->this_instrument();

=cut

sub this_instrument {
  return "";
}

=item B<valid_class>

Historically this method was used to determine whether this class can
handle the supplied FITS headers.  The headers can be either in
generic form or in FITS form.

  $isvalid = $class->valid_class( \%fits );

The base class always returns false. This is a backwards compatibility
method to prevent mixing of translation modules from earlier release
of C<Astro::FITS::HdrTrans> with the current object-oriented version.
See the C<can_translate> method for the new interface.

=cut

sub valid_class {
  return 0;
}

=item B<_generate_lookup_methods>

We generate the unit and constant mapping methods automatically from a
lookup table.

  Astro::FITS::HdrTrans::UKIRT->_generate_lookup_methods( \%const, \%unit);

This method generates all the simple internal methods. Expects two arguments,
both references to hashes. The first is a reference to a hash with
constant mapping from FITS to generic (and no reverse mapping), the
second is a reference to a hash with unit mappings (both from and to
methods are created). The methods are placed into the package given
by the class supplied to the method.

Additionally, an optional third argument can be used to indicate
methods that should be null translations. This is a reference to an array
of generic keywords and should be used in the rare cases when a base
class implementation should be nullified. This will result in undefined
values in the generic hash but no value in the generic to FITS mapping.

These methods will have the standard interface of

  $generic = $class->_to_GENERIC_NAME( \%fits );
  %fits = $class->_from_GENERIC_NAME( \%generic );

=cut

sub _generate_lookup_methods {
  my $class = shift;
  my $const = shift;
  my $unit  = shift;
  my $null  = shift;

 # Have to go into a different package
  my $p = "{\n package $class;\n";
  my $ep = "\n}"; # close the scope

  # Loop over the keys to the unit mapping hash
  # The keys are the GENERIC name
  for my $key (keys %$unit) {

    # Get the original FITS header name
    my $fhdr = $unit->{$key};

    # print "Processing $key and $ohdr and $fhdr\n";

    # First generate the code to generate Generic headers
    my $subname = "to_$key";
    my $sub = qq/ $p sub $subname { \$_[1]->{\"$fhdr\"}; } $ep /;
    eval "$sub";
    #print "Sub: $sub\n";

    # Now the from
    $subname = "from_$key";
    $sub = qq/ $p sub $subname { (\"$fhdr\", \$_[1]->{\"$key\"}); } $ep/;
    eval "$sub";
    #print "Sub: $sub\n";

  }

  # and the CONSTANT mappings (only to_GENERIC_NAME)
  for my $key (keys %$const) {
    my $subname = "to_$key";
    my $val = $const->{$key};
    # A method so no gain in using a null prototype
    my $sub = qq/ $p sub $subname { \"$val\" } $ep /;
    eval "$sub";
  }

  # finally the null mappings
  if (defined $null) {
    for my $key (@$null) {
      # to generic
      my $subname = "to_$key";
      my $sub = qq/ $p sub $subname { } $ep /;
      eval "$sub";

      # to generic
      $subname = "from_$key";
      $sub = qq/ $p sub $subname { return (); } $ep /;
      eval "$sub";
    }
  }

}

=back

=head1 PROTECTED IMPORTS

Not all translation methods warrant a full blown inheritance.  For
cases where 1 or 2 translation routines should be imported
(e.g. reading DATE-OBS FITS standard headers without importing the
additoinal FITS methods) a special import routine can be used when
using the class.

  use Astro::FITS::Header::FITS qw/ ROTATION /;

This will load the from_ROTATION and to_ROTATION methods into
the namespace.

=cut

sub import {
  my $class = shift;

  # this is where we are going to install the methods
  my $callpkg = caller();

  # Prepend the from_ and to_ prefixes
  for my $key (@_) {
    for my $dir (qw/ from_ to_ /) {
      my $method = $dir . $key;
      #print "Importing method $method\n";
      no strict 'refs';

      if (!defined *{"$class\::$method"}) {
	croak "Method $method is not available for export from class $class";
      }

      # assign it
      *{"$callpkg\::$method"} = \&{"$class\::$method"};
    }
  }

}

=head1 REVISION

 $Id$

=head1 SEE ALSO

C<Astro::FITS::HdrTrans>

=head1 AUTHOR

Tim Jenness E<lt>t.jenness@jach.hawaii.eduE<gt>

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
