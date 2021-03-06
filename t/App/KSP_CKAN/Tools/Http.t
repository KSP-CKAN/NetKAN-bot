#!/usr/bin/env perl -w

use lib 't/lib/';

use strict;
use warnings;
use Test::Most;
use Test::Warnings;
use App::KSP_CKAN::Test;

# Setup our environment
my $test = App::KSP_CKAN::Test->new();
$test->create_tmp;

use_ok("App::KSP_CKAN::Tools::Http");

my $http = App::KSP_CKAN::Tools::Http->new();

subtest 'mirror' => sub {
  $http->mirror( url => "https://ckan-travis.s3.amazonaws.com/netkan.exe", path => $test->tmp."/netkan.exe");
  is(-e $test->tmp."/netkan.exe", 1, "Mirrored successfully");
  isnt(-X $test->tmp."/netkan.exe", 1, "File not executable");
};

$test->cleanup;

done_testing();
