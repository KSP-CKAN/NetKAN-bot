#!/usr/bin/env perl -w

use strict;
use warnings;
use Test::Most;
use Test::Warnings;
use File::Path qw(remove_tree mkpath);
use File::chdir;
use File::Spec 'tmpdir';
use File::Copy::Recursive qw(dircopy dirmove);

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
  chdir("../");
  dirmove("CKAN-meta", "CKAN-meta-tmp");
  system("git", "clone", "--bare", "CKAN-meta-tmp", "CKAN-meta");

}

use_ok("App::KSP_CKAN::Tools::Git");

# Test we can get our working directory
subtest 'Working Dir Parsing' => sub {
  my @test_git = (
    "$testpath/data/CKAN-meta",
    'git@github.com:techman83/CKAN-meta.git',
    'https://github.com/techman83/CKAN-meta.git',
  );
  
  foreach my $working (@test_git) {
    my $git = App::KSP_CKAN::Tools::Git->new(
      remote => $working,
      local => $testpath,
    );
  
    is($git->working, 'CKAN-meta', "'CKAN-meta' parsed from $working"); 
  };
};

# Test our instantiation
my $git = App::KSP_CKAN::Tools::Git->new(
  remote => "$testpath/data/CKAN-meta",
  local => $testpath,
  clean => 1,
);
isa_ok($git, "App::KSP_CKAN::Tools::Git");

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
    open my $in, '>', "$testpath/CKAN-meta/$filename";
    print $in "{\n}";
    close $in;
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
  remote => "$testpath/data/CKAN-meta",
  working => "CKAN-meta-pull",
  local => $testpath,
  clean => 1,
);
$pull->pull;
{
  local $CWD = "$testpath/CKAN-meta-pull";
  open my $in, '>', "$testpath/CKAN-meta-pull/test_pull.ckan";
  print $in "{\n}";
  close $in;
}
$pull->add;
$pull->commit(all => 1);
$pull->push;
$git->pull;
is(-e "$testpath/CKAN-meta/test_pull.ckan", 1, "Pull successful");

# Test accidental deletes
unlink("$testpath/CKAN-meta/test_file.ckan");
$git->add;
is($git->changed, 1, "File delete not commited");

# Cleanup after ourselves
if ( -d $testpath ) {
  remove_tree($testpath);
}


done_testing();
__END__
