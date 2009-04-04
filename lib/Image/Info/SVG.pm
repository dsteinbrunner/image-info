package Image::Info::SVG;

$VERSION = '1.02';

use strict;
no strict 'refs';
use XML::Simple;

sub process_file {
    my($info, $source) = @_;
    my(@comments, @warnings, %info, $comment, $img, $imgdata, $xs);
    local($_);

    while(<$source>){
	if( ! exists($info{standalone}) && /standalone="(.+?)"/ ){
	    $info{standalone} = $1;
	}
	if( /<!--/ .. /-->/ ){
	    $comment .= $_;
	}
	if( /-->/ ){
	    $comment =~ s/<!--//;
	    $comment =~ s/-->//;
	    chomp($comment);
	    push @comments, $comment;
	    $comment = '';
	}
	$imgdata .= $_;
    }
    if( $imgdata =~ /<!DOCTYPE\s+svg\s+.+?\s+"(.+?)">/ ){
	$info{dtd} = $1;
    }
    elsif( $imgdata !~ /<svg/ ){
	return $info->push_info(0, "error", "Not a valid SVG image");
    }

    local $SIG{__WARN__} = sub {
	push(@warnings, @_);
    };

    $xs = XML::Simple->new;
    $img = $xs->XMLin($imgdata);

    $info->push_info(0, "color_type" => "sRGB");
    $info->push_info(0, "file_ext" => "svg");
    # XXX not official type yet, may be image/svg+xml
    $info->push_info(0, "file_media_type" => "image/svg-xml");
    $info->push_info(0, "height", $img->{height});
#    $info->push_info(0, "resolution", "1/1");
    $info->push_info(0, "width", $img->{width});
#    $info->push_info(0, "BitsPerSample", 8);
    #$info->push_info(0, "SamplesPerPixel", -1);

    # XXX Description, title etc. could be tucked away in a <g> :-(
    $info->push_info(0, "ImageDescription", $img->{desc}) if $img->{desc};
    if( $img->{image} ){
	if( ref($img->{image}) eq 'ARRAY' ){
	    foreach my $img (@{$img->{image}}){
		$info->push_info(0, "SVG_Image", $img->{'xlink:href'});
	    }
	}
	else{
	    $info->push_info(0, "SVG_Image", $img->{image}->{'xlink:href'});
	}
    }
    $info->push_info(0, "SVG_StandAlone", $info{standalone});
    $info->push_info(0, "SVG_Title", $img->{title}) if $img->{title};
    $info->push_info(0, "SVG_Version", $info{dtd}||'unknown');

    for (@comments) {
	$info->push_info(0, "Comment", $_);
    }
    
    for (@warnings) {
	$info->push_info(0, "Warn", $_);
    }
}
1;
__END__

=pod

=head1 NAME

Image::Info::SVG - SVG support for Image::Info

=head1 SYNOPSIS

 use Image::Info qw(image_info dim);

 my $info = image_info("image.svg");
 if (my $error = $info->{error}) {
     die "Can't parse image info: $error\n";
 }
 my $color = $info->{color_type};

 my($w, $h) = dim($info);

=head1 DESCRIPTION

A functional yet thus far rudimentary SVG implementation.
SVG also provides (for) a plethora of attributes and metadata of an image.

This modules supplies the standard key names except for
BitsPerSample, Compression, Gamma, Interlace, LastModificationTime, as well as:

=over

=item ImageDescription

The image description, corresponds to <desc>.

=item SVG_Image

A scalar or reference to an array of scalars containing the URI's of
embedded images (JPG or PNG) that are embedded in the image.

=item SVG_StandAlone

Whether or not the image is standalone.

=item SVG_Title

The image title, corresponds to <title>

=item SVG_Version

The URI of the DTD the image conforms to.

=back

=head1 FILES

This module requires L<XML::Simple>

=head1 SEE ALSO

L<Image::Info>, L<XML::Simple>, L<expat>

=head1 NOTES

For more information about SVG see:

 http://www.w3.org/Graphics/SVG/

Random notes:

  Colors
    # iterate over polygon,rect,circle,ellipse,line,polyline,text for style->stroke: style->fill:?
    #  and iterate over each of these within <g> too?! and recurse?!
    # append <color>'s
    # perhaps even deep recursion through <svg>'s?
  ColorProfile <color-profile>
  RenderingIntent ?
  requiredFeatures
  requiredExtensions
  systemLanguage

=head1 AUTHOR

Jerrad Pierce <belg4mit@mit.edu>/<webmaster@pthbb.org>

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=begin register

MAGIC: /^<\?xml/

SVG also provides (for) a plethora of attributes and metadata of an image.
See L<Image::Info::SVG> for details.

=end register

=cut