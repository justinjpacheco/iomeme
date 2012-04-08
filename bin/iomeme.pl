#!/usr/bin/perl

use strict;
use iomeme;

my $meme = iomeme->new(
    meme => "tmimitw",
    top => "hello",
    bottom => 'world',
);

open(IMG,'>output.jpg');
    print IMG $meme->render();
close(IMG);
