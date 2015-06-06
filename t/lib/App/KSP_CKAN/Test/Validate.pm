package App::KSP_CKAN::Test::Validate;
use Method::Signatures 20140224;
use App::KSP_CKAN::Tools::Http;
use Moo;
use namespace::clean;

has config    => ( is => 'rw' );
has '_http'   => ( is => 'ro', lazy => 1, builder => 1 );

method _build__http {
  return App::KSP_CKAN::Tools::Http->new();
}

method _mirror_files {
  return;
}

with('App::KSP_CKAN::Roles::Validate');

1;
