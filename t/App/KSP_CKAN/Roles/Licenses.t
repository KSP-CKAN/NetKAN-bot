#!/usr/bin/env perl -w

use lib 't/lib/';

use strict;
use warnings;
use Test::Most;
use Test::Warnings;
use App::KSP_CKAN::Test;
use App::KSP_CKAN::Test::Licenses;

my $licenses = App::KSP_CKAN::Test::Licenses->new();

subtest 'licenses' => sub {
  my @licenses = [
      "public-domain",
      "Apache", "Apache-1.0", "Apache-2.0",
      "Artistic", "Artistic-1.0", "Artistic-2.0",
      "BSD-2-clause", "BSD-3-clause", "BSD-4-clause",
      "ISC",
      "CC-BY", "CC-BY-1.0", "CC-BY-2.0", "CC-BY-2.5", "CC-BY-3.0", "CC-BY-4.0",
      "CC-BY-SA", "CC-BY-SA-1.0", "CC-BY-SA-2.0", "CC-BY-SA-2.5", "CC-BY-SA-3.0", "CC-BY-SA-4.0",
      "CC-BY-NC", "CC-BY-NC-1.0", "CC-BY-NC-2.0", "CC-BY-NC-2.5", "CC-BY-NC-3.0", "CC-BY-NC-4.0",
      "CC-BY-NC-SA", "CC-BY-NC-SA-1.0", "CC-BY-NC-SA-2.0", "CC-BY-NC-SA-2.5", "CC-BY-NC-SA-3.0", "CC-BY-NC-SA-4.0",
      "CC-BY-NC-ND", "CC-BY-NC-ND-1.0", "CC-BY-NC-ND-2.0", "CC-BY-NC-ND-2.5", "CC-BY-NC-ND-3.0", "CC-BY-NC-ND-4.0",
      "CC-BY-ND", "CC-BY-ND-1.0", "CC-BY-ND-2.0", "CC-BY-ND-2.5", "CC-BY-ND-3.0", "CC-BY-ND-4.0",
      "CC0",
      "CDDL", "CPL",
      "EFL-1.0", "EFL-2.0",
      "Expat", "MIT",
      "GPL-1.0", "GPL-2.0", "GPL-3.0",
      "LGPL-2.0", "LGPL-2.1", "LGPL-3.0",
      "GFDL-1.0", "GFDL-1.1", "GFDL-1.2", "GFDL-1.3",
      "GFDL-NIV-1.0", "GFDL-NIV-1.1", "GFDL-NIV-1.2", "GFDL-NIV-1.3",
      "LPPL-1.0", "LPPL-1.1", "LPPL-1.2", "LPPL-1.3c",
      "MPL-1.1",
      "Perl",
      "Python-2.0",
      "QPL-1.0",
      "W3C",
      "Zlib",
      "Zope",
      "WTFPL",
      "Unlicense",
      "open-source", "unrestricted" ];

  my @test = $licenses->redistributable_licenses;

  is_deeply(
    @test,
    @licenses,
    "Redistributable licenses returned correctly"
  );
};

subtest 'license urls' => sub {
  is(
    $licenses->license_url("GPL-2.0"),
    "http://www.gnu.org/licenses/old-licenses/gpl-2.0.en.html",
    "GPL-2.0 license url returned successfully",
  );
};

1;

done_testing();
__END__
