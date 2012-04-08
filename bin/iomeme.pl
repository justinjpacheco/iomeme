#!/usr/bin/perl

use strict;
use lib qw/lib/;
use iomeme;

my $meme = iomeme->new(
    meme => "tmimitw",
    top => "hello",
    bottom => 'world',
);

open(IMG,'>/tmp/output.jpg');
    print IMG $meme->render();
close(IMG);
