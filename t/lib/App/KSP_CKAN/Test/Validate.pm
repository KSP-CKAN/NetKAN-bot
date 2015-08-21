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
  # ckan-validate.py
  $self->_http->mirror( 
    url => $self->config->ckan_validate,
    path => $self->config->working."/ckan-validate.py",
    exe => 1,
  );

  # CKAN.schema
  $self->_http->mirror( 
    url => $self->config->ckan_schema,
    path => $self->config->working."/CKAN.schema",
    exe => 1,
  );
  return;
}

with('App::KSP_CKAN::Roles::Logger','App::KSP_CKAN::Roles::Validate');

1;
