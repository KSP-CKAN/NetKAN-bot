#!/usr/bin/env perl -w

use lib 't/lib/';

use strict;
use warnings;
use Test::Most;
use Test::Warnings;
use App::KSP_CKAN::Test;

# Setup our environment
my $test = App::KSP_CKAN::Test->new();
$test->create_netkan( file => $test->tmp."/package.netkan" );

use_ok("App::KSP_CKAN::Metadata::NetKAN");

my $package = App::KSP_CKAN::Metadata::NetKAN->new( file => $test->tmp."/package.netkan");
my $optional = App::KSP_CKAN::Metadata::NetKAN->new( 
  file    => $test->tmp."/package.netkan",
  vref    => undef,
  staging => 1,
);
subtest 'package' => sub {  
  is($package->identifier, 'DogeCoinFlag', "Package identifier successfully retrieved");
  is($package->name, "Example NetKAN", "Name successfully retrieved");
  is($package->license, "CC-BY", "License successfully retrieved");
  is($package->kref, "#/ckan/github/pjf/DogeCoinFlag", "'kref' successfully retrieved");
  is($package->vref, "#/ckan/ksp-avc", "'vref' successfully retrieved");
  is($package->staging, 0, "staging false if doesn't exist");
};

subtest 'optional' => sub {  
  is($optional->vref, undef, "'vref' undef when not present retrieved");
  is($optional->staging, 1, "staging retrieved successfully");
};
# Cleanup after ourselves
$test->cleanup;

done_testing();
__END__
