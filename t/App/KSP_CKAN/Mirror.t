#!/usr/bin/env perl -w

use lib 't/lib/';

use v5.010;
use strict;
use warnings;
use Test::Most;
use Test::Warnings;
use File::Copy qw(copy);
use App::KSP_CKAN::Test;
use App::KSP_CKAN::Cached;
use App::KSP_CKAN::Metadata::Ckan;
use App::KSP_CKAN::Tools::Config;

# Setup our environment
my $test = App::KSP_CKAN::Test->new();
$test->create_config;

use_ok("App::KSP_CKAN::Mirror");

my $config = App::KSP_CKAN::Tools::Config->new(
  file => $test->tmp."/.ksp-ckan",
  );

$test->create_ckan(
  file      => $test->tmp."/upload.ckan", 
  random    => 0,
  license   => '[ "CC-BY-NC-SA", "GPL-2.0" ]',
  download  => 'http://localhost:3001/test.zip',
  sha256    => '4C2BC8312BF1DDE1275A65E09C5D64482C069C7DB2150A4457FA16E06B827C4F',
);

$test->create_ckan(
  file        => $test->tmp."/fail.ckan", 
  random      => 0,
  license     => '[ "CC-BY-NC-SA", "GPL-2.0" ]',
  download    => 'http://localhost:3001/fail-test.zip',
);

$test->create_ckan(
  file        => $test->tmp."/upload2.ckan", 
  random      => 0,
  identifier  => "ExampleTest",
  license     => '[ "CC-BY-NC-SA", "GPL-2.0" ]',
  download    => 'http://localhost:3001/fail-test.zip',
  sha256      => '4C2BC8312BF1DDE1275A65E09C5D64482C069C7DB2150A4457FA16E06B827C4F',
);

my $tester = App::KSP_CKAN::Cached->new( 
  test_config   => $config, 
  tmp           => $test->tmp,
  package       => 'Mirror', 
);

$tester->test_live(\&iaS3_testing, 1);
$tester->test_cached(\&iaS3_testing, 1);

sub iaS3_testing {
  my ($mirror,$tmp,$message) = @_;

  isa($mirror, "App::KSP_CKAN::Mirror");
  dies_ok 
    { $mirror->_load_ckan($tmp."doesnt.exist") }
    "'_load_ckan' requires a real file";

  subtest 'Check Cached' => sub {
    my $cache = $mirror->config->cache;
    is(
      $mirror->_check_cached(123456), 0,
      "'_check_cached' returns '0' when file is not found in cache",
    );
    copy($tmp."/data/test.zip", $cache."/123456-test.zip");
    is(
      $mirror->_check_cached(123456), $cache."/123456-test.zip",
      "'_check_cached' returns filename and path when file found in cache",
    );
  };

  subtest 'Check Cached' => sub {
    my $ckan = App::KSP_CKAN::Metadata::Ckan->new( file => $tmp."/upload.ckan");
    my $fail = App::KSP_CKAN::Metadata::Ckan->new( file => $tmp."/fail.ckan");
    my $cache = $mirror->config->cache;

    is(
      $mirror->_check_file($tmp."/".$ckan->mirror_filename, $ckan), 1,
      "'_check_file' returns '1' when file is downloaded and sha256 matches",
    );
    is(
      $mirror->_check_file($tmp."/".$fail->mirror_filename, $fail), 0,
      "'_check_file' returns '0' when file fails to download",
    );
    copy($tmp."/data/CKAN-meta/README.md", $cache."/".$ckan->url_hash."-test.zip");
    is(
      $mirror->_check_file($tmp."/".$ckan->mirror_filename, $ckan), 0,
      "'_check_file' returns '0' when file exists but sha256 fails to match",
    );
  
  };
    
  subtest 'Upload CKAN' => sub {
    my $ckan = App::KSP_CKAN::Metadata::Ckan->new( file => $tmp."/upload2.ckan");
    my $cache = $mirror->config->cache;
    # TODO: If we implement live testing, these will fail.
    #       we can add a header to our request to simulate
    #       a failure.
    #
    #       Something like this:
    #       $ia->_ua->default_headers->push_header( 'x-archive-simulate-error' => 'SlowDown' );
    is(
      $mirror->upload_ckan( $tmp."/upload.ckan" ),
      1, "File already mirrored"
    );    
    is(
      $mirror->upload_ckan( $tmp."/upload.ckan" ),
      0, "Archive overloaded while attempting to uploaded"
    );
    copy($tmp."/data/test.zip", $cache."/".$ckan->url_hash."-test.zip");
    is(
      $mirror->upload_ckan( $tmp."/upload2.ckan" ),
      1, "Uploaded to archive successfully"
    );
    is(
      $mirror->_check_overload,
      1, "Archive is overloaded"
    );
    is(
      $mirror->_check_overload,
      0, "Archive not overloaded"
    );
  };
}


# Cleanup after ourselves
$test->cleanup;

done_testing();
__END__
