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
$test->create_ckan( $test->tmp."/package.ckan" );
$test->create_ckan( $test->tmp."/metapackage.ckan",1 , "metapackage" );

subtest 'package' => sub {
  my $package = App::KSP_CKAN::Metadata::Ckan->new( file => $test->tmp."/package.ckan");
  
  is($package->identifier, 'ExampleKAN', "Package identifier successfully retrieved");
  is($package->kind, 'package', "Kind successfully retrieved");
  is($package->download, 'https://example.com/example.zip', "Download url successfully retrieved");
  is($package->is_package, 1, "This CKAN is a package");
};

subtest 'metapackage' => sub {
  my $metapackage = App::KSP_CKAN::Metadata::Ckan->new( file => $test->tmp."/metapackage.ckan");
  
  is($metapackage->identifier, 'ExampleKAN', "Package identifier successfully retrieved");
  is($metapackage->kind, 'metapackage', "Kind successfully retrieved");
  is($metapackage->download, '0', "No download url");
  is($metapackage->is_package, '0', "This CKAN is not a package");
};

# Cleanup after ourselves
$test->cleanup;

done_testing();
__END__
