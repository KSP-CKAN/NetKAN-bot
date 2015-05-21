# NetKAN-bot
NetKAN indexing service

TODO: Expand this!

We'll need some deps. 
```bash
apt-get install liblocal-lib-perl cpanminus install build-essential mono-complete libcurl4-openssl-dev python-jsonschema  
```

NetKAN will need certs for mono
```bash
mozroots --import --ask-remove
```

# We'll be using lib local for our Perl deps.
```bash
perl -Mlocal::lib >> ~/.bashrc
```

Our Perl Deps
```bash
cpanm File::Basename File::chdir File::Path Try::Tiny HTTP::Tiny Log::Tiny IPC::System::Simple
```

Currently everything is hardcoded, if you generate a github token, NetKAN will use it and 
it will need to go here ~/.NetKAN/github.token

And _only_ contain the the token on the first line.

It will generate a log file at ~/.NetKAN/NetKAN.log
