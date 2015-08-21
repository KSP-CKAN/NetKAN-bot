package App::KSP_CKAN::Tools::NetKAN;

use v5.010;
use strict;
use warnings;
use autodie;
use Method::Signatures 20140224;
use Try::Tiny;
use File::Spec 'tmpdir';
use File::Basename qw(basename);
use File::Path qw(mkpath);
use Capture::Tiny qw(capture);
use Digest::MD5::File qw(dir_md5_hex);
use File::Find::Age;
use Carp qw(croak);
use Moo;
use namespace::clean;

# ABSTRACT: A wrapper around NetKAN.exe and NetKAN related functions.

# VERSION: Generated by DZP::OurPkg:Version

=head1 SYNOPSIS

  use App::KSP_CKAN::Tools::NetKAN;

  my $netkan = App::KSP_CKAN::Tools::NetKAN->new(
    netkan => "/path/to/netkan.exe",
    chache => "/path/to/cache",
    token => $token,
    file => '/path/to/file.netkan',
    ckan_meta => '/path/to/CKAN-meta',
  );

=head1 DESCRIPTION

Is a wrapper for the NetKAN inflater. Initially it will
just wrap and capture errors, but the intention is to 
add helper methods to check for changes in remote meta
data and only run the inflater when required.

=cut

my $Ref = sub {
  croak("config isn't a 'App::KSP_CKAN::Tools::Config' object!") unless $_[0]->DOES("App::KSP_CKAN::Tools::Config");
};

my $Meta = sub {
  croak("ckan-meta isn't a 'App::KSP_CKAN::Tools::Git' object!") unless $_[0]->DOES("App::KSP_CKAN::Tools::Git");
};

has 'config'              => ( is => 'ro', required => 1, isa => $Ref );
has 'netkan'              => ( is => 'ro', required => 1 );
has 'cache'               => ( is => 'ro', default => sub { File::Spec->tmpdir()."/NetKAN-cache"; } );
has 'file'                => ( is => 'ro', required => 1 );
has 'ckan_meta'           => ( is => 'ro', required => 1, isa => $Meta );
has 'token'               => ( is => 'ro' );
has 'rescan'              => ( is => 'ro', default => sub { 1 } );
has '_ckan_meta_working'  => ( is => 'ro', lazy => 1, builder => 1 );
has '_output'             => ( is => 'ro', lazy => 1, builder => 1 );
has '_cli'                => ( is => 'ro', lazy => 1, builder => 1 );
has '_cache'              => ( is => 'ro', lazy => 1, builder => 1 );
has '_basename'           => ( is => 'ro', lazy => 1, builder => 1 );

method _build__cache {
  if ( ! -d $self->cache ) {
    mkpath($self->cache);
  }

  return $self->cache;
}

method _build__basename {
  return basename($self->file,  ".netkan");
}

method _build__ckan_meta_working {
  return $self->config->working."/".$self->ckan_meta->working;
}

method _build__output {
  if (! -d $self->_ckan_meta_working."/".$self->_basename ) {
    mkdir $self->_ckan_meta_working."/".$self->_basename;
  }
  return $self->_ckan_meta_working."/".$self->_basename;
}

method _build__cli {
  if ($self->token) {
    return $self->netkan." --outputdir=".$self->_output." --cachedir=".$self->_cache." --github-token=".$self->token." ".$self->file;
  } else {
    return $self->netkan." --outputdir=".$self->_output." --cachedir=".$self->_cache." ".$self->file;
  }
}

method _output_md5 {
  my $md5 = Digest::MD5->new();
  $md5->adddir($self->_output);
  return $md5->hexdigest;
}

# Short of hashing every file individually (including
# ones that may not have existed before) we have no
# real way to derive what changed from NetKAN, but the
# Filesystem is kind enough to tell us.
method _newest_file {
  return pop(File::Find::Age->in($self->_output))->{file};
}

method _check_lite {
  # TODO: Build a method to go and check if required full inflate
  croak("_check_lite is unimplimented");
  return 0;
}

method _parse_error($error) {
  my $return;
  if ($error =~ /^\d+.\[\d+\].FATAL/) {
    $error =~ m{FATAL.+.-.(.+)};
    $return = $1;
  } else {
    $error =~ m{^\[ERROR\].(.+)}m;
    $return = $1;
  }
  return $return || "Error wasn't parsable";
}

method _commit($file) {
  $self->ckan_meta->add($file);
  my $changed = basename($file,  ".ckan");
  if ( $self->validate($file) ) {
    $self->warn("Failed to Parse $changed");
    $self->ckan_meta->reset(file => $file);
  }
  else {
    $self->info("Commiting $changed");
    $self->ckan_meta->commit(
      file => $file,
      message => "NetKAN generated mods - $changed",
    );
  }
}

=method inflate
  
  $netkan->inflate;

Inflates our metadata.

=cut

method inflate {
  if (! $self->rescan ) {
    return;
  }

  # We won't know if NetKAN actually made a change and
  # it doesn't know either, it just produces a ckan file.
  # This gives us a hash of all files in the directory
  # before we inflate to compare afterwards.
  my $md5 = $self->_output_md5;

  $self->debug("Inflating ".$self->file);
  my ($stderr, $stdout, $exit) = capture { 
    system($self->_cli);
  };

  if ($exit) { 
    my $error = $self->_parse_error($stdout); 
    $self->warn("'".$self->file."' - ".$error); 
  }

  if ($md5 ne $self->_output_md5) {
    $self->_commit($self->_newest_file);
  }

  return $exit;
}

with('App::KSP_CKAN::Roles::Logger','App::KSP_CKAN::Roles::Validate');

1;
