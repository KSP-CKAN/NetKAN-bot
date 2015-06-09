package Test::App::KSP_CKAN::Logger;
use Moo;
use namespace::clean;

has config => ( is => 'rw' );

with('App::KSP_CKAN::Roles::Logger');

1;
