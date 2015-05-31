#!/usr/bin/env perl -w

use lib 't/lib/';

use strict;
use warnings;
use Test::Most;
use Test::Warnings;
use App::KSP_CKAN::Test;

use_ok("App::KSP_CKAN::Tools::NetKAN");

done_testing();
__END__
