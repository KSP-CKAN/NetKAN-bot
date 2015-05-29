#!/usr/bin/env perl -w

use strict;
use warnings;
use Test::Most;
use Test::Warnings;
use File::Path qw(remove_tree mkpath);
use File::chdir;
use File::Spec 'tmpdir';
use File::Copy::Recursive 'dircopy';

# Setup our test environment
our $tmp = File::Spec->tmpdir();
our $testpath = "$tmp/KSP_CKAN-test";
mkpath("$testpath");
dircopy("t/data", "$testpath/data");
{
  local $CWD = "$testpath/data/CKAN-meta";
  system("git", "init");
  system("git", "add", "-A");
  system("git", "commit", "-a", "-m", "Commit ALL THE THINGS!");
}

use_ok("App::KSP_CKAN::Git");

# Test we can get our working directory
my @test_git = (
  "$testpath/data/CKAN-meta",
  'git@github.com:techman83/CKAN-meta.git',
  'https://github.com/techman83/CKAN-meta.git',
);

foreach my $working (@test_git) {
  my $git = App::KSP_CKAN::Git->new(
    remote => $working,
    local => $testpath,
  );

  is($git->working, 'CKAN-meta', "'CKAN-meta' parsed from $working"); 
};

# Test our instantiation
my $git = App::KSP_CKAN::Git->new(
  remote => "$testpath/data/CKAN-meta",
  local => $testpath,
  clean => 1,
);
isa_ok($git, "App::KSP_CKAN::Git");

# Test Cleanup
mkpath("$testpath/CKAN-meta");
$git->_clean;
isnt("$testpath/CKAN-meta", 1, "Clean was successful");

# Test our clone
isa_ok($git->_git, "Git::Wrapper");
is(-e "$testpath/CKAN-meta/README.md", 1, "Cloned successfully");

open my $in, '>', "$testpath/CKAN-meta/test_file.ckan";
print $in "{\n}";
close $in;

# Test adding
is($git->changed, 0, "No files were added");
$git->add;
is($git->changed, 1, "Files were added");

# Test Committing a single file

# TODO: This is broken
my @files = $git->changed;
$git->commit( all => 1);
is($git->changed, 0, "Commit successful");

# Cleanup after ourselves
{ 
  if ( -d $testpath ) {
    remove_tree($testpath);
  }
}

done_testing();
__END__
