#!/usr/bin/env perl -w

use lib 't/lib/';

use strict;
use warnings;
use Test::Most;
use Test::Warnings;
use File::chdir;
use App::KSP_CKAN::Test;
use App::KSP_CKAN::NetKAN;
use App::KSP_CKAN::Tools::Config;

## Setup our environment
my $test = App::KSP_CKAN::Test->new();
$test->create_repo("CKAN-meta");
$test->create_repo("NetKAN");

# Config
$test->create_config(nogh => 1);
my $config = App::KSP_CKAN::Tools::Config->new(
  file => $test->tmp."/.ksp-ckan",
);

use_ok("App::KSP_CKAN::NetKAN");
my $netkan = App::KSP_CKAN::NetKAN->new( 
  config => $config,
);

$netkan->full_index;

{
  local $CWD = $config->working;
  my @files = glob( "./CKAN-meta/DogeCoinFlag/*.ckan" );
  foreach my $file (@files) {
    ok($file =~ /DogeCoinFlag-v\d.\d\d.ckan/, "NetKAN Inflated");
  }

  my $git = App::KSP_CKAN::Tools::Git->new(
    remote => $config->CKAN_meta,
    local => $config->working,
    clean => 1,
  );
  
  $git->_git;
  ok(! -d  "CKAN-meta/DogeCoinFlag-broken", "No broken metadata committed");
  ok(! -d  "CKAN-meta/DogeCoinFlag-invalid", "No invalid metadata committed");
     
}

ok( -d $config->cache, "NetKAN cache path set correctly" );

$test->cleanup;

done_testing();
__END__
