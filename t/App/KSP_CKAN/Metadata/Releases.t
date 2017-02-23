#!/usr/bin/env perl -w

use lib 't/lib/';

use strict;
use warnings;
use Test::Most;
use Test::Warnings;
use App::KSP_CKAN::Test;

# Setup our environment
my $test = App::KSP_CKAN::Test->new();

use_ok("App::KSP_CKAN::Metadata::Releases");
$test->create_releases( file => $test->tmp."/releases.json" );

my $releases = App::KSP_CKAN::Metadata::Releases->new( file => $test->tmp."/releases.json" );
isa_ok( $releases, "App::KSP_CKAN::Metadata::Releases");

subtest 'version compare' => sub {
  is($releases->_compare_version("0.25.0", "1.0.0"), 0, "0.25.0 less than 1.0.0");
  is($releases->_compare_version("0.90.0", "1.2.0"), 0, "0.90.0 less than 1.2.0");
  is($releases->_compare_version("1.0.0", "0.25.0"), 1, "1.0.0 greater than 0.25.0");
  is($releases->_compare_version("1.1.0", "0.25.0"), 1, "1.1.0 greater than 0.25.0");
  is($releases->_compare_version("1.1.0", "0.90.0"), 1, "1.1.0 greater than 0.90.0");
  is($releases->_compare_version("1.0", "1.0.1"), 0, "1.0 less than to 1.0.1");
  is($releases->_compare_version("1.0.1", "1.0"), 1, "1.0.1 greater than 1.0");
  is($releases->_compare_version("1.1.1", "1.0"), 1, "1.1.1 greater than 1.0");
  is($releases->_compare_version("1.0", "1.1.1"), 0, "1.0 less than 1.1.1");
  is($releases->_compare_version("1.2", "1.1.1"), 1, "1.2 greater than 1.1.1");
  is($releases->_compare_version("1.2", "1.2.0"), 1, "1.2 equal to 1.2.0");
  is($releases->_compare_version("1.2.0", "1.2"), 1, "1.2.0 equal to 1.2");
  is($releases->_compare_version("1.1.0", "100.0.0"), 0, "1.1.0 less than 100.0.0");
};

subtest 'release bracket' => sub {
  is($releases->release("0.20.0"), 'legacy', "0.20.0 ends up in legacy");
  is($releases->release("0.90.0"), 'middle', "0.90.0 ends up in middle");
  is($releases->release("1.1.0"), 'current', "1.1.0 ends up in current");
  is($releases->release("1.3.0"), 'current', "1.3.0 ends up in current");
  is($releases->release("any"), 'current', "any ends up in current");
};

$test->cleanup;

done_testing();
