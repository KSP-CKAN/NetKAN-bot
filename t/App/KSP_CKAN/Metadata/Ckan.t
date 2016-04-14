#!/usr/bin/env perl -w

use lib 't/lib/';

use strict;
use warnings;
use Test::Most;
use Test::Warnings;
use App::KSP_CKAN::Test;

# Setup our environment
my $test = App::KSP_CKAN::Test->new();

use_ok("App::KSP_CKAN::Metadata::Ckan");
$test->create_ckan( file => $test->tmp."/package.ckan" );
$test->create_ckan( file => $test->tmp."/metapackage.ckan", kind => "metapackage" );
$test->create_ckan( file => $test->tmp."/no_mirror.ckan", license => "restricted", download => "");
$test->create_ckan( file => $test->tmp."/hash.ckan", download => "https://github.com/pjf/DogeCoinFlag/releases/download/v1.02/DogeCoinFlag-1.02.zip" );

my $package = App::KSP_CKAN::Metadata::Ckan->new( file => $test->tmp."/package.ckan");
subtest 'package' => sub {  
  is($package->identifier, 'ExampleKAN', "Package identifier successfully retrieved");
  is($package->kind, 'package', "Kind successfully retrieved");
  is($package->download, 'https://example.com/example.zip', "Download url successfully retrieved");
  is($package->is_package, 1, "This CKAN is a package");
};

my $metapackage = App::KSP_CKAN::Metadata::Ckan->new( file => $test->tmp."/metapackage.ckan");
subtest 'metapackage' => sub { 
  is($metapackage->identifier, 'ExampleKAN', "Package identifier successfully retrieved");
  is($metapackage->kind, 'metapackage', "Kind successfully retrieved");
  is($metapackage->download, '0', "No download url");
  is($metapackage->is_package, '0', "This CKAN is not a package");
};

my $no_mirror = App::KSP_CKAN::Metadata::Ckan->new( file => $test->tmp."/no_mirror.ckan" );
my $hash = App::KSP_CKAN::Metadata::Ckan->new( file => $test->tmp."/hash.ckan");
subtest 'mirror' => sub {
  is($package->can_mirror, 1, "Package can be mirrored");
  is($metapackage->can_mirror, 0, "Meta package can't be mirrored");
  is($no_mirror->can_mirror, 0, "License not explicitly listed for mirroring");
  is($no_mirror->download, 0, "0 hash returned for blank download link");
  is($no_mirror->url_hash, 0, "0 hash returned for blank download link");
  is($metapackage->url_hash, 0, "0 hash returned for metapackage");
  is($hash->url_hash, "6F8BEBCB", "Hash calculated correctly");
};

# Cleanup after ourselves
$test->cleanup;

done_testing();
__END__
