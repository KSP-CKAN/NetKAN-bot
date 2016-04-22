#!/usr/bin/env perl -w

use lib 't/lib/';

use strict;
use warnings;
use Test::Most;
use Test::Warnings;
use File::chdir;
use App::KSP_CKAN::Test;
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

use_ok("App::KSP_CKAN::WebHooks::InflateNetKAN", qw(inflate));
my $inflate = App::KSP_CKAN::WebHooks::InflateNetKAN->new( 
  config => $config,
);

# TODO: Figure out the exporter
$inflate->inflate("DogeCoinFlag");

{
  local $CWD = $config->working;
  my @files = glob( "./CKAN-meta/DogeCoinFlag/*.ckan" );
  foreach my $file (@files) {
    ok($file =~ /DogeCoinFlag-v\d.\d\d.ckan/, "NetKAN Inflated");
  }
  is($#files, 0, "A file was found");
}

ok( -d $config->working."/cache", "NetKAN path set correctly" );

$test->cleanup;

done_testing();
__END__
