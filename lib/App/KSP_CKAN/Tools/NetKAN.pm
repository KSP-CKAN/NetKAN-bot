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
use Scalar::Util::Reftype;
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
  croak("auth isn't a 'App::KSP_CKAN::Tools::Config' object!") unless reftype( $_[0] )->class eq "App::KSP_CKAN::Tools::Config";
};

has 'config'      => ( is => 'ro', required => 1, isa => $Ref );
has 'netkan'    => ( is => 'ro', required => 1 );
has 'cache'     => ( is => 'ro', default => sub { File::Spec->tmpdir()."/NetKAN-cache"; } );
has 'file'      => ( is => 'ro', required => 1);
has 'ckan_meta' => ( is => 'ro', required => 1 );
has 'token'     => ( is => 'ro' );
has 'rescan'    => ( is => 'ro', default => sub { 1 } );
has '_output'   => ( is => 'ro', lazy => 1, builder => 1 );
has '_cli'      => ( is => 'ro', lazy => 1, builder => 1 );
has '_cache'    => ( is => 'ro', lazy => 1, builder => 1 );

method _build__cache {
  if ( ! -d $self->cache ) {
    mkpath($self->cache);
  }

  return $self->cache;
}

method _build__output {
  my $basename = basename($self->file,  ".netkan");
  if (! -d $self->ckan_meta."/".$basename ) {
    mkdir $self->ckan_meta."/".$basename;
  }
  return $self->ckan_meta."/".$basename;
}

method _build__cli {
  if ($self->token) {
    return $self->netkan." --outputdir=".$self->_output." --cachedir=".$self->_cache." --github-token=".$self->token." ".$self->file;
  } else {
    return $self->netkan." --outputdir=".$self->_output." --cachedir=".$self->_cache." ".$self->file;
  }
}

method _check_lite {
  # TODO: Build a method to go and check if required full inflate
  return 0;
}

method _parse_error($error) {
  $error =~ m{^\[ERROR\].(.+)}m;
  return $1;
}

=method inflate
  
  $netkan->inflate;

Inflates our metadata.

=cut

method inflate {
  if (! $self->rescan ) {
    return;
  }

  $self->debug("Inflating ".$self->file);
  my ($stderr, $stdout, $exit) = capture { 
    system($self->_cli);
  };

  if ($exit) {
    my $error = $self->_parse_error($stdout) || "' - Error wasn't parsable";
    $self->warn("'".$self->file."' - ".$error);
  }

  return $exit;
}

with('App::KSP_CKAN::Roles::Logger');

1;
