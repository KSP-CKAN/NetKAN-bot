#!/usr/bin/env perl
use lib './t/lib/';

use strict;
use Dancer2;
use App::KSP_CKAN::Test::IA;

my $DEBUG = $ENV{KSP_CKAN_DEBUG} || 0;

# Debug/Dev
if ($DEBUG) {
  set logger => 'console';
  set log => 'core';
}

# Setting it in the config file didn't appear to work.
# Not sure why, normally would use plackup, but unnecessary
# here.
set port => 3001;

dance;
