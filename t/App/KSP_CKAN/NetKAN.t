#!/usr/bin/env perl -w

use lib 't/lib/';

use strict;
use warnings;
use Test::Most;
use Test::Warnings;
use App::KSP_CKAN::Test;
use App::KSP_CKAN::NetKAN;
use App::KSP_CKAN::Tools::Config;

## Setup our environment
my $test = App::KSP_CKAN::Test->new();
$test->create_repo("CKAN-meta");
$test->create_repo("NetKAN");

# Config
$test->create_config;
my $config = App::KSP_CKAN::Tools::Config->new(
  file => $test->tmp."/.ksp-ckan",
);

use_ok("App::KSP_CKAN::NetKAN");
my $netkan = App::KSP_CKAN::NetKAN->new( 
  config => $config,
);

$netkan->full_index;

# TODO: Write MOAR tests

# Cleanup after ourselves
$test->cleanup;

done_testing();
__END__
