#!/usr/bin/env perl -w

use lib 't/lib/';

use v5.010;
use strict;
use warnings;
use Test::Most;
use Test::Warnings;
use App::KSP_CKAN::Test;
use App::KSP_CKAN::Cached;
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

  subtest 'Upload CKAN' => sub {
    dies_ok 
      { $mirror->_load_ckan($tmp."doesnt.exist") }
      "'_load_ckan' requires a real file";
      
    is(
      $mirror->upload_ckan( $tmp."/upload.ckan" ),
      1, "File uploaded successfully"
    );

    # TODO: If we implement live testing, these will fail.
    #       we can add a header to our request to simulate
    #       a failure.
    #
    #       Something like this:
    #       $ia->_ua->default_headers->push_header( 'x-archive-simulate-error' => 'SlowDown' );
    
    # TODO: Not 100% happy with how the lib operates in general,
    #       but we can catch deaths until it's improved.
    dies_ok 
      { $mirror->upload_ckan( $tmp."/upload.ckan" ) }
      "'Dies when expected'"
  };
}

# Cleanup after ourselves
$test->cleanup;

done_testing();
__END__
