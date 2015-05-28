#!/usr/bin/perl -w

use Test::Most;
use Test::Warnings;
use File::Path qw(remove_tree mkpath);
use File::chdir;

use_ok("App::KSP_CKAN::Git");

# Test we can get our working directory
my @test_git = (
  "t/data/CKAN-meta",
  'git@github.com:techman83/CKAN-meta.git',
  'https://github.com/techman83/CKAN-meta.git',
);

foreach my $working (@test_git) {
  my $git = App::KSP_CKAN::Git->new(
    remote => $working,
    local => "/tmp/KSP_CKAN-test",
  );

  is($git->working, 'CKAN-meta', "'CKAN-meta' parsed from $working"); 
};

# Test our instantiation
my $git = App::KSP_CKAN::Git->new(
  remote => "t/data/CKAN-meta",
  local => "/tmp/KSP_CKAN-test",
  clean => 1,
);
isa_ok($git, "App::KSP_CKAN::Git");

# Test Cleanup
mkpath("/tmp/KSP_CKAN-test/CKAN-meta");
$git->_clean;
isnt("/tmp/KSP_CKAN-test/CKAN-meta", 1, "Clean was successful");

# Test our clone
isa_ok($git->_git, "Git::Wrapper");
is(-e "/tmp/KSP_CKAN-test/CKAN-meta/README.md", 1, "Cloned successfully");

# Cleanup after ourselves
{ 
  local $CWD = "/tmp";
  if ( -d "KSP_CKAN-test/" ) {
    remove_tree("KSP_CKAN-test/");
  }
}

done_testing();
__END__
