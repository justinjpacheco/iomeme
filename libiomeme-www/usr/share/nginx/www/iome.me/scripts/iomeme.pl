=p
Copyright (c) 2012 ICRL

See the file license.txt for copying permission.
=cut
#!/usr/bin/env perl
use strict;

use iomeme;
use Cache::FastMmap;
use Mojolicious::Lite;
use Mojo::Util qw/url_unescape/;
use Net::Twitter::Lite;
use YAML::XS;

my $cache = Cache::FastMmap->new();

# read config file into cache
#
open my $fh, '<', '/etc/iomeme/iomeme.yaml'
  or die "can't open config file: $!";

my $config = YAML::XS::LoadFile($fh);
$cache->set("www-config", $config);


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

    my $url_to_tweet = "http://" . $headers->header('host') . "/$request_url";

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

    $self->render( data => $image_data, format => $image_format, partal => 1 );
    tweet_meme($url_to_tweet);

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

sub tweet_meme {

    my $twitter_config = $cache->get("www-config")->{'twitter'};

    if ($twitter_config->{'twitter_enabled'}) {
        my $url = shift;

        my $nt = Net::Twitter::Lite->new(
            consumer_key        => $twitter_config->{'consumer_key'},
            consumer_secret     => $twitter_config->{'consumer_secret'},
            access_token        => $twitter_config->{'access_token'},
            access_token_secret => $twitter_config->{'access_token_secret'}
        );

        eval { $nt->update($twitter_config->{'twitter_message'} . $url); }
    }

}

app->start;
