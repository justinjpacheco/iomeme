package IOMeme;
use Mojo::Base 'Mojolicious';

# This method will run once at server start
sub startup {
  my $self = shift;

  # read config file
  #
  $self->plugin(Config => {file => 'etc/iomeme.conf'});

  # setup routes
  #
  my $r = $self->routes;

  $r->get('/')->to('main#root');
  $r->get('/meme')->to('main#get_memes');

  $r->get('/:meme/:top/:bottom')->to('main#render_meme');
  $r->get('/:meme//:bottom')->to('main#render_meme');
  $r->get('/:meme/:top')->to('main#render_meme');
  $r->get('/:meme')->to('main#render_meme');

}

1;
