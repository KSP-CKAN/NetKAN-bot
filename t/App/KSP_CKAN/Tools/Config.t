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
is($config->GH_token, "123456789", "GH_token loaded from config");
is($config->working, $test->_tmp, "working loaded from config");

$test->create_config( optional => 0 );
$config = App::KSP_CKAN::Tools::Config->new(
  file => $test->tmp."/.ksp-ckan",
);

is($config->GH_token, 0, "GH_token returns false");
is($config->working, $ENV{HOME}."/CKAN-working", "working default generated");

done_testing();
