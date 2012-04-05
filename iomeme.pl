#!/usr/bin/perl

use strict;
use warnings;

use GD;
use GD::Text::Wrap;
use Data::Dumper;

my $top_text = <<EOSTR;
if you try to participate
EOSTR

my $bottom_text = <<EOSTR;
You're going to have a bad time You're going to have a bad time
You're going to have a bad time You're going to have a bad time
You're going to have a bad time You're going to have a bad time
You're going to have a bad time You're going to have a bad time
You're going to have a bad time You're going to have a bad time
You're going to have a bad time You're going to have a bad time
EOSTR

my $image_filename = 'the-most-interesting-man-in-the-world.jpg';
my $image_background = GD::Image->new($image_filename);
my ($width,$height) = $image_background->getBounds();

my $top = render_text('top',uc($top_text),$width,($height/5));
my $bottom = render_text('bottom',uc($bottom_text),$width,($height/5));

my $bottom_position = (($height - 15) - $bottom->height);

print "height is: " . $height . "\n";
print "bottom height is: " . $bottom->height . "\n";
print "bottom position: " . $bottom_position . "\n";


$image_background->copy($top,0,15,0,0,$width,$height);
$image_background->copy($bottom,0,$bottom_position,0,0,$width,$height);

#Only here to test the test.
open(GD, '>output.png') or die $!;
binmode GD;
print GD $image_background->png();
close GD;

sub render_text {
    my ($type,$text,$width,$height) = @_;

    my $text_size = 50;

    while (1) {

        my $gd = GD::Image->new($width,$height);

        # Allocate colours
        my $offwhite = $gd->colorAllocate(250,255,255);
        my $white = $gd->colorAllocate(255,255,255);
        my $black = $gd->colorAllocate(0,0,0);

        $gd->transparent($offwhite);
        $gd->interlaced('true');

        my $drawn_text = GD::Text::Wrap->new($gd,
            color => $black,
            text => $text,
            align => 'center',
            font => 'impact.ttf',
            ptsize => $text_size
        );

        my ($x,$y) = (0,0);
        # draw the text border
        #
        $drawn_text->set('color',$black);
        $drawn_text->draw($x - 1,$y - 1);
        $drawn_text->draw($x + 1,$y - 1);
        $drawn_text->draw($x - 1,$y + 1);
        $drawn_text->draw($x + 1,$y + 1);

        # draw the text overlay
        #
        $drawn_text->set('color',$white);
        $drawn_text->draw($x,$y);

        my ($b_x,$b_y,$b_width,$b_height) = $drawn_text->get_bounds(0,0);

        printf("type: %s image height: %d bounds height: %d font size: %d\n",
            $type,$height,$b_height,$text_size);

        if ($height > $b_height) {
            # trim the white space by resizing after the text has been applied
            #
            $gd->copy($gd,0,0,0,0,$width,$b_height);
            return $gd;
        }

        $text_size = $text_size - 1;

    }

}
