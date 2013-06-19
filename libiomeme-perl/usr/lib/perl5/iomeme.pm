=p
Copyright (c) 2012 ICRL

See the file license.txt for copying permission.
=cut
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

    # FIXME: what should we do if the meme doesn't exist?
    #
    my $meme = $memes->{$self->meme} || $memes->{'tid'};
    my $image = Imager->new();

    # FIXME: better error handling
    #
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

    my $font_size = 42;
    my $sheight = undef;
    my $strprm = {};

    my $adjusted_image_height = ($image_height / 3);

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
        ad => {
            name => "Advice dog",
            template => $path . 'advice-dog.jpg',
            desc => "http://knowyourmeme.com/memes/advice-dog"
        },
        ag => {
            name => "Advice God",
            template => $path . 'advice-god.jpg',
            desc => "http://knowyourmeme.com/memes/advice-god"
        },
        ap => {
            name => "Annoyed Picard",
            template => $path . 'annoyed-picard.jpg',
        },
        acf => {
            name => "Annoying childhood friend",
            template => $path . 'annoying-childhood-friend.jpg',
            desc => "http://knowyourmeme.com/memes/annoying-childhood-friend"
        },
        afg => {
            name => "Annoying facebook girl",
            template => $path . 'annoying-facebook-girl.jpg',
            desc => "http://knowyourmeme.com/memes/annoying-facebook-girl"
        },
        ajc => {
            name => "Anti-joke chicken",
            template => $path . 'anti-joke-chicken.jpg',
            desc => "http://knowyourmeme.com/memes/anti-joke-chicken"
        },
        aso => {
            name => "Art student owl",
            template => $path . 'art-student-owl.jpg',
            desc => "http://knowyourmeme.com/memes/art-student-owl"
        },
        aitoo => {
            name => "Am I the only one",
            template => $path . 'am-i-the-only-one.jpg',
        },
        apcr => {
            name => "Almost politically correct redneck",
            template => $path . 'almost-politically-correct-redneck.jpg',
        },
        bac => {
            name => "Bad advice cat",
            template => $path . 'bad-advice-cat.jpg',
            desc => "http://knowyourmeme.com/memes/bad-advice-cat"
        },
        blb => {
            name => "Bad luck Brian",
            template => $path . 'bad-luck-brian.jpg',
            desc => "http://knowyourmeme.com/memes/bad-luck-brian"
        },
        bg => {
            name => "Bear Grylls",
            template => $path . 'bear-grylls.jpg',
            desc => "http://knowyourmeme.com/memes/bear-grylls-better-drink-my-own-piss"
        },
        bo => {
            name => "Bill Oreilly",
            template => $path . 'bill-oreilly.jpg',
            desc => "http://knowyourmeme.com/memes/bill-oreilly-you-cant-explain-that"
        },
        bc => {
            name => "Business cat",
            template => $path . 'business-cat.jpg',
            desc => "http://knowyourmeme.com/memes/business-cat"
        },
        bd => {
            name => "Butthurt Dweller",
            template => $path . 'butthurt-dweller.jpg',
            desc => "http://knowyourmeme.com/memes/butthurt-dweller-gordo-granudo"
        },
        bor => {
            name => "Bill O'Reilly Rant",
            template => $path . 'bill-oreilly-rant.jpg',
            desc => "http://knowyourmeme.com/memes/bill-oreilly-rant"
        },
        cc => {
            name => "Chemistry cat",
            template => $path . 'chemistry-cat.jpg',
            desc => "http://knowyourmeme.com/memes/chemistry-cat",
        },
        cf => {
            name => "College freshman",
            template => $path . 'college-freshman.jpg',
            desc => "http://knowyourmeme.com/memes/uber-frosh-college-freshman"
        },
        ch => {
            name => "Captain hindsight",
            template => $path . 'captain-hindsight.jpg',
            desc => "http://knowyourmeme.com/memes/captain-hindsight"
        },
        ck => {
            name => "Conspiracy Keanu",
            template => $path . 'conspiracy-keanu.jpg',
            desc => "http://knowyourmeme.com/memes/conspiracy-keanu"
        },
        cw => {
            name => "Courage wolf",
            template => $path . 'courage-wolf.jpg',
            desc => "http://knowyourmeme.com/memes/courage-wolf"
        },
        ccw => {
            name => "Creepy condescending Wonka",
            template => $path . 'creepy-condescending-wonka.jpg',
            desc => "http://knowyourmeme.com/memes/condescending-wonka-creepy-wonka"
        },
        ccc => {
            name => "Cool chick Carol",
            template => $path . 'cool-chick-carol.jpg',
            desc => "http://knowyourmeme.com/memes/cool-chick-carol"
        },
        cgpm => {
            name => "Crazy girlfriend praying mantis",
            template => $path . 'crazy-girlfriend-praying-mantis.jpg',
            desc => "http://knowyourmeme.com/memes/crazy-girlfriend-praying-mantis"
        },
        dd => {
            name => "Depression dog",
            template => $path . 'depression-dog.jpg',
            desc => "http://knowyourmeme.com/memes/depression-dog"
        },
        dr => {
            name => "Downvoting Roman",
            template => $path . 'downvoting-roman.jpg',
            desc => "http://knowyourmeme.com/memes/downvoting-roman-commodus-thumbsdown"
        },
        ds => {
            name => "Dwight Schrute",
            template => $path . 'dwight-schrute.jpg',
            desc => "http://knowyourmeme.com/memes/schrute-facts"
        },
        dsm => {
            name => "Dating site murderer",
            template => $path . 'dating-site-murderer.jpg',
            desc => "http://knowyourmeme.com/memes/dating-site-murderer-good-intentions-axe-murderer"
        },
        dvt => {
            name => "Domestic violence turtle",
            template => $path . 'domestic-violence-turtle.jpg'
        },
        ec => {
            name => "Eye contact",
            template => $path . 'eye-contact.jpg'
        },
        ftsg => {
            name => "Family tech support guy",
            template => $path . 'family-tech-support-guy.jpg',
            desc => "http://knowyourmeme.com/memes/family-technical-support"
        },
        fa => {
            name => "Forever alone",
            template => $path . 'forever-alone.jpg',
            desc => "http://knowyourmeme.com/memes/forever-alone"
        },
        fbf => {
            name => "Foul bachelor frog",
            template => $path . 'foul-bachelor-frog.jpg',
            desc => "http://knowyourmeme.com/memes/foul-bachelor-frog"
        },
        fbtf => {
            name => "Foul bachelorette frog",
            template => $path . 'foul-bachelorette-frog.jpg',
            desc => "http://knowyourmeme.com/memes/foul-bachelorette-frog"
        },
        fdotik => {
            name => "First day on the Internet kid",
            template => $path . 'first-day-on-the-internet-kid.jpg',
            desc => "http://knowyourmeme.com/memes/first-day-on-the-internet-kid"
        },
        ff => {
            name => "Futurama Fry",
            template => $path . 'futurama-fry.jpg',
            desc => "http://knowyourmeme.com/memes/futurama-fry-not-sure-if-x"
        },
        fp => {
            name => "Picard facepalm",
            template => $path . 'picard-facepalm.jpg',
            desc => "http://knowyourmeme.com/memes/people/jean-luc-picard"
        },
        fz => {
            name => "Futurama Zoidberg",
            template => $path . 'futurama-zoidberg.jpg',
            desc => "http://knowyourmeme.com/memes/futurama-zoidberg-why-not-zoidberg"
        },
        fwp => {
            name => "First world problems",
            template => $path . 'first-world-problems.jpg',
            desc => "http://knowyourmeme.com/memes/first-world-problems"
        },
        fsc => {
            name => "Friend stealing credit",
            template => $path . 'friend-stealing-credit.jpg'
        },
        ggg => {
            name => "Good guy Greg",
            template => $path . 'good-guy-greg.jpg',
            desc => "http://knowyourmeme.com/memes/good-guy-greg"
        },
        gggi => {
            name => "Good girl Gina",
            template => $path . 'good-girl-gina.jpg',
            desc => "http://knowyourmeme.com/memes/good-girl-gina"
        },
        gfti => {
            name => "Grandma finds the Internet",
            template => $path . 'grandma-finds-the-internet.jpg',
            desc => "http://knowyourmeme.com/memes/internet-grandma-surprise"
        },
        gcat => {
            name => "Grumpy Cat",
            template => $path . 'grumpy-cat.jpg',
            desc => "http://knowyourmeme.com/memes/grumpy-cat"
        },
        htd => {
            name => "Helpful Tyler Durden",
            template => $path . 'helpful-tyler-durden.jpg',
            desc => "http://knowyourmeme.com/memes/disruptive-durden-helpful-tyler-durden"
        },
        heaf => {
            name => "High expectations asian father",
            template => $path . 'high-expectations-asian-father.jpg',
            desc => "http://knowyourmeme.com/memes/high-expectations-asian-father"
        },
        hb => {
            name => "Hipster barista",
            template => $path . 'hipster-barista.jpg',
            desc => "http://knowyourmeme.com/memes/hipster-barista",
        },
        hk => {
            name => "Hipster kitty",
            template => $path . 'hipster-kitty.jpg',
            desc => "http://knowyourmeme.com/memes/hipster-kitty",
        },
        in => {
            name => "Imminent Ned",
            template => $path . 'imminent-ned.jpg',
            desc => "http://knowyourmeme.com/memes/imminent-ned-brace-yourselves-x-is-coming"
        },
        ih => {
            name => "Internet husband",
            template => $path . 'redditors-wife.jpg',
            desc => "http://knowyourmeme.com/memes/internet-husband"
        },
        iw => {
            name => "Insanity wolf",
            template => $path . 'insanity-wolf.jpg',
            desc => "http://knowyourmeme.com/memes/insanity-wolf"
        },
        ing => {
            name => "Idiot nerd girl",
            template => $path . 'idiot-nerd-girl.jpg',
            desc => "http://knowyourmeme.com/memes/idiot-nerd-girl"
        },
        itbc => {
            name => "Inappropriate timing Bill Clinton",
            template => $path . 'inappropriate-timing-bill-clinton.jpg',
        },
        jd => {
            name => "Joseph Ducreux",
            template => $path . 'joseph-ducreux.jpg',
            desc => "http://knowyourmeme.com/memes/joseph-ducreux-archaic-rap"
        },
        kk => {
            name => "Karate Kyle",
            template => $path . 'karate-kyle.jpg',
            desc => "http://knowyourmeme.com/memes/karate-kyle"
        },
        ll => {
            name => "Lonely Lenny",
            template => $path . 'lonely-lenny.jpg'
        },
        lpc => {
            name => "Lame pun coon",
            template => $path . 'lame-pun-coon.jpg',
            desc => "http://knowyourmeme.com/memes/lame-pun-coon"
        },
        moeg => {
            name => "Musically oblivious 8th grader",
            template => $path . 'musically-oblivious-8th-grader.jpg',
            desc => "http://knowyourmeme.com/memes/musically-oblivious-8th-grader"
        },
        nn => {
            name => "Net noob",
            template => $path . 'net-noob.jpg',
            desc => "http://knowyourmeme.com/memes/lonely-computer-guy-net-noob"
        },
        og => {
            name => "Office grizzly",
            template => $path . 'office-grizzly.jpg',
            desc => "http://knowyourmeme.com/memes/office-grizzly"
        },
        oag => {
            name => "Overly attached girlfriend",
            template => $path . 'overly-attached-girlfriend.jpg',
        },
        oep => {
            name => "Over educated problems",
            template => $path . 'over-educated-problems.jpg',
        },
        omm => {
            name => "Ordinary muslim man",
            template => $path . 'ordinary-muslim-man.jpg',
            desc => "http://knowyourmeme.com/memes/ordinary-muslim-man"
        },
        odns => {
            name => "One does not simply",
            template => $path . 'one-does-not-simply.jpg',
            desc => "http://knowyourmeme.com/memes/one-does-not-simply-walk-into-mordor"
        },
        p => {
            name => "Pedobear",
            template => $path . 'pedobear.jpg',
            desc => "http://knowyourmeme.com/memes/pedobear"
        },
        pp => {
            name => "Paranoid parrot",
            template => $path . 'paranoid-parrot.jpg',
            desc => "http://knowyourmeme.com/memes/paranoid-parrot"
        },
        pr => {
            name => "Philosoraptor",
            template => $path . 'philosoraptor.jpg',
            desc => "http://knowyourmeme.com/memes/philosoraptor"
        },
        plp => {
            name => "Pickup line panda",
            template => $path . 'pickup-line-panda.jpg',
            desc => "http://knowyourmeme.com/memes/pickup-line-panda"
        },
        pcb => {
            name => "PTSD clarinet boy",
            template => $path . 'ptsd-clarinet-boy.jpg',
            desc => "http://knowyourmeme.com/memes/ptsd-clarinet-boy"
        },
        pisep => {
            name => "Push it somewhere else patrick",
            template => $path . 'put-it-somewhere-else-patrick.jpg',
            desc => "http://knowyourmeme.com/memes/push-it-somewhere-else-patrick"
        },
        rr => {
            name => "Redneck Randal",
            template => $path . 'redneck-randal.jpg',
            desc => "http://knowyourmeme.com/memes/redneck-randal"
        },
        rt => {
            name => "Regretful toddler",
            template => $path . 'regretful-toddler.jpg'
        },
        rzt => {
            name => "Rez Trisha",
            template => $path . 'rez-trisha.jpg'
        },
        rpg => {
            name => "Ridiculously photogenic guy",
            template => $path . 'ridiculously-photogenic-guy.jpg',
            desc => "http://knowyourmeme.com/memes/ridiculously-photogenic-guy-zeddie-little"
        },
        rra => {
            name => "Rich raven",
            template => $path . 'rich-raven.jpg',
            desc => "http://knowyourmeme.com/memes/rich-raven"
        },
        rst => {
            name => "Rasta science teacher",
            template => $path . 'rasta-science-teacher.jpg',
            desc => "http://knowyourmeme.com/memes/rasta-science-teacher"
        },
        sg => {
            name => "Scumbag girl",
            template => $path . 'scumbag-girl.jpg',
            desc => "http://knowyourmeme.com/memes/scumbag-girl-scumbag-stacy"
        },
        sk => {
            name => "Success kid",
            template => $path . 'success-kid.jpg',
            desc => "http://knowyourmeme.com/memes/i-hate-sandcastles-success-kid"
        },
        sd => {
            name => "Stoner dog",
            template => $path . 'stoner-dog.jpg',
            desc => "http://knowyourmeme.com/memes/stoner-dog"
        },
        sp => {
            name => "Slowpoke",
            template => $path . 'slowpoke.jpg',
            desc => "http://knowyourmeme.com/memes/slowpoke"
        },
        ss => {
            name => "Scumbag Steve",
            template => $path . 'scumbag-steve.jpg',
            desc => "http://knowyourmeme.com/memes/scumbag-steve"
        },
        sap => {
            name => "Socially awkward penguin",
            template => $path . 'socially-awkward-penguin.jpg',
            desc => "http://knowyourmeme.com/memes/socially-awkward-penguin"
        },
        sbg => {
            name => "Sad birthday girl",
            template => $path . 'sad-birthday-girl.jpg',
        },
        sbm => {
            name => "Successful black man",
            template => $path . 'successful-black-man.jpg',
            desc => "http://knowyourmeme.com/memes/successful-black-man"
        },
        sor => {
            name => "Sexually oblivious rhino",
            template => $path . 'sexually-oblivious-rhino.jpg',
            desc => "http://knowyourmeme.com/memes/sexually-oblivious-rhino"
        },
        ssm => {
            name => "Sheltering suburban mom",
            template => $path . 'sheltering-suburban-mom.jpg',
            desc => "http://knowyourmeme.com/memes/sheltering-suburban-mom"
        },
        swa => {
            name => "Say what again",
            template => $path . 'say-what-again.jpg',
            desc => "http://knowyourmeme.com/memes/say-what-again"
        },
        saap => {
            name => "Socially awkward/awesome penguin",
            template => $path . 'socially-awkward-awesome-penguin.jpg',
            desc => "http://www.quickmeme.com/Socially-Awkward-Awesome-Penguin/"
        },
        sawp => {
            name => "Socially awesome penguin",
            template => $path . 'socially-awesome-penguin.jpg',
            desc => "http://knowyourmeme.com/memes/socially-awesome-penguin"
        },
        scsi => {
            name => "Super cool ski instructor",
            template => $path . 'super-cool-ski-instructor.jpg',
            desc => "http://knowyourmeme.com/memes/super-cool-ski-instructor"
        },
        tid => {
            name => "Tech impaired duck",
            template => $path . 'tech-impaired-duck.jpg',
            desc => "http://knowyourmeme.com/memes/technologically-impaired-duck"
        },
        tws => {
            name => "Third world success",
            template => $path . 'third-world-success.jpg',
            desc => "http://knowyourmeme.com/memes/third-world-success"
        },
        tmicitw => {
            name => "The most interesting cat in the world",
            template => $path . 'the-most-interesting-cat-in-the-world.jpg',
            desc => "http://knowyourmeme.com/memes/the-most-interesting-cat-in-the-world"
        },
        tmimitw => {
            name => "The most interesting man in the world",
            template => $path . 'the-most-interesting-man-in-the-world.jpg',
            desc => "http://knowyourmeme.com/memes/the-most-interesting-man-in-the-world"
        },
        tdh => {
            name => "Too damn high",
            template => $path . 'too-damn-high.jpg',
            desc => "http://knowyourmeme.com/memes/the-rent-is-too-damn-high-jimmy-mcmillan"
        },
        uht => {
            name => "Unhelpful highschool teacher",
            template => $path . 'unhelpful-highschool-teacher.jpg',
            desc => "http://knowyourmeme.com/memes/unhelpful-high-school-teacher"
        },
        xaty => {
            name => "X all the Y",
            template => $path . 'x-all-the-y.jpg',
            desc => "http://knowyourmeme.com/memes/x-all-the-y"
        },
        yun => {
            name => "Y u no",
            template => $path . 'y-u-no.jpg',
            desc => "http://knowyourmeme.com/memes/y-u-no-guy"
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
    my $font = Imager::Font->new(file => $path . $fontfile, aa => 1);
    return $font;
}

__PACKAGE__->meta->make_immutable();

1;
