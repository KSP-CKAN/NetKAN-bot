#!/usr/bin/env perl -w

use lib 't/lib/';

use strict;
use warnings;
use Test::Most;
use Test::Warnings;
use File::chdir;
use File::Path qw(mkpath);
use App::KSP_CKAN::Test;
use App::KSP_CKAN::Tools::Config;


use_ok("App::KSP_CKAN::WebHooks::GenerateReleases");

## Setup our environment
my $test = App::KSP_CKAN::Test->new();
$test->create_repo("CKAN-meta");

# Config
$test->create_config(nogh => 1);
my $config = App::KSP_CKAN::Tools::Config->new(
  file => $test->tmp."/.ksp-ckan",
);

my $generate = App::KSP_CKAN::WebHooks::GenerateReleases->new(
  config => $config,
); 
isa_ok($generate, "App::KSP_CKAN::WebHooks::GenerateReleases");

$generate->_CKAN_meta->pull;

# Create test files
my $path = $config->working."/CKAN-meta/";
$test->create_ckan( file => $path."current.ckan" );
$test->create_ckan( file => $path."current/current.ckan" );
$test->create_ckan( file => $path."middle.ckan", ksp_version_max => "1.0", ksp_version_min => "0.90" );
$test->create_ckan( file => $path."middle/middle.ckan", ksp_version => "1.0" );
$test->create_ckan( file => $path."legacy.ckan", ksp_version_max => "0.20", ksp_version_min => "0.13" );
$test->create_ckan( file => $path."legacy/legacy.ckan", ksp_version => "0.20" );
$test->create_releases( file => $config->working."/CKAN-meta/releases.json" );
$generate->_CKAN_meta->add;
$generate->_CKAN_meta->commit(all => 1);
$generate->_CKAN_meta->push;

use File::Find;

my @files;
{
  local $CWD = $path;
  find(sub {
    my $f =  $File::Find::name; 
    push (@files, $f) if ($f =~ /\.ckan$/);
  }, ".");
}

$generate->releases(\@files);

my @releases;
foreach my $release (@{$generate->_releases->releases}) {
  push(@releases, $release->{name});
}

foreach my $release (@releases) {
  my @non_exist = grep ! /$release/, @releases;
  subtest $release => sub {
    my $working = $config->working."/$release";
    my $ckan = App::KSP_CKAN::Tools::Git->new(
      remote  => $config->CKAN_meta,
      local   => $working,
      clean   => 1,
    );
  
    # Can't checkout a branch for an unitialised repo. Pull first
    # required, wouldn't hit this in regular use of git tools.
    $ckan->pull;
    $ckan->orphan_branch($release);
    $ckan->pull;
    local $CWD = $working."/CKAN-meta";
    is($ckan->current_branch, $release, "Branch correctly checked out");
    is(-f "$release.ckan", 1, "File at root of path made it into correct branch");
    is(-f "$release/$release.ckan", 1, "File under subpath made it into correct branch");
    foreach my $non (@non_exist) {
      is(-f "$non.ckan", undef, "File '$non' not in this branch");
      is(-f "$non/$non.ckan", undef, "'$non' under subpath '$non' not in this branch");
    }
  };
}

$test->cleanup;

done_testing();
__END__
