#!/usr/bin/perl

use strict;
use Data::Dumper;
use Imager;
use Imager::Font::Wrap;

sub get_image_parameters {
}

my $image = Imager->new();
$image->read(file => 'the-most-interesting-man-in-the-world.jpg');

my ($font_size,$font_height) = get_font_size(
    get_top_text(),
    $image->getwidth,
    ($image->getheight / 5)
);

render_text('top',$image,get_font(),get_top_text(),$font_size,$font_height);

my ($font_size,$font_height) = get_font_size(
    get_bottom_text(),
    $image->getwidth,
    ($image->getheight / 5)
);
render_text('bottom',$image,get_font(),get_bottom_text(),$font_size,$font_height);

$image->write(file=>'output.png')
    or die 'Cannot save output.png: ', $image->errstr;

sub get_font {
    return Imager::Font->new(file=>'impact.ttf')
        or die "Cannot load impact.ttf: ", Imager->errstr;
}

sub get_top_text {

my $text = <<EOSTR;
I don't always make memes
EOSTR

    return uc($text);
}

sub get_bottom_text {

my $text = <<EOSTR;
but when i do i make my own generator to do it
EOSTR

    return uc($text);
}

sub get_font_size {

    my ($text,$width,$height) = @_;

    my $text_size = 50;
    my $font = get_font();

    while (1) {

        my $savepos;

        my (undef,undef,$w,$h) = Imager::Font::Wrap->wrap_text(
            image  => undef,
            font   => $font,
            string => $text,
            size => $text_size,
            color => 'white',
            justify => 'center',
            width => $width,
            height => $height,
            savepos => \$savepos
        );

        printf("save pos: %d\n", $savepos);

        if ($savepos < length($text)) {

            $text_size = $text_size - 1;

        } else {

            return ($text_size,$h);

        }

    }

}

sub get_text_start_pos {

    my ($type,$width,$height,$text_height) = @_;

    if ($type eq 'bottom') {
        my $y_pos = ($height - $text_height) - 10;
        return(0,$y_pos);
    }

    return (15,0);
}

sub render_text {

    my ($type,$image,$font,$text,$text_size,$text_height) = @_;

    my ($x,$y) = get_text_start_pos(
        $type,$image->getwidth,$image->getheight,$text_height
    );

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

