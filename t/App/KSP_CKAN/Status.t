#!/usr/bin/env perl -w

use lib 't/lib/';

use strict;
use warnings;
use Test::Most;
use Test::Warnings;
use Test::MockTime 'set_relative_time';
use App::KSP_CKAN::Test;
use App::KSP_CKAN::Tools::Config;

# Setup our environment
my $test = App::KSP_CKAN::Test->new();
$test->create_config;

use_ok("App::KSP_CKAN::Status");

my $config = App::KSP_CKAN::Tools::Config->new(
  file => $test->tmp."/.ksp-ckan",
);

my $status = App::KSP_CKAN::Status->new(
  config => $config,
);

my $netkan = $status->get_status("TestKAN");
is($netkan->DOES("App::KSP_CKAN::Status::NetKAN"), 1, "App::KSP_CKAN::Status::NetKAN Object returned");
$netkan->update;
my $updated = $netkan->last_updated;

$status->write_json;
is(-e $status->_status_file, 1, "Status file written");

$status = App::KSP_CKAN::Status->new(
  config => $config,
);

$netkan = $status->get_status("TestKAN");
is($netkan->last_updated, $updated, "Data persists between file loads");

# Test runs too fast for the time to be different
set_relative_time(10);
$netkan->update;
isnt($netkan->last_updated, $updated, "Last updated changes value");

$test->cleanup;

done_testing();
