#!/usr/bin/env perl -w

use lib 't/lib/';

use strict;
use warnings;
use Test::Most;
use Test::Warnings;
use File::chdir;
use App::KSP_CKAN::Test;
use App::KSP_CKAN::Tools::Config;


use_ok("App::KSP_CKAN::WebHooks::InflateNetKAN");

subtest 'Scalar Identifier' => sub {
  ## Setup our environment
  my $test = App::KSP_CKAN::Test->new();
  $test->create_repo("CKAN-meta");
  $test->create_repo("NetKAN");
  
  # Config
  $test->create_config();
  my $config = App::KSP_CKAN::Tools::Config->new(
    file => $test->tmp."/.ksp-ckan",
  );
  my $inflate = App::KSP_CKAN::WebHooks::InflateNetKAN->new( 
    config => $config,
  );

  $inflate->inflate("DogeCoinFlag");

  {
    local $CWD = $config->working;
    my @files = glob( "./CKAN-meta/DogeCoinFlag/*.ckan" );
    foreach my $file (@files) {
      ok($file =~ /DogeCoinFlag-v\d.\d\d.ckan/, "NetKAN Inflated");
    }
    
    TODO: {
      local $TODO = "This test is broken on travis for some reason." if ($ENV{TRAVIS});
      is($#files, 0, "A file was found");
    }
    ok( -d $config->cache, "NetKAN cache path set correctly" );
  }
  
  $test->cleanup;
};

subtest 'Array of Identifiers' => sub {
  ## Setup our environment
  my $test = App::KSP_CKAN::Test->new();
  $test->create_repo("CKAN-meta");
  $test->create_repo("NetKAN");
  
  # Config
  $test->create_config();
  my $config = App::KSP_CKAN::Tools::Config->new(
    file => $test->tmp."/.ksp-ckan",
  );
  my $inflate = App::KSP_CKAN::WebHooks::InflateNetKAN->new( 
    config => $config,
  );

  # TODO: We should expand for multiple unique identifiers in testing
  my @identifiers = qw(DogeCoinFlag DogeCoinFlag);
  $inflate->inflate(\@identifiers);
  {
    local $CWD = $config->working;
    my @files = glob( "./CKAN-meta/DogeCoinFlag/*.ckan" );
    foreach my $file (@files) {
      ok($file =~ /DogeCoinFlag-v\d.\d\d.ckan/, "NetKAN Inflated");
    }
    
    TODO: {
      local $TODO = "This test is broken on travis for some reason." if ($ENV{TRAVIS});
      is($#files, 0, "A file was found");
    }
    ok( -d $config->cache, "NetKAN cache path set correctly" );
  }
  $test->cleanup;
};

done_testing();
__END__
