#!/usr/bin/env perl -w

use strict;
use warnings;
use Test::Most;
use Test::Warnings;
use File::Path qw(remove_tree mkpath);
use File::Spec 'tmpdir';

# Setup our test environment
our $tmp = File::Spec->tmpdir();
our $testpath = "$tmp/KSP_CKAN-test";
mkpath($testpath);

use_ok("App::KSP_CKAN::Http");

my $http = App::KSP_CKAN::Http->new();

subtest 'mirror' => sub {
  $http->mirror( url => "http://ci.ksp-ckan.org:8080/job/NetKAN/lastSuccessfulBuild/artifact/netkan.exe", path => "$testpath/netkan.exe");
  is(-e "$testpath/netkan.exe", 1, "Mirrored successfully");
  isnt(-X "$testpath/netkan.exe", 1, "File not executable");
  $http->mirror( url => "https://raw.githubusercontent.com/KSP-CKAN/CKAN/master/bin/ckan-validate.py", path => "$testpath/ckan-validate.py", exe => 1);
  is(-X "$testpath/ckan-validate.py", 1, "File executable");
};

# Cleanup after ourselves
if ( -d $testpath ) {
  remove_tree($testpath);
}


done_testing();
