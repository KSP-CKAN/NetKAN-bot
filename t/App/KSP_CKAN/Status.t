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

# Set our initial states
$netkan->inflated;
$netkan->indexed;
$netkan->checked;
my $inflated = $netkan->last_inflated;
my $indexed = $netkan->last_indexed;
my $checked = $netkan->last_checked;
$status->update_status("TestKAN", $netkan);

is(-e $status->_status_file, 1, "Status file written");

$status = App::KSP_CKAN::Status->new(
  config => $config,
);

$netkan = $status->get_status("TestKAN");
is($netkan->last_inflated, $inflated, "Data persists between file loads");

# Test runs too fast for the time to be different
set_relative_time(10);
$netkan->inflated;
$netkan->indexed;
$netkan->checked;
isnt($netkan->last_inflated, $inflated, "Last inflated changes value");
isnt($netkan->last_indexed, $indexed, "Last indexed changes value");
isnt($netkan->last_checked, $checked, "Last checked changes value");

$netkan->failure("Test");
is($netkan->last_error, "Test", "Last error set correctly");
is($netkan->failed, 1, "Failed set correctly");

$netkan->success;
is($netkan->last_error, undef, "Last cleared correctly");
is($netkan->failed, 0, "Failed set correctly");

$test->cleanup;

done_testing();
