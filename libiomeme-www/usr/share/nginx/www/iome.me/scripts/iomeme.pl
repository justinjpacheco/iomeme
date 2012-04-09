#!/usr/bin/env perl

use Mojolicious::Lite;
use iomeme;

get '/:type/:top/:bottom' => sub {
    my $self = shift;

    my $type = $self->param('type');
    my $top = $self->param('top');
    my $bottom = $self->param('bottom');

    my $opt = {
        meme => $type,
        top => uc($top),
        bottom => uc($bottom)
    };

    my $meme = iomeme->new(%$opt);

    $self->render( data => $meme->render, format => $meme->format );
};

app->start;
