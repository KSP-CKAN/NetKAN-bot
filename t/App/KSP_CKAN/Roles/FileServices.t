#!/usr/bin/env perl -w

use lib 't/lib/';

use strict;
use warnings;
use Test::Most;
use Test::Warnings;
use App::KSP_CKAN::Test;
use App::KSP_CKAN::Test::FileServices;

my $fileservices = App::KSP_CKAN::Test::FileServices->new();

is(
  $fileservices->extension("application/x-gzip"),
  "gz",
  "'gz' returned for 'application/x-gzip'",
);

is(
  $fileservices->extension("application/x-tar"),
  "tar",
  "'tar' returned for 'application/x-tar'",
);

is(
  $fileservices->extension("application/x-compressed-tar"),
  "tar.gz",
  "tar.gz'' returned for 'application/x-compressed-tar'",
);

is(
  $fileservices->extension("application/zip"),
  "zip",
  "'zip' returned for 'application/zip'",
);

is(
  $fileservices->extension("application/octect-stream"),
  0,
  "'0' returned for 'application/octect-stream'",
);

is(
  $fileservices->extension("plain/text"),
  0,
  "'0' returned for 'plain/text'",
);

done_testing();
__END__
