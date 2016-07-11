package App::KSP_CKAN::Tools::Git;

use v5.010;
use strict;
use warnings;
use autodie qw(:all);
use Method::Signatures 20140224;
use Carp qw(croak);
use Try::Tiny;
use Git::Wrapper;
use Capture::Tiny qw(capture capture_stdout);
use File::chdir;
use File::Path qw(remove_tree mkpath);
use Digest::file qw(digest_file_hex);
use Moo;
use namespace::clean;

# ABSTRACT: A collection of our regular git commands

# VERSION: Generated by DZP::OurPkg:Version

=head1 SYNOPSIS

  use App::KSP_CKAN::Git;

  my $git = App::KSP_CKAN::Git->new(
    remote => 'git@github.com:KSP-CKAN/NetKAN-bot.git',
    local => "$ENV{HOME}/.NetKAN/NetKAN-bot",
    clean => 1,
  );

=head1 DESCRIPTION

CKAN's development + build process is built around git. The
things we need to do are pretty common and all git 
interactions will fit nicely here.

The wrapper can be called with the following options.

=over

=item remote

Remote repository path or url.

=item local

Path to the working directory of where it will be cloned.

=item working

This optional, we'll try to guess that. It can however
be provided (just the human name, no slashes).

=item clean

Will remove and pull a fresh copy of the repository.

=item shallow

Will perform a shallow clone of the repository

=back

=cut

has 'remote'    => ( is => 'ro', required => 1 );
has 'local'     => ( is => 'ro', required => 1 );
has 'working'   => ( is => 'ro', lazy => 1, builder => 1 );
has 'clean'     => ( is => 'ro', default => sub { 0 } );
has 'shallow'   => ( is => 'ro', default => sub { 1 } );
has 'branch'    => ( is => 'rw', default => sub { "master" } );
has '_git'      => ( is => 'rw', isa => sub { "Git::Wrapper" }, lazy => 1, builder => 1 );

method _build__git {
  if ( ! -d $self->local ) {
    mkpath($self->local);
  }

  if ( ! -d $self->local."/".$self->working ) {
    $self->_clone;
  } elsif ($self->clean) { # Lets not clean a cloned repo
    $self->_hard_clean;
  }

  my $git = Git::Wrapper->new({
    dir => $self->local."/".$self->working,
  });

  # Lets make sure we start from a known place.
  $git->checkout($self->branch);
  return $git;
}

method _build_working {
  $self->remote =~ m/^(?:.*\/)?(.+)$/;
  my $working = $1;
  $working =~ s/\.git$//;
  return $working;
}

method _clone {
  # TODO: I think Git::Wrapper has a way to do this natively
  # TODO: We should pass back success or failure.
  if ($self->shallow) {
    capture { system("git", "clone", "--depth", "1", $self->remote, $self->local."/".$self->working) };
  } else {
    capture { system("git", "clone", $self->remote, $self->local."/".$self->working) };
  }
  return;
}

method _hard_clean {
  # TODO: We could fail here too, we should return as such.
  # NOTE: We've not instantiated a git object at this point, so
  # we can't use it.
  local $CWD = $self->local."/".$self->working;
  capture { system("git", "reset", "--hard", "HEAD") };
  capture { system("git", "clean", "-df") };
  return;
}

method _random_branch {
  # http://www.perlmonks.org/?node_id=233023
  my @chars = ("A".."Z", "a".."z");
  my $rand;
  $rand .= $chars[rand @chars] for 1..8;
  return $rand;
}

=method current_branch

  say $git->current_branch;

Returns the current bracn you're on.

=cut

method current_branch {
  my @parse = $self->_git->rev_parse(qw|--abbrev-ref HEAD|);
  return $parse[0];
}

=method add

  $git->add($file);

This method takes an optional filename, if blank will perform a
'git add .'.

=cut

# TODO: It'd probably be nice to allow a list of 
# files
method add($file?) {
  if ($file) {
    $self->_git->add($file);
  } else {
    $self->_git->add(".");
  }
  return;
}

=method clean_untracked

  $git-clean_untracked;

Recursively removes untracked files and directories from the repository.

=cut

method clean_untracked {
  $self->_git->RUN("clean", "-df");
}

=method changed
  
  my @changed = $git->changed;

Will return a list of changed files when compared to 
origin/current_branch. Can be used in scalar context 
(number of committed files) or an if block.

  if ($git->changed) {
    say "We've got changed files!";
  }

Takes an optional bool parameter of 'origin' if you want
a list of comparing local.

  my @local = $git->changed( origin => 0 );

=cut

method changed(:$origin = 1) {
  if ( $origin ) {
    return $self->_git->diff({ 'name-only' => 1, }, "--stat", "origin/".$self->current_branch );
  } else {
    return $self->_git->diff({ 'name-only' => 1, });
  }
}

=method commit

  $git->commit( all => 1, message => "Commit Message!" );

Will commit all staged added files with a generic
commit message.

=over

=item all

Optional argument. Defaults to false.

=item file

Optional argument. Will commit all if not provided.

=item message

Optional argument. Will literally add 'Generic Commit' as
the commit message if not provided.

=back

=cut

method commit(:$all = 0, :$file = 0, :$message = "Generic Commit") {
  if ($all || ! $file) {
    return $self->_git->commit({ a => 1 }, "-m $message");
  } else {
    return $self->_git->commit($file, "-m \"$message\"");
  }
}

