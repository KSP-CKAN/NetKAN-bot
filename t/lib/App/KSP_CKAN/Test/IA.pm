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
    status(503);
    return '';
  }
};

put '/:item/:file' => sub {
  if ( ! defined $state->{upload} ) {
    $state->{upload} = 1;
    return '';
  } else {
    status(400);
    return '';
  }
};

get '/download/:item/:file' => sub {
  if ( ! defined $state->{check} ) {
    $state->{check} = 1;
    return '';
  } else {
    status(400);
    return '';
  }
};

1;
