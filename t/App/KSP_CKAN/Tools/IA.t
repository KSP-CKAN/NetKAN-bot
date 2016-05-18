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
use App::KSP_CKAN::Metadata::Ckan;

# Setup our environment
my $test = App::KSP_CKAN::Test->new();
$test->create_config;

use_ok("App::KSP_CKAN::Tools::IA");

my $config = App::KSP_CKAN::Tools::Config->new(
  file => $test->tmp."/.ksp-ckan",
  );

my $ia = App::KSP_CKAN::Tools::IA->new( 
  config => $config, 
  collection  => "test_collection",
);

isa_ok($ia->_ua, "LWP::UserAgent");
is(
  $ia->_ua->{def_headers}{authorization}, 
  'LOW 12345678:87654321',
  "Authorization header set",
);

subtest 'single value' => sub {
  my ($header, $value) = $ia->_archive_header( "collection", "test" );
  is( $header, "x-archive-meta-collection",
    "Single header name generated corerctly",
  );
  is( $value, "test",
    "Single header value generated corerctly",
  );
};

subtest 'single value as array' => sub {
  my @array = "test";
  my ($header, $value) = $ia->_archive_header( "collection", \@array );
  is( $header, "x-archive-meta-collection",
    "Single header name generated corerctly",
  );
  is( $value, "test",
    "Single header value generated corerctly",
  );
};

subtest 'multi value as array' => sub {
  my @values = qw( test1 test2 test3 );
  my @expected = qw(
    x-archive-meta01-creator
    test1
    x-archive-meta02-creator
    test2
    x-archive-meta03-creator
    test3
  );
  my @result = $ia->_archive_header( "creator", \@values );
  is_deeply(
    \@result, \@expected, "Multi value header returned correctly",
  );
};

$test->create_ckan(
  file => $test->tmp."/upload.ckan", 
  random => 0,
  license => '[ "CC-BY-NC-SA", "GPL-2.0" ]',
);
my $ckan = App::KSP_CKAN::Metadata::Ckan->new( file => $test->tmp."/upload.ckan" );

subtest '_metadata_headers' => sub {
  my $metadata_headers = $ia->_metadata_headers( $test->tmp."/test.zip", $ckan );
  
  isa_ok($metadata_headers, 'HTTP::Headers');
  is($metadata_headers->{'x-archive-meta-title'}, 'Example KAN - 1.0.0.1', "Title header generated");
  is($metadata_headers->{'x-archive-meta-creator'}, 'Techman83', "Creator header generated");
  is($metadata_headers->{'x-archive-meta-mediatype'}, 'software', "Mediatype header generated");
  is($metadata_headers->{'content-type'}, 'application/zip', "Content type header generated");
  is($metadata_headers->{'x-archive-meta-collection'}, 'test_collection', "Collection header generated");
  is(
    $metadata_headers->{'x-archive-meta-description'},
    'It\'s a random example!<br><br>Homepage: <a href="https://example.com/homepage">https://example.com/homepage</a><br>Repository: <a href="https://example.com/repository">https://example.com/repository</a><br>License(s): CC-BY-NC-SA GPL-2.0',
    "Description header generated",
  );
  is($metadata_headers->{'x-archive-meta-subject'}, 'ksp; kerbal space program; mod', "Subject header generated");
  is(
    $metadata_headers->{'x-archive-meta01-licenseurl'}, 
    'http://creativecommons.org/licenses/by-nc-sa/1.0/',
    "CC-BY-NC-SA License header added",
  );
  is(
    $metadata_headers->{'x-archive-meta02-licenseurl'}, 
    'http://www.gnu.org/licenses/old-licenses/gpl-2.0.en.html',
    "GPL-2.0 License header added",
  );
};

my $tester = App::KSP_CKAN::Cached->new( test_config => $config, tmp => $test->tmp );

$tester->test_live(\&iaS3_testing, 1);
$tester->test_cached(\&iaS3_testing, 1);

sub iaS3_testing {
  my ($ia,$tmp,$message) = @_;
  my $ckan = App::KSP_CKAN::Metadata::Ckan->new( file => $tmp."/upload.ckan" );

  subtest 'files' => sub {
    my $file = $tmp."/data/test.zip";
    is(
      $ia->_upload_uri($ckan),
      $ia->iaS3uri."/ExampleKAN-1.0.0.1/1A2B3C4D-ExampleKAN-1.0.0.1.zip",
      "URI produced correctly",
    );
  
    my $put = $ia->_put_request(
      file => $file,
      headers => $ia->_metadata_headers( $file, $ckan ),
      uri => $ia->_upload_uri($ckan)
    );
    isa_ok($put, "HTTP::Request", "\$put is a 'HTTP::Request' object");
    is($put->{_method}, "PUT", "Method 'PUT' set correctly");
    is( 
      $put->{_uri},
      $ia->iaS3uri.'/ExampleKAN-1.0.0.1/1A2B3C4D-ExampleKAN-1.0.0.1.zip',
      "Uri in put correct",
    );
    isa_ok($put->{_headers}, "HTTP::Headers", "Headers are an 'HTTP::Headers' object");
    is(
      $ia->put_ckan( ckan => $ckan, file => $file),
      1, "File uploaded successfully"
    );
    is(
      $ia->ckan_mirrored( ckan => $ckan ),
      1, "Ckan is mirrored"
    );
    is(
      $ia->check_overload,
      0, "IA is not overloaded"
    );

    # TODO: If we implement live testing, these will fail.
    #       we can add a header to our request to simulate
    #       a failure.
    #
    #       Something like this:
    #       $ia->_ua->default_headers->push_header( 'x-archive-simulate-error' => 'SlowDown' );
    is(
      $ia->put_ckan( ckan => $ckan, file => $file),
      0, "File upload returned failure correctly"
    );
    is(
      $ia->ckan_mirrored( ckan => $ckan ),
      0, "Ckan is not mirrored"
    );
    is(
      $ia->check_overload,
      1, "IA is overloaded"
    );
  };
}

# Cleanup after ourselves
$test->cleanup;

done_testing();
__END__