=method checkout_branch

  $git->checkout_branch("staging")

Checks out the destination branch if it exists else creates it and
checks it out.

=cut

method checkout_branch($branch) {
  local $CWD = $self->local."/".$self->working;
  # one of these will succeed
  try {
    capture {system("git checkout -b $branch")};
  };
  try {
    capture {system("git checkout $branch")};
  };
  croak "Couldn't checkout our requested branch" unless $branch eq $self->current_branch;
  return;
}

=method cherry_pick

  $git->cherry_pick($commit);

Cherry picks a commit into the current branch.

=cut

method cherry_pick($commit) {
  $self->_git->RUN("cherry-pick", $commit);
  return;
}

=method staged_commit

  $git->staged_commit( 
    file        => "/path/to/ExampleNetKAN.netkan",
    identifier  => "ExampleNetKAN", 
    message     => "NetKAN bot loves to commit!",
  );

Performs a commit to the staging branch, then checks out an identifier
branch and cherry-picks the commit from the previous commit to staging.

=cut

# TODO: The staging branch is will reflect the first point it branched
#       from master on the NetKAN bot. So to use the staging branch
#       it must accompany the primary repository in ckan. It'll worth
#       seeing how this works in practice and think on how to solve
#       them drifting.

method staged_commit(:$identifier, :$file, :$message = "Generic Commit") {
  # Need to push our changes before checking out staging otherwise our
  # staged commits end up with the commits already in master.
  $self->pull( ours => 1 );
  $self->push;

  # We could stash, but the results were inconsistent and it seemed hard,
  # with lots of edge cases.
  # This seems like a novel approach
  # https://codingkilledthecat.wordpress.com/2012/04/27/git-stash-pop-considered-harmful/
  my $random_branch = $self->_random_branch;
  $self->checkout_branch($random_branch);
  $self->commit(
    file    => $file,
    message => $message,
  );

  # We need to hash the new file for comparrison against the existing
  # file before cherry-picking
  my $hash = digest_file_hex( $file, "SHA-1" );
  my $commit = $self->last_commit;

  # We need to go back to master to avoid issues diverging from the 
  # random branch if our staging branch doesn't exist. 
  $self->checkout_branch($self->branch);

  # Lets start with staging
  $self->checkout_branch("staging");
  
  # We don't want to repeatedly PR changes  
  if ( -e $file && digest_file_hex( $file, "SHA-1" ) eq $hash ) {
    $self->delete_branch($random_branch);
    return 0;
  }
  
  $self->cherry_pick($commit);
  # Upstream pulling needs to be done after commiting.
  try { # Our remote may not have the branch, we don't mind.
    $self->pull( ours => 1 );
  };
  $self->push;
 
  # We need to go back to our original branch to avoid
  # diverging from our staging branch
  $self->checkout_branch($self->branch);

  # Commit to identifier branch
  $self->checkout_branch($identifier);
  $self->cherry_pick($commit);
  # Upstream pulling needs to be done after commiting.
  try { # Our remote may not have the branch, we don't mind.
    $self->pull( ours => 1 );
  };
  $self->push;

  # Return to our original branch
  $self->checkout_branch($self->branch);
  $self->delete_branch($random_branch);
  return 1;
}

=method delete_branch
  
  $git->delete_branch($branch);

Deletes the requested branch.

=cut

method delete_branch($branch) {
  return $self->_git->RUN("branch", "-D", $branch);
}

=method reset
  
  $git->reset( file => $file );

Will reset the uncommitted file.

=cut

# TODO: We can likely expand what we can do with reset.
method reset(:$file) {
  return $self->_git->RUN("reset", $file);
}

=method push
  
  $git->push;

Will push the current checked out local branch to origin/branch.

=cut

method push {
  return $self->_git->push("origin",$self->current_branch);
}

=method pull

  $git->pull;

Performs a git pull. Takes optional bool arguments of
'ours' and 'theirs' which will tell git who wins when
merge conflicts arise.

=cut

method pull(:$ours?,:$theirs?) {
  if ($theirs) {
    $self->_git->pull("origin", $self->current_branch, "-X", "theirs");
  } elsif ($ours) {
    $self->_git->pull("origin", $self->current_branch, "-X", "ours");
  } else {
    $self->_git->pull("origin", $self->current_branch);
  }
  return;
}

=method last_commit
  
  $git->last_commit;

Will return the full hash of the last commit.

=cut

method last_commit {
  # NOTE: We could have used the builtin $git->RUN('log', '--format=%H'))[0],
  #       but it parses the entire commit history which at ~19000 commits
  #       takes about 120ms, this takes less than 2ms.
  local $CWD = $self->local."/".$self->working;
  my $commit = capture_stdout { system("git", "log", "--no-patch", "HEAD^..HEAD", '--format=%H') };
  chomp($commit);
  return $commit;
}

=method yesterdays_diff

  $git->yesterdays_diff;

Produces a list of files of changes since yesterday.

git diff $(git rev-list -n1 --before="yesterday" master) --name-only

=cut

# TODO: It'd be cool to be able to test this
method yesterdays_diff {
  my $branch = $self->branch;
  local $CWD = $self->local."/".$self->working;
  my $changed = capture_stdout { system("git diff \$(git rev-list -n1 --before=\"yesterday\" $branch) --name-only") };
  chomp $changed;
  return split("\n", $changed);
}

1;
