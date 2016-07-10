#!/usr/bin/env perl -w

use lib 't/lib/';

use strict;
use warnings;
use v5.010;
use Test::Most;
use Test::Warnings ':no_end_test';
use Digest::file qw(digest_file_hex);
use App::KSP_CKAN::Test;
use App::KSP_CKAN::Tools::Http;
use App::KSP_CKAN::Tools::Git;
use App::KSP_CKAN::Tools::Config;
use App::KSP_CKAN::Status;

## Setup our environment
my $test = App::KSP_CKAN::Test->new();

# Config
$test->create_config(nogh => 1);
my $config = App::KSP_CKAN::Tools::Config->new(
  file => $test->tmp."/.ksp-ckan",
);

my $status = App::KSP_CKAN::Status->new(
  config => $config,
);

# CKAN-meta
$test->create_repo("CKAN-meta");
my $ckan = App::KSP_CKAN::Tools::Git->new(
  remote => $test->tmp."/data/CKAN-meta",
  local => $config->working,
  clean => 1,
);
$ckan->pull;

# Netkan
$test->create_repo("NetKAN");
my $netkan_git = App::KSP_CKAN::Tools::Git->new(
  remote => $test->tmp."/data/NetKAN",
  local => $config->working,
  clean => 1,
);
$netkan_git->pull;

# netkan.exe
my $http = App::KSP_CKAN::Tools::Http->new();
$http->mirror( url => $config->netkan_exe, path => $test->tmp."/netkan.exe", exe => 1 );
$http->mirror( url => $config->ckan_validate, path => $config->working."/ckan-validate.py", exe => 1 );
$http->mirror( url => $config->ckan_schema, path => $config->working."/CKAN.schema" );

use_ok("App::KSP_CKAN::Tools::NetKAN");
my $netkan = App::KSP_CKAN::Tools::NetKAN->new(
  config    => $config, 
  netkan    => $test->tmp."/netkan.exe",
  cache     => $test->tmp."/cache", # TODO: Test default cache location
  ckan_meta => $ckan,
  status    => $status,
  file      => $config->working."/NetKAN/NetKAN/DogeCoinFlag.netkan"
);

# TODO: Fix this on travis.
TODO: {
   todo_skip "These tests are broken on travis", 7 if $ENV{TRAVIS};
  
  my $md5 = $netkan->_output_md5;
  isnt($md5, undef, "MD5 '$md5' generated");
  is( $netkan->inflate, 0, "Return success correctly" );
  isnt($md5, $netkan->_output_md5, "MD5 Hash updated when new file generated");

  my @files = glob($config->working."/CKAN-meta/DogeCoinFlag/*");
  is( -e $files[0], 1, "Meta Data inflated" );
  is( $files[0], $netkan->_newest_file, "'".$netkan->_newest_file."' returned as the newest file");
  
  $netkan = App::KSP_CKAN::Tools::NetKAN->new( 
    config    => $config, 
    netkan    => $test->tmp."/netkan.exe",
    cache     => $test->tmp."/cache",
    ckan_meta => $ckan,
    status    => $status,
    file      => $config->working."/NetKAN/NetKAN/DogeCoinFlag-broken.netkan"
  );
  isnt( $netkan->inflate, 0, "Return failure correctly" );

  subtest 'Status Setting' => sub {
    is($status->status->{'DogeCoinFlag-broken'}{last_error}, "JSON deserialization error", "'last_error' set on failure");
    is($status->status->{'DogeCoinFlag-broken'}{failed}, 1, "'failed' true on failure");
    is($status->status->{'DogeCoinFlag-broken'}{last_indexed}, undef, "'last_index' undef when no successful indexing has ever occured");
    is($status->status->{'DogeCoinFlag'}{last_error}, undef, "'last_error' undef on success");
    is($status->status->{'DogeCoinFlag'}{failed}, 0, "'failed' false on succes");
  };

  ok( -d $test->tmp."/cache", "NetKAN Cache path set correctly");
}

# Test file validation
subtest 'File Validation' => sub {
  $test->create_ckan( file => $config->working."/CKAN-meta/test_file.ckan" );
  $netkan->_commit( $config->working."/CKAN-meta/test_file.ckan" );
  is($netkan->ckan_meta->changed(origin => 0), 0, "Commit validated file successful");
  $netkan->ckan_meta->push;
  is($netkan->ckan_meta->changed, 0, "Changes pushed repository" );
  $test->create_ckan( file => $config->working."/CKAN-meta/test_file2.ckan", valid => 0 );
  $netkan->_commit( $config->working."/CKAN-meta/test_file2.ckan" );
  is( $netkan->ckan_meta->changed, 0, "broken metadata was not committed" );
  $netkan->ckan_meta->add;
  is( $netkan->ckan_meta->changed, 0, "broken metadata gets removed" );
};

