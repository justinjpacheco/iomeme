package MemeBuilder;

use Imager;
use Imager::Font::Wrap;
use File::Basename;
use Cwd 'abs_path';

use MemeBuilder::Util;

sub new {
  my ($class,@args) = @_;

  my $type = $args[0];
  my $filepath = $args[1];

  if ($type ne 'file') {
    die "i only support files";
  }

  if (!$filepath) {
    die "i need a file path";
  }

  my $self = {
    type => $type,
    filepath => $filepath
  };

  bless($self,$class);

  $self->_build_imager_object();
  $self->_build_imager_font_object();

  return $self;
}

sub render {
  my $self = shift;

  my $data;
  my $top = $self->top;
  my $bottom = $self->bottom;
  my $imager = $self->{imager};

  if ($top) {
    MemeBuilder::Util::insert_string($self,{loc => 'TOP', text => $top});
  }

  if ($bottom) {
    MemeBuilder::Util::insert_string($self,{loc => 'BOTTOM', text => $bottom});
  }

  # write the image
  #
  $imager->write(data => \$data, type => $self->image_type);

  if ($imager->errstr) {
    die $imager->errstr;
  }

  return $data;
}

sub top {
  my ($self,$top) = @_;

  if ($top) {
    $self->{top} = $top;
    return $self->{top};
  }

  return $self->{top};
}

sub bottom {
  my ($self,$bottom) = @_;

  if ($bottom) {
    $self->{bottom} = $bottom;
    return $self->{bottom};
  }

  return $self->{bottom};
}

sub image_type {
  my $self = shift;
  return $self->{image_type};
}

sub _build_imager_object {
  my $self = shift;

  my $filepath = $self->{filepath};

  # build imager object
  #
  my $imager = Imager->new();

  $imager->read(file => $filepath);

  if ($imager->errstr) {
    die $imager->errstr;
  }

  $self->{image_type} = $imager->tags(name => 'i_format');

  $self->{imager} = $imager;
}

sub _build_imager_font_object {
  my $self = shift;

  my $base = abs_path(__FILE__);
  my $fontpath = dirname($base) . "/MemeBuilder/impact.ttf";

  $self->{font} = Imager::Font->new(file => $fontpath, aa => 1);
}

1;