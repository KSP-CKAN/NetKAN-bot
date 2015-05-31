#!/usr/bin/env perl -w

use lib 't/lib/';

use strict;
use warnings;
use Test::Most;
use Test::Warnings;
use File::chdir;
use File::Path qw(mkpath);
use App::KSP_CKAN::Test;

# Setup our environment
my $test = App::KSP_CKAN::Test->new();
$test->create_repo("CKAN-meta");

use_ok("App::KSP_CKAN::Tools::Git");

# Test we can get our working directory
subtest 'Working Dir Parsing' => sub {
  my @test_git = (
    $test->tmp."/data/CKAN-meta",
    'git@github.com:techman83/CKAN-meta.git',
    'https://github.com/techman83/CKAN-meta.git',
  );
  
  foreach my $working (@test_git) {
    my $git = App::KSP_CKAN::Tools::Git->new(
      remote => $working,
      local => $test->tmp,
    );
  
    is($git->working, 'CKAN-meta', "'CKAN-meta' parsed from $working"); 
  };
};

# Test our instantiation
my $git = App::KSP_CKAN::Tools::Git->new(
  remote => $test->tmp."/data/CKAN-meta",
  local => $test->tmp,
  clean => 1,
);
isa_ok($git, "App::KSP_CKAN::Tools::Git");

# Test Cleanup
mkpath($test->tmp."/CKAN-meta");
$git->_clean;
isnt($test->tmp."/CKAN-meta", 1, "Clean was successful");

# Test our clone
isa_ok($git->_git, "Git::Wrapper");
is(-e $test->tmp."/CKAN-meta/README.md", 1, "Cloned successfully");

# Test adding
$test->create_ckan( $test->tmp."/CKAN-meta/test_file.ckan" );
is($git->changed, 0, "No file was added");
$git->add;
is($git->changed, 1, "File was added");

# Test Committing a single file
subtest 'Committing' => sub {
  my @files = $git->changed;
  $git->commit(file => $files[0]);
  is($git->changed(origin => 0), 0, "Commit successful");
  is($git->changed, 1, "Commit not yet pushed");
  $git->push;
  is($git->changed, 0, "Commit pushed");
  
  # Test committing all files
  for my $filename (qw(test_file2.ckan test_file3.ckan)) {
    $test->create_ckan( $test->tmp."/CKAN-meta/".$filename );
  }
  $git->add;
  is($git->changed, 2, "Files were added");
  $git->commit(all => 1, message => "All the comitting");
  is($git->changed(origin => 0), 0, "Commit successful");
  $git->push;
  is($git->changed, 0, "Commit pushed");
};

# Pull tests
# TODO: Expand these
my $pull = App::KSP_CKAN::Tools::Git->new(
  remote => $test->tmp."/data/CKAN-meta",
  working => "CKAN-meta-pull",
  local => $test->tmp,
  clean => 1,
);
$pull->pull;
$test->create_ckan( $test->tmp."/CKAN-meta-pull/test_pull.ckan" );
$pull->add;
$pull->commit(all => 1);
$pull->push;
$git->pull;
is(-e $test->tmp."/CKAN-meta/test_pull.ckan", 1, "Pull successful");

# Test accidental deletes
unlink($test->tmp."/CKAN-meta/test_file.ckan");
$git->add;
is($git->changed, 1, "File delete not commited");

# Cleanup after ourselves
$test->cleanup;

done_testing();
__END__
