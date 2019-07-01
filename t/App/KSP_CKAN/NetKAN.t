#!/usr/bin/env perl -w

use lib 't/lib/';

use strict;
use warnings;
use v5.010;
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
$test->create_config();
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

  # TODO: Fix these tests in travis
  my $why = "These tests pass locally, but not within Travis";
  TODO: {
    local $TODO = $why if $ENV{TRAVIS};
    ok($#files != -1, "We committed files to master");
  }

  my $git = App::KSP_CKAN::Tools::Git->new(
    remote => $config->CKAN_meta,
    local => $config->working,
    clean => 1,
  );

  my $identifier = "DogeCoinFlagStaged";
  is($git->current_branch, "master", "We started on the master branch");
  ok(! -d "CKAN-meta/$identifier", "Staged netkan not committed to master");

  $git->checkout_branch($identifier);
  is($git->current_branch, $identifier, "We are on the $identifier branch");
  my @id_branch = glob( "./CKAN-meta/$identifier/*.ckan" );

  TODO: {
    local $TODO = $why if $ENV{TRAVIS};
    ok($#id_branch != -1, "We committed files to $identifier");
  }

  foreach my $file (@id_branch) {
    ok($file =~ /$identifier-v\d.\d\d.ckan/, "Committed to $identifier");
  }
}

ok( -d $config->cache, "NetKAN cache path set correctly" );

$test->cleanup;

done_testing();
__END__
