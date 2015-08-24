package App::KSP_CKAN::Status::NetKAN;

use v5.010;
use strict;
use warnings;
use Method::Signatures 20140224;
use Moo;
use namespace::clean;

has 'name'            => ( is => 'ro', );
has 'last_updated'    => ( is => 'rw' );
has 'last_indexed'    => ( is => 'rw' );

method update {
  $self->last_updated(time);
}

method indexed {
  $self->last_updated(time);
}

method TO_JSON {
  my $data = {
    name => $self->name,
    last_updated => $self->last_updated,
    last_indexed => $self->last_indexed,
  };
  return $data;
}

1;
