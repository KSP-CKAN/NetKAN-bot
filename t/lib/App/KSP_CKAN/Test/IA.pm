package App::KSP_CKAN::Test::IA;

use Dancer2;

# A little ugly, but works for this purpose.
my $state;

# TODO: These could stand to be more thorough, but is enough
#       to test the code pathways.

get '/' => sub {
  if ( ! defined $state->{overload} ) {
    $state->{overload} = 1;
    return '';
  } else {
    $state->{overload} = undef;
    status(503);
    return '';
  }
};

put '/:item/:file' => sub {
  if ( ! defined $state->{upload} ) {
    $state->{upload} = 1;
    return '';
  } else {
    $state->{upload} = undef;
    status(400);
    return '';
  }
};

get '/download/:item/:file' => sub {
  if ( ! defined $state->{check} ) {
    $state->{check} = 1;
    return '';
  } else {
    $state->{check} = undef;
    status(400);
    return '';
  }
};

get '/metadata/:item' => sub {
  if ( ! defined $state->{mirrored} ) {
    $state->{mirrored} = 1;
    return '{ "files": [ { "name": "74770739-ExampleKAN-1.0.0.1.zip", "sha1": "1a2B3c4D5e"} ] }';
  } else {
    return '{ }';
  }
};

1;
