#!/usr/bin/perl

use strict;
use Data::Dumper;
use Imager;
use Imager::Font::Wrap;

my $image = Imager->new();
$image->read(file => 'the-most-interesting-man-in-the-world.jpg');

my $font_size = get_font_size(
    get_text(),
    $image->getwidth,
    ($image->getheight / 5)
);

render_text('bottom',$image,get_font(),get_text(),$font_size);

$image->write(file=>'output.png')
    or die 'Cannot save output.png: ', $image->errstr;

sub get_font {
    return Imager::Font->new(file=>'impact.ttf')
        or die "Cannot load impact.ttf: ", Imager->errstr;
}

sub get_text {

my $text = <<EOSTR;
if you try to participate
EOSTR

    return uc($text);
}

sub get_font_size {

    my ($text,$width,$height) = @_;

    my $adjusted_height = ($height / 5);
    my $text_size = 50;
    my $font = get_font();

    while (1) {

        my (undef,undef,$b_width,$b_height) = Imager::Font::Wrap->wrap_text(
            image  => undef,
            font   => $font,
            string => $text,
            size => $text_size,
            color => 'white',
            justify => 'center',
            width => $width,
            height => $adjusted_height
        );

        if ($b_height > $adjusted_height) {

            $text_size = $text_size - 1;

        } else {

            return $text_size;

        }

    }

}

sub get_text_start_pos {

    my ($type,$width,$height) = @_;

    if ($type eq 'bottom') {
        my $y_pos = ($height - ($height / 5) );
        return(0,$y_pos);
    }

    return (0,0);
}

sub render_text {

    my ($type,$image,$font,$text,$text_size) = @_;

    my ($x,$y) = get_text_start_pos($type,$image->getwidth,$image->getheight);

    my $pos = [
        [($x - 1),($y - 1)],
        [($x - 2),($y - 1)],
        [($x + 1),($y - 1)],
        [($x + 2),($y - 1)],
        [($x - 1),($y - 1)],
        [($x - 1),($y + 2)],
        [($x + 1),($y + 1)],
    ];

    my $options = {
        image  => $image,
        height => ($image->getheight/5),
        font   => $font,
        string => $text,
        size => $text_size,
        justify => 'center'
    };

    # used to add a border to the text
    #
    for (my $i = 0; $i < @$pos; $i++) {

        $options->{'x'} = $pos->[$i][0];
        $options->{'y'} = $pos->[$i][1];
        $options->{'color'} = 'black';

        Imager::Font::Wrap->wrap_text(%$options)
            or die "wrap_text died", $image->errstr;

    }

    # the final wrap_text draws the white text ontop of
    # the black text
    #
    $options->{'color'} = 'white';

    Imager::Font::Wrap->wrap_text(%$options)
        or die "wrap_text died", $image->errstr;

}

