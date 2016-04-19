#!/usr/bin/env perl -w

use lib 't/lib/';

use v5.010;
use strict;
use warnings;
use Test::Most;
use Test::Warnings;
use App::KSP_CKAN::Test;
use App::KSP_CKAN::Tools::Config;
use App::KSP_CKAN::Metadata::Ckan;



use Data::Dumper;



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

subtest 'put_ckan' => sub {
  my $file = $test->tmp."/data/test.zip";
  is(
    $ia->_uri($ckan),
    "https://s3.us.archive.org/ExampleKAN-1.0.0.1/74770739-ExampleKAN-1.0.0.1.zip",
    "URI produced correctly",
  );

  my $put = $ia->_put_request(
    file => $file,
    headers => $ia->_metadata_headers( $file, $ckan ),
    uri => $ia->_uri($ckan)
  );
  isa_ok($put, "HTTP::Request", "\$put is a 'HTTP::Request' object");
  is($put->{_method}, "PUT", "Method 'PUT' set correctly");
  is( 
    $put->{_uri},
    'https://s3.us.archive.org/ExampleKAN-1.0.0.1/74770739-ExampleKAN-1.0.0.1.zip',
    "Uri in put correct",
  );
  isa_ok($put->{_headers}, "HTTP::Headers", "Headers are an 'HTTP::Headers' object");

};

# Cleanup after ourselves
$test->cleanup;

done_testing();
__END__