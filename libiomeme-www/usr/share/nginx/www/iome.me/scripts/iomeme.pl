#!/usr/bin/env perl
use strict;

use iomeme;
use Mojo::URL;
use Mojo::Util qw/url_unescape/;
use Cache::FastMmap;
use Mojolicious::Lite;

my $cache = Cache::FastMmap->new();

get '/*' => sub {
    my $self = shift;

    my $headers = $self->req->content->headers;
    my $request_url = $self->req->url;
    my $original_request_url = $headers->header('X-Original-URL');

    if ($original_request_url) {
        $request_url = Mojo::Util::url_unescape($original_request_url);
    }

    # remove leading / from url path
    #
    $request_url =~ s/^\///;

    # replace + with spaces
    #
    $request_url =~ s/\+/ /g;

    my ($type,$top,$bottom) = split('/',$request_url);

    my $key = $type.$top.$bottom;

    my ($image_data,$image_format) = undef;

    if ($cache->get($key)) {

        ($image_data,$image_format) = @{$cache->get($key)};

    } else {

        my $meme = get_meme($type,$top,$bottom);
        $cache->set($key,[$meme->render,$meme->format]);
        ($image_data,$image_format) = @{$cache->get($key)};

    }

    $self->render( data => $image_data, format => $image_format );

} => 'index';

sub get_meme {
    my ($type,$top,$bottom) = @_;

    # limit the amount of text in top and bottom
    #
    $top = substr($top,0,50) if ($top);
    $bottom = substr($bottom,0,50) if ($bottom);

    my $opt = {
        meme => $type,
        top => uc($top or ""),
        bottom => uc($bottom or "")
    };

    return iomeme->new(%$opt);

}

app->start;
