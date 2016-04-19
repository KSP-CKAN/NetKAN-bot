package App::KSP_CKAN::Tools::IA;

use v5.010;
use strict;
use warnings;
use autodie;
use Method::Signatures 20140224;
use LWP::UserAgent;
use File::MimeInfo::Magic 'mimetype';
use Scalar::Util 'reftype';
use HTTP::Request::StreamingUpload;
use Encode;
use Moo;
use namespace::clean;

# ABSTRACT: An abstraction to the Internet Archive S3 like interface

# VERSION: Generated by DZP::OurPkg:Version

=head1 SYNOPSIS

  use App::KSP_CKAN::Tools::IA;

  my $IA = App::KSP_CKAN::Tools::IA->new( config => $config );

=head1 DESCRIPTION

Provides a light wrapper to the Internet Archives' S3 like interface.

Takes the following named attributes:

=over

=item config

Requires a 'App::KSP_CKAN::Tools::Config' object.

=item collection

Defaults to 'test_collection'.

=item mediatype

Defaults to 'software'

=item iaS3uri

Defaults to 'https://s3.us.archive.org'.

=back

=cut

my $Ref = sub {
    croak("auth isn't a 'App::KSP_CKAN::Tools::Config' object!") unless $_[0]->DOES("App::KSP_CKAN::Tools::Config");
};

has 'config'      => ( is => 'ro', required => 1, isa => $Ref );
has 'collection'  => ( is => 'ro', default => sub { 'test_collection' } );
has 'mediatype'   => ( is => 'ro', default => sub { 'software' } );
has 'iaS3uri'     => ( is => 'ro', default => sub { 'https://s3.us.archive.org' } );
has 'iaDLuri'     => ( is => 'ro', default => sub { 'https://www.archive.org/download' } );
has '_ua'         => ( is => 'rw', lazy => 1, builder => 1 );
has '_ias3keys'   => ( is => 'ro', lazy => 1, builder => 1 );

method _build__ua {
  my $ua = LWP::UserAgent->new();
  $ua->agent('upload_via_KSP-CKAN/NetKAN-bot');
  $ua->timeout(60);
  $ua->env_proxy;
  $ua->default_headers->push_header( 'authorization' => "LOW ". $self->_ias3keys);
  return $ua;
}

method _build__ias3keys {
  my $config = $self->config;
  return $config->IA_access.":".$config->IA_secret;
}

method _upload_uri($ckan) {
  $self->logdie("\$ckan isn't a 'App::KSP_CKAN::Metadata::Ckan' object!") unless $ckan->DOES("App::KSP_CKAN::Metadata::Ckan");
  return $self->iaS3uri."/".$ckan->mirror_item."/".$ckan->mirror_filename;
}

method _download_uri($ckan) {
  $self->logdie("\$ckan isn't a 'App::KSP_CKAN::Metadata::Ckan' object!") unless $ckan->DOES("App::KSP_CKAN::Metadata::Ckan");
  return $self->iaDLuri."/".$ckan->mirror_item."/".$ckan->mirror_filename;
}

# TODO: Likely makes sense to be part of the Ckan lib.
method _description($ckan) {
  my $description = $ckan->abstract;
  $description .= "<br><br>Homepage: <a href=\"".$ckan->homepage."\">".$ckan->homepage."</a>" if $ckan->homepage;
  $description .= "<br>Repository: <a href=\"".$ckan->repository."\">".$ckan->repository."</a>" if $ckan->repository;
  $description .= "<br>License(s): @{$ckan->licenses}" if $ckan->license;
  return $description;
}

method _archive_header( $header, $value ) {
  # Credit for logic to: https://github.com/kngenie/ias3upload
  if (reftype \$value ne "SCALAR") {
    if ($#{$value} == 0) {
      return ('x-archive-meta-' . $header, encode('UTF-8', $value->[0]));
    } else {
      my $i = 1;
      return map((sprintf('x-archive-meta%02d-%s', $i++, $header), encode('UTF-8',$_)), @{$value});
    }
  } else {
    return ('x-archive-meta-' . $header, encode('UTF-8',$value));
  }
}