# Test staged commits
subtest 'Staged Commits' => sub {
  # Setup
  my $staged = App::KSP_CKAN::Tools::NetKAN->new(
    config    => $config, 
    netkan    => $test->tmp."/netkan.exe",
    cache     => $test->tmp."/cache", # TODO: Test default cache location
    ckan_meta => $ckan,
    status    => $status,
    file      => $config->working."/NetKAN/NetKAN/DogeCoinFlagStaged.netkan"
  );
  my $file = $config->working."/CKAN-meta/staged.ckan";
  $test->create_ckan( file => $file );
  my $hash = digest_file_hex( $file, "SHA-1" );
  my $identifier = "DogeCoinFlagStaged";

  # Commit
  is($ckan->current_branch, "master", "We started on the master branch");
  $staged->_commit( $file );
  is($ckan->current_branch, "master", "We were returned to the master branch");
  isnt(-e $file, 1, "Our staged file wasn't commited to master");

  # Staged branch
  $ckan->checkout_branch("staging");
  is($ckan->current_branch, "staging", "We are on the staging branch");
  $ckan->_hard_clean;
  is(digest_file_hex( $file, "SHA-1" ), $hash, "Our staging branch was commited to");

  # Identifier branch
  $ckan->checkout_branch($identifier);
  is($ckan->current_branch, $identifier, "We are on the $identifier branch");
  $ckan->_hard_clean;
  is(digest_file_hex( $file, "SHA-1" ), $hash, "Our $identifier branch was commited to");

  $ckan->checkout_branch($ckan->branch);
};

# Test Error Parsing
subtest 'Error Parsing' => sub {
  is (
    $netkan->_parse_error("8194 [1] FATAL CKAN.NetKAN.Program (null) - Could not find CrowdSourcedScience directory in zipfile to install"),
    "Could not find CrowdSourcedScience directory in zipfile to install",
    "Zipfile Error Parsing Success"
  );
  
  is (
    $netkan->_parse_error("2142 [1] FATAL CKAN.NetKAN.Program (null) - JSON deserialization error"),
    "JSON deserialization error",
    "JSON Error Parsing Success"
  );
  
  my $error = <<EOF;
Unhandled Exception:
CKAN.Kraken: Cannot find remote and ID in kref: http://dl.dropboxusercontent.com/u/7121093/ksp-mods/KSP%5B1.0.2%5DWasdEditorCamera%5BMay20%5D.zip
  at CKAN.NetKAN.MainClass.FindRemote (Newtonsoft.Json.Linq.JObject json) [0x00000] in <filename unknown>:0 
  at CKAN.NetKAN.MainClass.Main (System.String[] args) [0x00000] in <filename unknown>:0 
[ERROR] FATAL UNHANDLED EXCEPTION: CKAN.Kraken: Cannot find remote and ID in kref: http://dl.dropboxusercontent.com/u/7121093/ksp-mods/KSP%5B1.0.2%5DWasdEditorCamera%5BMay20%5D.zip
  at CKAN.NetKAN.MainClass.FindRemote (Newtonsoft.Json.Linq.JObject json) [0x00000] in <filename unknown>:0 
  at CKAN.NetKAN.MainClass.Main (System.String[] args) [0x00000] in <filename unknown>:0 
EOF
  
  is (
    $netkan->_parse_error( $error ),
    "FATAL UNHANDLED EXCEPTION: CKAN.Kraken: Cannot find remote and ID in kref: http://dl.dropboxusercontent.com/u/7121093/ksp-mods/KSP%5B1.0.2%5DWasdEditorCamera%5BMay20%5D.zip",
    "Generic Error Parsing Success"
  );
  
  is (
    $netkan->_parse_error("791 [1] WARN CKAN.Curl (null) - Curl environment not pre-initialised, performing non-threadsafe init.\n8194 [1] FATAL CKAN.NetKAN.Program (null) - Could not find CrowdSourcedScience directory in zipfile to install"),
    "Could not find CrowdSourcedScience directory in zipfile to install",
    "Mutliline Fatal Success"
  );
  
  is (
    $netkan->_parse_error( "Cookie Cat Crystal Combo powers... ACTIVATE" ),
    "Error wasn't parsable",
    "Receive 'Error wasn't parsable' when none parsed"
  );
};

# Cleanup after ourselves
$test->cleanup;

done_testing();
__END__
