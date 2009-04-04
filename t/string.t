#!/usr/bin/perl -w

# Load file into a string into memory and then test it

use strict;
use Test::More;
use File::Spec;

my (@tests, $tests);

BEGIN
   {
   @tests = glob("img/test*");
   $tests = (scalar @tests) * 2;
   plan tests => $tests;
   chdir 't' if -d 't';
   use lib '../lib';
   };

my $requires = 
  {
  xpm => 'Image::XPM',
  xbm => 'Image::XBM',
  svg => 'XML::Simple',
  };

SKIP:
  {
  skip( 'Need either Perl 5.008 or greater, or IO::String for these tests', $tests )
    unless $] >= 5.008 || do
      {
      eval "use IO::String;";
      $@ ? 0 : 1;
      };

  use Image::Info qw(image_info);

  my $updir = File::Spec->updir();

  for my $f (@tests)
    {
    # extract the extension of the image file
    $f =~ /\.([a-z]+)\z/i; my $x = lc($1 || '');

    SKIP:
      {
      # test for loading the nec. library
      if (exists $requires->{$x})
        {
        my $r = $requires->{$x};
        print STDERR "# $x requires $r\n";
        skip( "Need $r for this test", 2 ) && next
          unless do {
            eval "use $r;";
            $@ ? 0 : 1;
          };
        }

      # 2 tests follow:

      my $file = File::Spec->catfile($updir,$f);
      my $h1 = image_info($file);

      is ($h1->{error}, undef, 'no error');

      my $img = cat($file);
      my $h2 = image_info(\$img);

      is_deeply ($h1, $h2, $file);
      } # end inner SKIP
    } # end for each file
  } # end SKIP all block

sub cat {
    my $file = shift;
    local(*F, $/);
    open(F, $file) || die "Can't open $file: $!";
    binmode F;
    my $c = <F>;
    close(F);
    $c;
}
