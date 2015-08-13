#!/usr/bin/env perl -w

use strict;
use lib "t/lib";
use Test::More;
use App::KSP_CKAN::Test::Logger;
use App::KSP_CKAN::Tools::Config;
use App::KSP_CKAN::Test;

## Setup our environment
my $test = App::KSP_CKAN::Test->new();
$test->create_config;
my $config = App::KSP_CKAN::Tools::Config->new(
  file => $test->tmp."/.ksp-ckan",
);

#TODO: Add 'no_end_test' due to Double END Block issue
use Test::Warnings ':no_end_test';

my $logger = Test::App::KSP_CKAN::Logger->new(
  config => $config,
);

subtest 'Logger Instantiation' => sub {
  can_ok($logger, qw(
    log trace debug info warn error fatal
    is_trace is_debug is_info is_warn is_error is_fatal
    logexit logwarn error_warn logdie error_die
    logcarp logcluck logcroak logconfess
  ));
};

$logger->info("Log test");

ok(-e $config->working."/KSP_CKAN.log", "Log file created successfully");

$test->cleanup;

done_testing();
