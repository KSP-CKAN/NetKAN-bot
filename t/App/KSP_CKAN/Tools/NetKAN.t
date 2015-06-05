#!/usr/bin/env perl -w

use lib 't/lib/';

use strict;
use warnings;
use Test::Most;
use Test::Warnings;
use App::KSP_CKAN::Test;
use App::KSP_CKAN::Tools::Http;
use App::KSP_CKAN::Tools::Git;

## Setup our environment
my $test = App::KSP_CKAN::Test->new();

# CKAN-meta
$test->create_repo("CKAN-meta");
my $ckan = App::KSP_CKAN::Tools::Git->new(
  remote => $test->tmp."/data/CKAN-meta",
  local => $test->tmp,
  clean => 1,
);
$ckan->pull;

# Netkan
$test->create_repo("NetKAN");
my $netkan_git = App::KSP_CKAN::Tools::Git->new(
  remote => $test->tmp."/data/NetKAN",
  local => $test->tmp,
  clean => 1,
);
$netkan_git->pull;

# netkan.exe
my $http = App::KSP_CKAN::Tools::Http->new();
$http->mirror( url => "http://ci.ksp-ckan.org:8080/job/NetKAN/lastSuccessfulBuild/artifact/netkan.exe", path => $test->tmp."/netkan.exe", exe => 1);

use_ok("App::KSP_CKAN::Tools::NetKAN");
my $netkan = App::KSP_CKAN::Tools::NetKAN->new( 
  netkan    => $test->tmp."/netkan.exe",
  cache     => $test->tmp."/cache", # TODO: Test default cache location
  ckan_meta => $test->tmp."/CKAN-meta",
  file => $test->tmp."/NetKAN/NetKAN/DogeCoinFlag.netkan"
);
is( $netkan->inflate, 0, "Return success correctly" );
my @files = glob($test->tmp."/CKAN-meta/DogeCoinFlag");
is( -e $files[0], 1, "Meta Data inflated" );

$netkan = App::KSP_CKAN::Tools::NetKAN->new( 
  netkan    => $test->tmp."/netkan.exe",
  cache     => $test->tmp."/cache",
  ckan_meta => $test->tmp."/CKAN-meta",
  file => $test->tmp."/NetKAN/NetKAN/DogeCoinFlag-broken.netkan"
);
ok( -d $test->tmp."/cache", "NetKAN Cache path set correctly");
isnt( $netkan->inflate, 0, "Return failure correctly" );

# Cleanup after ourselves
$test->cleanup;

done_testing();
__END__
