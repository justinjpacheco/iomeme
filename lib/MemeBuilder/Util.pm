package MemeBuilder::Util;

sub insert_string {
    my ($mb,$args) = @_;

    my $loc = $args->{loc};
    my $text = $args->{text};

    my $strprm = get_string_parameters($mb,$loc,$text);

    insert_string_border($mb,$strprm);
    insert_string_overlay($mb,$strprm);
}

sub insert_string_border {
  my ($mb,$strprm) = @_;

  my $font = $mb->{font};
  my $imager = $mb->{imager};

  my $x = $strprm->{x};
  my $y = $strprm->{y};
  my $text = $strprm->{text};
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
    image  => $imager,
    font   => $font,
    size => $font_size,
    string => $text,
    justify => 'center',
    height => $imager->getheight(),
    width => $imager->getwidth(),
  };

  # used to add a border to the text
  #
  for (my $i = 0; $i < @$pos; $i++) {

    $options->{'x'} = $pos->[$i][0];
    $options->{'y'} = $pos->[$i][1];
    $options->{'color'} = 'black';

    Imager::Font::Wrap->wrap_text(%$options)
        or die "wrap_text died: ", $imager->errstr;

  }
}

sub insert_string_overlay {
  my ($mb,$strprm) = @_;

  my $font = $mb->{font};
  my $imager = $mb->{imager};

  my $x = $strprm->{x};
  my $y = $strprm->{y};
  my $text = $strprm->{text};
  my $font_size = $strprm->{font_size};
  my $string_height = $strprm->{string_height};

  my $options = {
    x => $x,
    y => $y,
    image  => $imager,
    font   => $font,
    size => $font_size,
    string => $text,
    justify => 'center',
    height => $imager->getheight(),
    width => $imager->getwidth(),
  };

  # the final wrap_text draws the white text ontop of
  # the black text
  #
  $options->{'color'} = 'white';

  Imager::Font::Wrap->wrap_text(%$options)
      or die "wrap_text died", $imager->errstr;
}

sub get_string_parameters {
  my ($mb,$loc,$text) = @_;

  my $imager = $mb->{imager};

  my $image_width = $imager->getwidth();
  my $image_height = $imager->getheight();
  my $font = $mb->{font};

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
      string => $text,
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

  if ($loc eq 'TOP') {
    $strprm->{x} = 0;
    $strprm->{y} = 0;
  }

  if ($loc eq 'BOTTOM') {
    $strprm->{x} = 0;
    $strprm->{y} = ($image_height - $sheight);
  }

  $strprm->{text} = $text;

  return $strprm;
}


1;