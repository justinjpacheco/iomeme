#!/usr/bin/env perl
use strict;

use iomeme;
use Mojo::URL;
use Mojo::Util qw/url_unescape/;
use Mojolicious::Lite;

get '/cdn/*' => sub {
    my $self = shift;

    my $url_path = Mojo::Util::url_unescape($self->req->url);

    # remove leading / from url path
    #
    $url_path =~ s/^\///;

    my (undef,$type,$top,$bottom) = split('/',$url_path);

    my $meme = get_meme($type,$top,$bottom);
    $self->render( data => $meme->render, format => $meme->format );

} => 'cdn';

get '/*' => sub {
    my $self = shift;

    if (1) {
        my $cdn_url = get_cdn_url($self);
        return $self->redirect_to($cdn_url);
    }

    my $url_path = Mojo::Util::url_unescape($self->req->url);

    # remove leading / from url path
    #
    $url_path =~ s/^\///;

    my ($type,$top,$bottom) = split('/',$url_path);

    my $meme = get_meme($type,$top,$bottom);
    $self->render( data => $meme->render, format => $meme->format );

} => 'index';

sub get_cdn_url {
    my $self = shift;
    my $req = $self->req->url;

    my $base = $self->req->url->base->host;
    my $cdn_domain = 'nyud.net';
    my $cdn_host = $base . "." . $cdn_domain;

    my $url = Mojo::URL->new;
    $url->scheme('http');
    $url->host($cdn_host);
    $url->path($self->url_for('/cdn') . $self->req->url->to_string);

    return $url;
}

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
