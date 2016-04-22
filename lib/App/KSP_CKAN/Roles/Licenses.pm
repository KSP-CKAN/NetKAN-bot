package App::KSP_CKAN::Roles::Licenses;

use v5.010;
use strict;
use warnings;
use autodie;
use Method::Signatures 20140224;
use Moo::Role;

# ABSTRACT: At CKAN we care about licenses

# VERSION: Generated by DZP::OurPkg:Version

=head1 SYNOPSIS

  with('App::KSP_CKAN::Roles::Licenses');

=head1 DESCRIPTION

We care about licenses deeply. It helps us make decisions about
what we can and can't do with hosted mods. Such as mirroirng.

=cut

has '_license_urls'   => ( is => 'ro', lazy => 1, builder => 1 );

# NOTE: Did look at a couple of libs to do this, but nothing quite fit
#       without building a translation table anyway.
# TODO: Do we consider no version number for a version to be the first
#       version of the relevant license or the latest?
method _build__license_urls {
  return {
    "Apache"            => 'http://www.apache.org/licenses/LICENSE-1.0',
    "Apache-1.0"        => 'http://www.apache.org/licenses/LICENSE-1.0',
    "Apache-2.0"        => 'http://www.apache.org/licenses/LICENSE-2.0',
    "Artistic"          => 'http://www.gnu.org/licenses/license-list.en.html#ArtisticLicense',
    "Artistic-1.0"      => 'http://www.gnu.org/licenses/license-list.en.html#ArtisticLicense',
    "Artistic-2.0"      => 'http://www.perlfoundation.org/artistic_license_2_0',
    "BSD-2-clause"      => 'https://opensource.org/licenses/BSD-2-Clause',
    "BSD-3-clause"      => 'https://opensource.org/licenses/BSD-3-Clause',
#    "BSD-4-clause"      => '', # TODO: Clarify this
    "ISC"               => 'https://opensource.org/licenses/ISC',
    "CC-BY"             => 'https://creativecommons.org/licenses/by/1.0/',
    "CC-BY-1.0"         => 'https://creativecommons.org/licenses/by/1.0/',
    "CC-BY-2.0"         => 'https://creativecommons.org/licenses/by/2.0/',
    "CC-BY-2.5"         => 'https://creativecommons.org/licenses/by/2.5/',
    "CC-BY-3.0"         => 'https://creativecommons.org/licenses/by/3.0/',
    "CC-BY-4.0"         => 'https://creativecommons.org/licenses/by/4.0/',
    "CC-BY-SA"          => 'https://creativecommons.org/licenses/by-sa/1.0/',
    "CC-BY-SA-1.0"      => 'https://creativecommons.org/licenses/by-sa/1.0/',
    "CC-BY-SA-2.0"      => 'https://creativecommons.org/licenses/by-sa/2.0/',
    "CC-BY-SA-2.5"      => 'https://creativecommons.org/licenses/by-sa/2.5/',
    "CC-BY-SA-3.0"      => 'https://creativecommons.org/licenses/by-sa/3.0/',
    "CC-BY-SA-4.0"      => 'https://creativecommons.org/licenses/by-sa/4.0/',
    "CC-BY-NC"          => 'https://creativecommons.org/licenses/by-nc/1.0/',
    "CC-BY-NC-1.0"      => 'https://creativecommons.org/licenses/by-nc/1.0/',
    "CC-BY-NC-2.0"      => 'https://creativecommons.org/licenses/by-nc/2.0/',
    "CC-BY-NC-2.5"      => 'https://creativecommons.org/licenses/by-nc/2.5/',
    "CC-BY-NC-3.0"      => 'https://creativecommons.org/licenses/by-nc/3.0/',
    "CC-BY-NC-4.0"      => 'https://creativecommons.org/licenses/by-nc/4.0/',
    "CC-BY-NC-SA"       => 'http://creativecommons.org/licenses/by-nc-sa/1.0/', 
    "CC-BY-NC-SA-1.0"   => 'http://creativecommons.org/licenses/by-nc-sa/1.0',
    "CC-BY-NC-SA-2.0"   => 'http://creativecommons.org/licenses/by-nc-sa/2.0',
    "CC-BY-NC-SA-2.5"   => 'http://creativecommons.org/licenses/by-nc-sa/2.5',
    "CC-BY-NC-SA-3.0"   => 'http://creativecommons.org/licenses/by-nc-sa/3.0',
    "CC-BY-NC-SA-4.0"   => 'http://creativecommons.org/licenses/by-nc-sa/4.0',
    "CC-BY-NC-ND"       => 'https://creativecommons.org/licenses/by-nd-nc/1.0/',
    "CC-BY-NC-ND-1.0"   => 'https://creativecommons.org/licenses/by-nd-nc/1.0/',
    "CC-BY-NC-ND-2.0"   => 'https://creativecommons.org/licenses/by-nd-nc/2.0/',
    "CC-BY-NC-ND-2.5"   => 'https://creativecommons.org/licenses/by-nd-nc/2.5/',
    "CC-BY-NC-ND-3.0"   => 'https://creativecommons.org/licenses/by-nd-nc/3.0/',
    "CC-BY-NC-ND-4.0"   => 'https://creativecommons.org/licenses/by-nd-nc/4.0/',
    "CC0"               => 'https://creativecommons.org/publicdomain/zero/1.0/',
    "CDDL"              => 'https://opensource.org/licenses/CDDL-1.0',
    "CPL"               => 'https://opensource.org/licenses/cpl1.0.php',
    "EFL-1.0"           => 'https://opensource.org/licenses/ver1_eiffel',
    "EFL-2.0"           => 'https://opensource.org/licenses/EFL-2.0',
    "Expat"             => 'https://opensource.org/licenses/MIT', # https://en.wikipedia.org/wiki/MIT_License
    "MIT"               => 'https://opensource.org/licenses/MIT',
    "GPL-1.0"           => 'http://www.gnu.org/licenses/old-licenses/gpl-1.0.en.html',
    "GPL-2.0"           => 'http://www.gnu.org/licenses/old-licenses/gpl-2.0.en.html',
    "GPL-3.0"           => 'http://www.gnu.org/licenses/gpl-3.0.en.html',
    "LGPL-2.0"          => 'https://www.gnu.org/licenses/old-licenses/lgpl-2.0.html',
    "LGPL-2.1"          => 'https://www.gnu.org/licenses/old-licenses/lgpl-2.1.html',
    "LGPL-3.0"          => 'http://www.gnu.org/licenses/lgpl-3.0.en.html',
#    "GFDL-1.0"          => '', # TODO: Doesn't appear to exist.
    "GFDL-1.1"          => 'http://www.gnu.org/licenses/old-licenses/fdl-1.1.en.html',
    "GFDL-1.2"          => 'http://www.gnu.org/licenses/old-licenses/fdl-1.2.html',
    "GFDL-1.3"          => 'http://www.gnu.org/licenses/fdl-1.3.en.html',
#    "GFDL-NIV-1.0"      => '', # TODO: Can't seem to find links to NIV, aside
#    "GFDL-NIV-1.1"      => '', #       from it referred to in the debian spec.
#    "GFDL-NIV-1.2"      => '',
#    "GFDL-NIV-1.3"      => '',
    "LPPL-1.0"          => 'https://latex-project.org/lppl/lppl-1-0.html',
    "LPPL-1.1"          => 'https://latex-project.org/lppl/lppl-1-1.html',
    "LPPL-1.2"          => 'https://latex-project.org/lppl/lppl-1-2.html',
    "LPPL-1.3c"         => 'https://latex-project.org/lppl/lppl-1-3c.html',
    "MPL-1.1"           => 'https://www.mozilla.org/en-US/MPL/1.1/',
    "Perl"              => 'http://dev.perl.org/licenses/',
    "Python-2.0"        => 'https://www.python.org/download/releases/2.0/license/',
    "QPL-1.0"           => 'https://opensource.org/licenses/QPL-1.0',
    "W3C"               => 'https://www.w3.org/Consortium/Legal/2015/copyright-software-and-document',
    "Zlib"              => 'http://www.zlib.net/zlib_license.html',
    "Zope"              => 'http://old.zope.org/Resources/License.1',
  }
}

=method redistributable_licenses

  my @licenses = $self->redistributable_licenses;

Returns an array of open source licenses which allow redistribution.

=cut

# This is an array of explicit licenses which are allowed to be mirrored.
# TODO: Maybe we can consume this from somewhere externally.
method redistributable_licenses {
 return [
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
    "open-source", "unrestricted" ];
}

=metho has_license_url

  $self->license_url("GPL-2.0");

We may not have all the URLs for licenses intially. In the fullness
of time this will just prevent errors for new licenses being added
to the spec. Returns a url when it is is known and 0 for no license url.

=cut

method license_url($license) {
  if ( defined $self->_license_urls->{$license} ) {
    return $self->_license_urls->{$license};
  }
  return 0;
}

1;
