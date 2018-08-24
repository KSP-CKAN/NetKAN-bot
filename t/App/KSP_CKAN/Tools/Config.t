#!/usr/bin/env perl -w

use lib 't/lib/';

use strict;
use warnings;
use Test::Most;
use Test::Warnings;
use App::KSP_CKAN::Test;

# Setup our environment
my $test = App::KSP_CKAN::Test->new();
$test->create_config;

use_ok("App::KSP_CKAN::Tools::Config");

my $config = App::KSP_CKAN::Tools::Config->new(
  file => $test->tmp."/.ksp-ckan",
);

is($config->CKAN_meta, $test->_tmp."/data/CKAN-meta", "NetKAN loaded from config");
is($config->NetKAN, $test->_tmp."/data/NetKAN", "NetKAN loaded from config");
my $token = $ENV{GH_token} // '123456789';
is($config->GH_token, $token, "GH_token loaded from config");
is($config->working, $test->_tmp."/working", "working loaded from config");
is(-d $config->working, 1, "working was automatically created");
is($config->cache, $test->_tmp."/cache", "cache loaded from config");
is(-d $config->cache, 1, "cache was automatically created");
is($config->netkan_exe, "https://ckan-travis.s3.amazonaws.com/netkan.exe", "netkan_exe loaded from config");
is($config->ckan_validate, "https://raw.githubusercontent.com/KSP-CKAN/CKAN/master/bin/ckan-validate.py", "ckan_validate loaded from config");
is($config->ckan_schema, "https://raw.githubusercontent.com/KSP-CKAN/CKAN/master/CKAN.schema", "ckan_schema loaded from config");
is($config->IA_access, "12345678", "IA_access loaded from config");
is($config->IA_secret, "87654321", "IA_secret loaded from config");
is($config->IA_collection, "collection", "IA_collection loaded from config");
is($config->debugging, 0, "debug disabled");

$test->create_config( optional => 0 );
$config = App::KSP_CKAN::Tools::Config->new(
  file => $test->tmp."/.ksp-ckan",
);

is($config->GH_token, 0, "GH_token returns false");
is($config->working, $ENV{HOME}."/CKAN-working", "working default generated");
is($config->cache, $ENV{HOME}."/CKAN-working/cache", "cache default generated");
is($config->IA_collection, "test_collection", "IA_collection default generated");

$test->cleanup;

done_testing();
