#!/usr/bin/env perl

use strict;
use lib qw/lib/;
use iomeme;

my $meme = iomeme->new(
    meme => "tmimitw",
    top => "hello",
    bottom => 'world',
);

open(IMG,'>/tmp/output.' . $meme->format);
    print IMG $meme->render();
close(IMG);
