package App::KSP_CKAN::WebHooks;

use Dancer2 appname => "xKanHooks";
use AnyEvent::Util;
use File::Touch;

post '/mirror' => sub { 
  info("Logging a thing");

  fork_call {
    info("Forking ".time);
    while (-e "/tmp/test_lock.lock" ) {
      debug("Waiting for lock release");
      sleep 5;
    }
    info("locking");
    touch("/tmp/test_lock.lock");
    sleep 20;
    return;
  } sub {
    info("Fork Complete");
    unlink("/tmp/test_lock.lock");
    return;
  };

  my $return->{message} = "Hello World"; 
  return $return;
};

post '/inflate' => sub {

}

1;
