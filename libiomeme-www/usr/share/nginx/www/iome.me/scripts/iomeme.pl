#!/usr/bin/env perl
use strict;

use iomeme;
use Mojo::URL;
use Mojo::Util qw/url_unescape/;
use Cache::FastMmap;
use Mojolicious::Lite;

# Uses vaguely sane defaults
my $cache = Cache::FastMmap->new();

get '/*' => sub {
    my $self = shift;

    my $url_path = Mojo::Util::url_unescape($self->req->url);

    use Data::Dumper;
    $self->app->log->debug(Dumper $sef->req->env);
    $self->app->log->debug(Dumper $self->req->content->headers->to_string);
    #$self->app->log->debug(Dumper %ENV);

    # remove leading / from url path
    #
    $url_path =~ s/^\///;

    my ($type,$top,$bottom) = split('/',$url_path);

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
