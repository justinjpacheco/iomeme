#!/usr/bin/env perl

use strict;
use iomeme;

my $meme = iomeme->new(
    meme => "tmimitw",
    top => "hello",
    bottom => 'world',
);

open(IMG,'>output.' . $meme->format);
    print IMG $meme->render();
close(IMG);
