package App::KSP_CKAN::Cached;

use strict;
use warnings;
use App::KSP_CKAN::Tools::Config;
use Method::Signatures 20140224;
use Test::Most;
use Moo;
use namespace::clean;

has 'package'     => ( is => 'ro', default => sub { 'IA' } );
has 'config'      => ( is => 'ro', lazy => 1, builder => 1 );
has 'test_config' => ( is => 'ro' );
has 'tmp' => ( is => 'ro' );

method _build_config() {
  my $config = App::KSP_CKAN::Tools::Config->new( file => "$ENV{HOME}/.ksp_ckan-test" );
  return $config;
}

method _live_ia {
  return App::KSP_CKAN::Tools::IA->new(
    config      => $self->config,
    collection  => "test_collection",
  );
}

method _cached_ia {
  return App::KSP_CKAN::Tools::IA->new(
    config      => $self->test_config,
    collection  => "test_collection",
    iaS3uri     => "http://localhost:3001",
    iaDLuri     => "http://localhost:3001/download",
    iaMDuri     => "http://localhost:3001/metadata",
  );
}

method _live_environment {
  if ( $self->package eq 'Mirror' ) {
    return App::KSP_CKAN::Mirror->new( 
      config  => $self->config,
      tmp     => $self->tmp,
      '_ia'   => $self->_live_ia,
    );
  }
  return $self->_cached_ia;
}

method _cached_environment {
  if ( $self->package eq 'Mirror' ) {
    return App::KSP_CKAN::Mirror->new( 
      config  => $self->test_config,
      tmp     => $self->tmp,
      '_ia'   => $self->_cached_ia,
    );
  }
  return $self->_cached_ia;
}

method test_live($test, $number_tests) {
  SKIP: {
  #  skip "No auth credentials found.", $number_tests unless ( -e "$ENV{HOME}/.ksp_ckan-test" );
    skip "Live tests are not yet implemented.", $number_tests;

    $test->($self->_live_environment, $self->tmp, "Testing Live Internet Archive API");
  }
}

method test_cached($test, $number_tests) {
  SKIP: {
    eval {  
      require Dancer2; 
    };

    skip 'These tests are for cached testing and require Dancer2', $number_tests if ($@);

    my $pid = fork();

    if (!$pid) {
      exec("t/bin/cached_api.pl");
    }

    # Allow some time for the instance to spawn. TODO: Make this smarter
    sleep 5;

    $test->($self->_cached_environment, $self->tmp,"Testing Cached API");
  
    # Kill Dancer
    kill 9, $pid;
  }
}

1;
