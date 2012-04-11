package iomeme;

use Moose;
use Imager;
use Imager::Font::Wrap;

use constant TOP => 'TOP';
use constant BOTTOM => 'BOTTOM';

has 'meme' => ( isa => 'Str', is => 'rw', required => 1);

has 'image' => ( isa => 'Imager', is => 'rw');

has 'top' => ( isa => 'Str', is => 'rw',);

has 'bottom' => ( isa => 'Str', is => 'rw');

has 'font' => (
    isa => 'Imager::Font',
    is => 'ro',
    builder => '_build_font'
);

has 'format' => (isa => 'Str', is => 'rw');

sub BUILD {
    my $self = shift;

    my $memes = $self->get_memes();
    my $meme = $memes->{$self->meme};
    my $image = Imager->new();

    $image->read(file => $meme->{template})
        or die 'failed to read template: ', $image->errstr;

    $self->image($image);

    # set the image format
    #
    $self->format($self->image->tags( name => 'i_format' ));
}

sub insert_string {
    my ($self,$type,$string) = @_;

    my $strprm = $self->get_string_parameters($type,$string);

    $self->insert_string_border($type,$string,$strprm);
    $self->insert_string_overlay($type,$string,$strprm);
}

sub insert_string_border {

    my ($self,$type,$string,$strprm) = @_;

    my $font = $self->font;
    my $image = $self->image;

    my $x = $strprm->{x};
    my $y = $strprm->{y};
    my $font_size = $strprm->{font_size};
    my $string_height = $strprm->{string_height};

    my $pos = [];
    my $thickness = 3;

    for (my $i = 0; $i < $thickness; $i++) {
        my ($xos,$yos) = undef;

        # left up
        $xos = $x - $i;
        $yos = $y - $i;
        push(@$pos,[($xos),($yos)]);

        # left down
        $xos = $x - $i;
        $yos = $y + $i;
        push(@$pos,[($xos),($yos)]);

        # left
        $xos = $x - $i;
        $yos = $y;
        push(@$pos,[($xos),($yos)]);

        # right
        $xos = $x + $i;
        $yos = $y;
        push(@$pos,[($xos),($yos)]);

        # right up
        $xos = $x + $i;
        $yos = $y - $i;
        push(@$pos,[($xos),($yos)]);

        # right down
        $xos = $x + $i;
        $yos = $y + $i;
        push(@$pos,[($xos),($yos)]);

    }

    my $options = {
        image  => $image,
        font   => $font,
        size => $font_size,
        string => $string,
        justify => 'center',
        height => $image->getheight(),
        width => $image->getwidth(),
    };

    # used to add a border to the text
    #
    for (my $i = 0; $i < @$pos; $i++) {

        $options->{'x'} = $pos->[$i][0];
        $options->{'y'} = $pos->[$i][1];
        $options->{'color'} = 'black';

        Imager::Font::Wrap->wrap_text(%$options)
            or die "wrap_text died: ", $image->errstr;

    }

}

sub insert_string_overlay {
    my ($self,$type,$string,$strprm) = @_;

    my $font = $self->font;
    my $image = $self->image;

    my $x = $strprm->{x};
    my $y = $strprm->{y};
    my $font_size = $strprm->{font_size};
    my $string_height = $strprm->{string_height};

    my $options = {
        x => $x,
        y => $y,
        image  => $image,
        font   => $font,
        size => $font_size,
        string => $string,
        justify => 'center',
        height => $image->getheight(),
        width => $image->getwidth(),
    };

    # the final wrap_text draws the white text ontop of
    # the black text
    #
    $options->{'color'} = 'white';

    Imager::Font::Wrap->wrap_text(%$options)
        or die "wrap_text died", $image->errstr;

}

sub get_string_parameters {
    my ($self,$type,$string) = @_;

    my $image = $self->image;
    my $image_width = $image->getwidth();
    my $image_height = $image->getheight();
    my $font = $self->font();

    my $font_size = 50;
    my $sheight = undef;
    my $strprm = {};

    my $adjusted_image_height = ($image_height / 5);

    while (1) {

        my $savepos;

        (undef,undef,undef,$sheight) = Imager::Font::Wrap->wrap_text(
            image  => undef,
            font   => $font,
            size => $font_size,
            string => $string,
            color => 'white',
            justify => 'center',
            width => $image_width,
            height => $adjusted_image_height,
            savepos => \$savepos
        );

        if ($savepos < length($string)) {
            $font_size = $font_size - 1;
        } else {
            $strprm->{font_size} = $font_size;
            $strprm->{string_height} = $sheight;
            last;
        }

    }

    if ($type eq TOP) {
        $strprm->{x} = 0;
        $strprm->{y} = 0;
    }

    if ($type eq BOTTOM) {
        $strprm->{x} = 0;
        $strprm->{y} = ($image_height - $sheight);
    }

    return $strprm;

}

sub render {
    my $self = shift;

    my $image_data;
    my $top = $self->top;
    my $bottom = $self->bottom;
    my $image = $self->image;

    if (!$top && !$bottom) {
        $image->write( data => \$image_data, type => $self->format )
            or die 'failed to write image: ', $image->errstr;

        return $image_data;
    }

    if ($top) {
        $image_data = $self->insert_string(TOP,$top);
    }

    if ($bottom) {
        $image_data = $self->insert_string(BOTTOM,$bottom);
    }

    $image->write( data => \$image_data, type => $self->format )
        or die 'failed to write image: ', $image->errstr;

    return $image_data;

}

sub get_memes {

    my $path = '/usr/share/templates/iomeme/';

    my $memes = {

        tmimitw => {
            template => $path . 'the-most-interesting-man-in-the-world.jpg'
        },

        odns => {
            template => $path . 'one-does-not-simply.jpg'
        },

        sk => {
            template => $path . 'success-kid.jpg'
        },

        ss => {
            template => $path . 'scumbag-steve.jpg'
        },

        fwp => {
            template => $path . 'first-world-problems.jpg'
        },

    };

    return $memes;
}

sub is_valid_meme {
    my ($self,$meme) = @_;

    my $memes = $self->get_memes();

    if ($memes->{$meme}) {
        return 1;
    }

    return 0;
}

sub _build_font {
    my $self = shift;
    my $path = '/usr/share/fonts/iomeme/';
    my $fontfile = 'impact.ttf';
    my $font = Imager::Font->new(file => $path . $fontfile);
    return $font;
}

__PACKAGE__->meta->make_immutable();

1;
