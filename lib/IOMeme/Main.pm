package IOMeme::Main;
use Mojo::Base 'Mojolicious::Controller';
use Mojo::Util qw(b64_encode b64_decode encode);
use Mojo::Cache;
use Data::Dumper;
use Try::Tiny;
use Net::Twitter::Lite::WithAPIv1_1;
use MemeBuilder;

my $cache = Mojo::Cache->new();

sub root {
  my $self = shift;

  my $params = $self->req->params->to_hash;
  my $key = $params->{m};

  if ($key) {

    if ($cache->get($key)) {

      my ($image_data,$image_type) = @{$cache->get($key)};
      $self->render(data => $image_data, format => $image_type);
      return;

    } else {

      # decode the key back into the path we build it from
      #
      my $path = b64_decode($key);

      # build a new url with the old path
      #
      my $url = $self->url_for("/$path");

      # redirect and hope this works ;)
      #
      $self->redirect_to($url);
      return;

    }

  }

  $self->redirect_to('http://www.iome.me');
  return;

}

sub get_memes {
  my $self = shift;

  my $config = $self->config;
  my $memes = $config->{memes};

  $self->render(json => $memes);
}

sub render_meme {
  my $self = shift;

  my $config = $self->config;
  my $memes = $config->{memes};

  my $meme = $self->stash('meme');
  my $top = $self->stash('top') || '';
  my $bottom = $self->stash('bottom') || '';

  # check to see if the meme is supported
  #
  if (!$meme || !exists($memes->{$meme})) {
    $self->app->log->info("$meme meme was not found");
    $self->render_not_found;
    return;
  }

  # get absolute path to meme template file
  #
  my $relpath = 'templates/memes/' . $memes->{$meme}->{template};
  my $filepath = $self->app->home->rel_file($relpath);

  # bail if the template file doesn't exist
  #
  if (!-e $filepath) {
    $self->app->log->info("$filepath does not exist");
    $self->render_not_found;
    return;
  }

  my $key = b64_encode(encode('UTF-8',"$meme/$top/$bottom"));

  # build url that includes base64 encoding
  #
  my $url = $self->url_for('/')->query(m => $key);

  # build the meme if not in the cache
  #
  if (!$cache->get($key)) {

    my $mb = MemeBuilder->new(file => $filepath);

    # replace + with spaces
    #
    $top =~ s/\+/ /g;
    $bottom =~ s/\+/ /g;

    # uppercase
    #
    $top = uc($top);
    $bottom = uc($bottom);

    $mb->top($top);
    $mb->bottom($bottom);

    $cache->set($key,[$mb->render,$mb->image_type]);

    if ($config->{twitter}->{enabled} && ($top || $bottom)) {

      my $nt = Net::Twitter::Lite::WithAPIv1_1->new(
        consumer_key        => $config->{twitter}->{'consumer_key'},
        consumer_secret     => $config->{twitter}->{'consumer_secret'},
        access_token        => $config->{twitter}->{'access_token'},
        access_token_secret => $config->{twitter}->{'access_token_secret'}
      );

      my $hashtag = $memes->{$meme}->{name};
      $hashtag =~ s/ //g;

      try {
        $nt->update(
          $config->{twitter}->{'message'} .
          "http://iome.me" . $url .
          " #" . lc($hashtag)
        );
      } catch {
        $self->app->log->warn("Posting meme to twitter failed: $_");
      }

    }

  }

  # redirect to a url that isn't easy to read
  #
  $self->redirect_to($url);

  return;
}

1;
