#!/usr/bin/env perl
use strict;

use iomeme;
use Mojolicious::Lite;

get '/*' => sub {
    my $self = shift;

    # mojo considers "." to be a different url path
    # so we'll get it out ourselves
    #
    my ($type,$top,$bottom) = @{$self->req->url->path->parts};

    # limit the amount of text in top and bottom
    #
    $top = substr($top,0,50) if ($top);
    $bottom = substr($bottom,0,50) if ($bottom);

    my $opt = {
        meme => $type,
        top => uc($top or ""),
        bottom => uc($bottom or "")
    };

    my $meme = iomeme->new(%$opt);

    $self->render( data => $meme->render, format => $meme->format );

};

app->start;