method _metadata_headers ( $file, $ckan ) {
  $self->logdie("\$ckan isn't a 'App::KSP_CKAN::Metadata::Ckan' object!") unless $ckan->DOES("App::KSP_CKAN::Metadata::Ckan");
  my $mimetype = mimetype( $file );

  my $headers = HTTP::Headers->new(
    'Content-Type'                => $mimetype,
    'Content-Length'              => -s $file,
    $self->_archive_header('collection', $self->collection),
    $self->_archive_header('creator', \@{$ckan->authors}),
    $self->_archive_header('subject', "ksp; kerbal space program; mod"),
    $self->_archive_header('title', $ckan->name." - ".$ckan->version),
    $self->_archive_header('description', $self->_description($ckan)),
    $self->_archive_header('mediatype', $self->mediatype),
  );
  
  # TODO: oh gosh, this looks more complicated than it needs to be.
  # Note: It's like this because we need to increment the headers with a
  # number, we might have multipel licenses we may not have a 
  # licenses url for all of them.
  my @urls;
  foreach my $license (@{$ckan->licenses}) {
    push(@urls, $self->license_url($license)) if $self->license_url($license);
  }
  my @url_headers = $self->_archive_header('licenseurl', \@urls) if $urls[0];
  $headers->push_header(@url_headers) if $url_headers[0];

  return $headers;
}

# NOTE: We're using StreamingUpload here, because LWP likes to 
#       pull the entire file into memory when uploading.
method _put_request( :$headers, :$uri, :$file) {
  return HTTP::Request::StreamingUpload->new(
    PUT     => $uri,
    path    => $file,
    headers => $headers,  
  );
}

=method check_overload

 $ia->check_overload;

Checks if the submission servers are overloaded or we've reached
an API limit. Returns '1' if overloaded, '0' if not.

=cut

method check_overload {
  my $res =  $self->_ua->get($self->iaS3uri."/?check_limit=1&accesskey=".$self->config->IA_access);
 
  if ( $res->{_rc} == '503' ) {
    return 1;
  }
  return 0;
}

=method put_ckan

  $ia->(
    ckan => $ckan,
    file => "/path/to/mod.zip",
  );

Takes a ckan object and file, then puts it on the Internet Archive.
Returns '1' on success, '0' on failure.

Requires the following named attributes:
=over

=item ckan

Requires a 'App::KSP_CKAN::Metadata::Ckan' object.

=item file

Path to the file being uploaded.

=back

=cut

method put_ckan( :$ckan, :$file ) {
  $self->logdie("\$ckan isn't a 'App::KSP_CKAN::Metadata::Ckan' object!") 
    unless $ckan->DOES("App::KSP_CKAN::Metadata::Ckan");

  my $headers =  $self->_metadata_headers( $file, $ckan );
  $headers->push_header('x-amz-auto-make-bucket', 1);

  my $request = $self->_put_request(
    headers => $headers,
    uri     => $self->_upload_uri( $ckan ),
    file    => $file,
  );

  my $res = $self->_ua->request($request);

  if ($res->is_success) {
    return 1;
  }

  return 0;
}

=method ckan_mirrored

  $ia->ckan_mirrored( ckan => $ckan );

Requires a 'App::KSP_CKAN::Metadata::Ckan' object within the 'ckan'
attribute. Returns '1' if mirrored, Otherwise '0' if the archive
can't be contacted or no file is found.

=cut

# TODO: Not 100% happy with our returns here. I've seen spotty
#       responses from the IA at times.
method ckan_mirrored( :$ckan ) {
  $self->logdie("\$ckan isn't a 'App::KSP_CKAN::Metadata::Ckan' object!") 
    unless $ckan->DOES("App::KSP_CKAN::Metadata::Ckan");
  
  my $res = $self->_ua->head($self->_download_uri( $ckan ));

  if ($res->is_success) {
    return 1;
  }

  return 0;
}

with('App::KSP_CKAN::Roles::Logger', 'App::KSP_CKAN::Roles::Licenses');

1;
