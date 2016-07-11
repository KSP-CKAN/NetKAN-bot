#!/usr/bin/env perl -w

use lib 't/lib/';

use strict;
use warnings;
use v5.010;
use Test::Most;
use Test::Warnings;
use File::chdir;
use File::Path qw(mkpath remove_tree);
use Digest::file qw(digest_file_hex);
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

# Test our clone
# Git gives benign 'warning: --depth is ignored in local clones; use file:// instead.'
# Local pulls don't honor depth, but we're only testing that we can clone.
isa_ok($git->_git, "Git::Wrapper");
is(-e $test->tmp."/CKAN-meta/README.md", 1, "Cloned successfully");

# Test adding
$test->create_ckan( file => $test->tmp."/CKAN-meta/test_file.ckan" );
is($git->changed, 0, "No file was added");
$git->add($test->tmp."/CKAN-meta/test_file.ckan");
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
    $test->create_ckan( file => $test->tmp."/CKAN-meta/".$filename );
  }
  $git->add;
  is($git->changed, 2, "Files were added");
  $git->commit(all => 1, message => "All the comitting");
  is($git->changed(origin => 0), 0, "Commit successful");
  $git->push;
  is($git->changed, 0, "Commit pushed");

  # Test reseting
  $test->create_ckan( file => $test->tmp."/CKAN-meta/test_file2.ckan" );
  is($git->changed, 1, "test_file2.ckan was changed");
  @files = $git->changed;
  $git->reset( file => $files[0] );
  $git->push;
  is($git->changed, 1, "test_file2.ckan was not pushed");
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
$test->create_ckan( file => $test->tmp."/CKAN-meta-pull/test_pull.ckan" );
$pull->add;
$pull->commit(all => 1);
$pull->push;
$git->pull;
is(-e $test->tmp."/CKAN-meta/test_pull.ckan", 1, "Pull successful");

# Test accidental deletes
unlink($test->tmp."/CKAN-meta/test_file.ckan");
$git->add;
is($git->changed, 2, "File delete not commited");

# Test cleanup
$test->create_ckan( file => $test->tmp."/CKAN-meta/cleaned_file.ckan" );
$git->_hard_clean;
isnt(-e $test->tmp."/CKAN-meta/cleaned_file.ckan", 1, "Cleanup Successful");

subtest 'Git Errors' => sub {
  my $remote_error = App::KSP_CKAN::Tools::Git->new(
    remote => $test->tmp."/data/CKAN-meta",
    working => "remote-error",
    local => $test->tmp,
    clean => 1,
  );
  $remote_error->pull;
  $test->create_ckan( file => $test->tmp."/remote-error/test_push.ckan" );
  $remote_error->add;
  $remote_error->commit(all => 1);
  {
    local $CWD = $test->tmp;
    remove_tree( "remote-error/" );
  }
  dies_ok { $remote_error->push } "Remote issue fails loudly";

  my $path_error = App::KSP_CKAN::Tools::Git->new(
    remote => $test->tmp."/data/non_existent_repo",
    local => $test->tmp,
    clean => 1,
  );
  dies_ok { $path_error->pull } 'Non existent repo fails loudly';
};

subtest 'Staged Commit' => sub {
  my $file = $test->tmp."/CKAN-meta/staged.ckan";
  my $identifier = "Testing";
  
  # Initial File Creation
  $test->create_ckan( file => $file );
  $git->add($file);
  my $hash = digest_file_hex( $file, "SHA-1" );
  my $success = $git->staged_commit(
    file        => $file,
    identifier  => $identifier,
    message     => "New File",
  );
  is($success, 1, "We commited a new file to staging");
  $git->_hard_clean;

  is($git->current_branch, "master", "We returned to the master branch");
  isnt(-e $file, 1, "Our staged file wasn't commited to master");
  
  $git->checkout_branch("staging");
  is($git->current_branch, "staging", "We are on to the staging branch");
  $git->_hard_clean;
  is(digest_file_hex( $file, "SHA-1" ), $hash, "Our staging branch was commited to");
  $git->checkout_branch($identifier);
  is($git->current_branch, $identifier, "We are on the $identifier branch");
  $git->_hard_clean;
  is(digest_file_hex( $file, "SHA-1" ), $hash, "Our $identifier branch was commited to");
  
  # File update
  $test->create_ckan( file => $file, random => 0 );
  $hash = digest_file_hex( $file, "SHA-1" );
  $git->add($file);
  my $update = $git->staged_commit(
    file        => $file,
    identifier  => $identifier,
    message     => "Modified File",
  );
  $git->_hard_clean;
  is($update, 1, "We commited a change to staging");
 
  # Get the last commit ID from staging 
  $git->checkout_branch("staging");
  my $commit = $git->last_commit;
  $git->checkout_branch("master");
  
  # Update with no changes
  $test->create_ckan( file => $file, random => 0 );
  $git->add($file);
  $hash = digest_file_hex( $file, "SHA-1" );
  my $nochange = $git->staged_commit(
    file        => $file,
    identifier  => $identifier,
    message     => "No change file",
  );
  is($nochange, 0, "File with no changes reports not committed");
  $git->checkout_branch("staging");
  is($git->last_commit, $commit, "Commit ID matches prior commit");

  # Ensure we're always starting on Master
  $git->checkout_branch("staging");
  is($git->current_branch, "staging", "We are on to the staging branch");
  my $branch = App::KSP_CKAN::Tools::Git->new(
    remote => $test->tmp."/data/CKAN-meta",
    local => $test->tmp,
    clean => 1,
  );
  is($branch->current_branch, "master", "We start on master upon instantiation");
};


# Cleanup after ourselves
$test->cleanup;

done_testing();
__END__
