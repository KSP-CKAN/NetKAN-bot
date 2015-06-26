App::KSP-CKAN    [![Build Status](https://travis-ci.org/KSP-CKAN/NetKAN-bot.svg?branch=master)](https://travis-ci.org/KSP-CKAN/NetKAN-bot)  [![Coverage Status](https://coveralls.io/repos/KSP-CKAN/NetKAN-bot/badge.svg?branch=master)](https://coveralls.io/r/KSP-CKAN/NetKAN-bot?branch=master)

Non Perl Dependencies
=====================
```bash
apt-get install liblocal-lib-perl cpanminus install build-essential mono-complete libcurl4-openssl-dev python-jsonschema  
```

NetKAN will need certs for mono
```bash
mozroots --import --ask-remove
```

Configure local::lib if you haven't already done so:
```bash
$ perl -Mlocal::lib >> ~/.bashrc
$ eval $(perl -Mlocal::lib)
```

Installation
============

Install from git, you can then use:
```bash
$ dzil authordeps | cpanm
$ dzil listdeps   | cpanm
$ dzil install
```

or cpanm via the tar.gz on the GitHub Release page

```bash
cpanm App-KSP_CKAN-0.001.tar.gz
```

Configuration
=============

An ini file with the following contents will need to created at ~/.ksp-ckan
```
CKAN_meta=git@github.com:KSP-CKAN/CKAN-meta.git
NetKAN=git@github.com:KSP-CKAN/NetKAN-bot.git
netkan_exe=https://ckan-travis.s3.amazonaws.com/netkan.exe
ckan_validate=https://raw.githubusercontent.com/KSP-CKAN/CKAN/master/bin/ckan-validate.py
ckan_schema=https://raw.githubusercontent.com/KSP-CKAN/CKAN/master/CKAN.schema
working=/home/NetKAN/NetKAN
```

If you have a GitHub token, add the following line (helpful for prevent expending the GitHub public API limits):
```
GH_token=1234567890
```

Running
=======

Completing a full index is as straight forward as:
```bash
netkan-indexer
```

Debugging will print debug messages to the logfile and to the screen. It is enabled with
```bash
netkan-indexer --debug
```

Enable it in cron with (crontab -e as the netkan user):
```
# Run full index every 3 hours
00 */3 * * * PERL5LIB=/home/netkan/perl5/lib/perl5/ netkan-indexer
```

There is a 'lite' cli option is not implemented. It's a future concept to allow 'lite' 
skimming of metadata API endpoints without performing a full metadata inflation.
