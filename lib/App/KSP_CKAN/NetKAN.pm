package App::KSP_CKAN::NetKAN;

use v5.010;
use strict;
use warnings;
use autodie;
use Method::Signatures 20140224;
use Scalar::Util::Reftype;
use File::chdir;
use Capture::Tiny qw(capture);
use Carp qw( croak );
use App::KSP_CKAN::Tools::Http;
use App::KSP_CKAN::Tools::Git;
use App::KSP_CKAN::Tools::NetKAN;
use Moo;
use namespace::clean;

# ABSTRACT: NetKAN Indexing Service

# VERSION: Generated by DZP::OurPkg:Version

=head1 SYNOPSIS

  use App::KSP_CKAN::NetKAN;

  my $netkan = App::KSP_CKAN::NetKAN->new(
    config => $config,
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
has '_http'       => ( is => 'ro', lazy => 1, builder => 1 );
has '_CKAN_meta'  => ( is => 'ro', lazy => 1, builder => 1 );
has '_NetKAN'     => ( is => 'ro', lazy => 1, builder => 1 );

method _build__http {
  return App::KSP_CKAN::Tools::Http->new();
}

method _build__CKAN_meta {
  return App::KSP_CKAN::Tools::Git->new(
    remote => $self->config->CKAN_meta,
    local => $self->config->working,
    clean => 1,
  );
}

method _build__NetKAN {
  return App::KSP_CKAN::Tools::Git->new(
    remote => $self->config->NetKAN,
    local => $self->config->working,
    clean => 1,
  );
}

method _mirror_files {
  # netkan.exe
  $self->_http->mirror( 
    url => $self->config->netkan_exe,
    path => $self->config->working."/netkan.exe",
    exe => 1,
  );

  # ckan-validate.py
  $self->_http->mirror( 
    url => $self->config->ckan_validate,
    path => $self->config->working."/ckan-validate.py",
    exe => 1,
  );

  # CKAN.schema
  $self->_http->mirror( 
    url => $self->config->ckan_schema,
    path => $self->config->working."/CKAN.schema",
    exe => 1,
  );
  return;
}


method _inflate_all(:$rescan = 1) {
  $self->_CKAN_meta->pull;
  $self->_NetKAN->pull;
  local $CWD = $self->config->working."/".$self->_NetKAN->working;
  foreach my $file (glob("NetKAN/*.netkan")) {
    my $netkan = App::KSP_CKAN::Tools::NetKAN->new(
      netkan => $self->config->working."/netkan.exe",
      cache => $self->config->working."/cache",
      token => $self->config->GH_token,
      file => $file,
      ckan_meta => $self->config->working."/".$self->_CKAN_meta->working,
      rescan => $rescan,
    );
    $netkan->inflate;
  }
  return;
}

method _validate($file) {
  my ($stderr, $stdout, $exit) = capture { 
    local $CWD = $self->config->working;
    system("python", "ckan-validate.py", $file);
  };

  # TODO: Logging
  #$stdout if $stdout;
  return $exit;
}

method _commit {
  $self->_CKAN_meta->add;
  my @changes = $self->_CKAN_meta->changed;

  foreach my $changed (@changes) {
    my $file = $self->config->working."/".$self->_CKAN_meta->working."/".$changed;
    if ( $self->_validate($file) ) {
      #$log->WARN("Failed to Parse $changed");
      $self->_CKAN_meta->reset(file => $file);
    }
    else {
      #$log->INFO("Commiting $changed");
      $self->_CKAN_meta->commit(
        file => $file,
        message => "NetKAN generated mods - $changed",
      );
    }
  }
  $self->_CKAN_meta->pull(ours => 1);
  $self->_CKAN_meta->push;
  return;
}

#TODO: Write Tests + doco

method full_index {
  $self->_mirror_files;
  $self->_inflate_all;
  $self->_commit;
  return;
}

method lite_index {
  $self->_mirror_files;
  $self->_inflate_all( rescan => 0 );
  $self->_commit;
  return;
}

1;