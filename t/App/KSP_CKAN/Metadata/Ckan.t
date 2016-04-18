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
$test->create_ckan( file => $test->tmp."/package.ckan", random => 0 );
$test->create_ckan( file => $test->tmp."/metapackage.ckan", kind => "metapackage" );
$test->create_ckan( file => $test->tmp."/no_mirror.ckan", license => '"restricted"', download => "");
$test->create_ckan( file => $test->tmp."/hash.ckan", download => "https://github.com/pjf/DogeCoinFlag/releases/download/v1.02/DogeCoinFlag-1.02.zip",  license => '[ "restricted", "GPL-2.0" ]' );

my $package = App::KSP_CKAN::Metadata::Ckan->new( file => $test->tmp."/package.ckan");
subtest 'package' => sub {  
  is($package->identifier, 'ExampleKAN', "Package identifier successfully retrieved");
  is($package->kind, 'package', "Kind successfully retrieved");
  is($package->download, 'https://example.com/example.zip', "Download url successfully retrieved");
  is($package->is_package, 1, "This CKAN is a package");
};

subtest 'fields' => sub {
  is($package->homepage, 'https://example.com/homepage', "Homepage url successfully retrieved");
  is($package->repository, 'https://example.com/repository', "Repository url successfully retrieved");
  is($package->abstract, "It's a random example!", "Abstract successfully retrieved");
  is($package->name, "Example KAN", "Name successfully retrieved");
  is($package->license, "CC-BY-NC-SA", "License successfully retrieved");
  is($package->version, "1.0.0.1", "Version successfully retrieved");
};

my $metapackage = App::KSP_CKAN::Metadata::Ckan->new( file => $test->tmp."/metapackage.ckan");
subtest 'metapackage' => sub { 
  is($metapackage->identifier, 'ExampleKAN', "Package identifier successfully retrieved");
  is($metapackage->kind, 'metapackage', "Kind successfully retrieved");
  is($metapackage->download, '0', "No download url");
  is($metapackage->is_package, '0', "This CKAN is not a package");
};

my $no_mirror = App::KSP_CKAN::Metadata::Ckan->new( file => $test->tmp."/no_mirror.ckan" );
my $hash = App::KSP_CKAN::Metadata::Ckan->new( file => $test->tmp."/hash.ckan" );
subtest 'mirror' => sub {
  # Can mirror
  is($package->can_mirror, 1, "Package can be mirrored");
  is($metapackage->can_mirror, 0, "Meta package can't be mirrored");
  is($hash->can_mirror, 1, "If multi license ckan has a license which can be mirrored");
  is($no_mirror->can_mirror, 0, "License not explicitly listed for mirroring");
  is($no_mirror->download, 0, "0 returned for blank download link");
  
  # Hashes
  is($no_mirror->url_hash, 0, "0 hash returned for blank download link");
  is($metapackage->url_hash, 0, "0 hash returned for metapackage");
  is($hash->url_hash, "6F8BEBCB", "Hash '".$hash->url_hash."' calculated correctly");
  
  # Filenames
  is(
    $package->mirror_filename, 
    "74770739-ExampleKAN-1.0.0.1.zip", 
    "Filename '".$package->mirror_filename."' produced correctly");
  is(
    $hash->mirror_filename, 
    "6F8BEBCB-ExampleKAN-1.0.0.1.zip", 
    "Filename '".$hash->mirror_filename."' produced correctly");
};

# Cleanup after ourselves
$test->cleanup;

done_testing();
__END__
