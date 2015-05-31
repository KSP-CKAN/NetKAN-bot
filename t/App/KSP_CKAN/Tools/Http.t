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
  $http->mirror( url => "http://ci.ksp-ckan.org:8080/job/NetKAN/lastSuccessfulBuild/artifact/netkan.exe", path => $test->tmp."/netkan.exe");
  is(-e $test->tmp."/netkan.exe", 1, "Mirrored successfully");
  isnt(-X $test->tmp."/netkan.exe", 1, "File not executable");
  $http->mirror( url => "https://raw.githubusercontent.com/KSP-CKAN/CKAN/master/bin/ckan-validate.py", path => $test->tmp."/ckan-validate.py", exe => 1);
  is(-X $test->tmp."/ckan-validate.py", 1, "File executable");
};

$test->cleanup;

done_testing();
