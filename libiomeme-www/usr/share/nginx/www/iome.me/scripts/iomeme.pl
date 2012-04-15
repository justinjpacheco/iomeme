#!/usr/bin/env perl
use strict;

use iomeme;
use Cache::FastMmap;
use Mojolicious::Lite;
use Mojo::Util qw/url_unescape/;

my $cache = Cache::FastMmap->new();

get '/*' => sub {
    my $self = shift;

    my ($image_data,$image_format) = undef;

    my $headers = $self->req->content->headers;
    my $original_request_url = $headers->header('X-Original-URL');

    my $request_url = $self->req->url;

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

    # we use this key as an index to our cache store
    #
    my $key = $type.$top.$bottom;

    if ($cache->get($key)) {

        ($image_data,$image_format) = @{$cache->get($key)};

    } else {

        my $meme = get_meme($type,$top,$bottom);
        ($image_data,$image_format) = ($meme->render,$meme->format);
        $cache->set($key,[$image_data,$image_format]);

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
