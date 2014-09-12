package IOMeme::Main;
use Mojo::Base 'Mojolicious::Controller';
use MemeBuilder;

sub root {
  my $self = shift;
  $self->redirect_to('http://www.iome.me');
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

  # build the meme
  #
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

  $self->render(data => $mb->render, format => $mb->image_type);
}

1;
