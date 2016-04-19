#!/usr/bin/env perl -w

use lib 't/lib/';

use strict;
use warnings;
use Test::Most;
use Test::Warnings;
use File::chdir;
use App::KSP_CKAN::Test;
use App::KSP_CKAN::Test::Validate;
use App::KSP_CKAN::Tools::Config;
use App::KSP_CKAN::Tools::Git;

## Setup our environment
my $test = App::KSP_CKAN::Test->new();
$test->create_repo("CKAN-meta-validate");

# Config
$test->create_config;
my $config = App::KSP_CKAN::Tools::Config->new(
  file => $test->tmp."/.ksp-ckan",
);

use_ok("App::KSP_CKAN::Test::Validate");
my $validate = App::KSP_CKAN::Test::Validate->new( 
  config => $config,
);

my $git = App::KSP_CKAN::Tools::Git->new(
  remote => $test->_tmp."/data/CKAN-meta-validate",
  local => $config->working,
  clean => 1,
);

$git->_git;
$validate->_mirror_files;
$validate->validate($config->working."/CKAN-meta-validate/DogeCoinFlag/DogeCoinFlag-v1.02.ckan");

is(
  $validate->validate($config->working."/CKAN-meta-validate/DogeCoinFlag/DogeCoinFlag-v1.02.ckan"),
  0,
  "DogeCoinFlag-v1.02.ckan Valid",
);
isnt(
  $validate->validate($config->working."/CKAN-meta-validate/DogeCoinFlag-invalid/DogeCoinFlag-v1.02.ckan"),
  0,
  "DogeCoinFlag-v1.02.ckan Invalid",
);
   
$test->cleanup;

done_testing();
__END__
