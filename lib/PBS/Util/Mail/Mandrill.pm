package PBS::Util::Mail::Mandrill;

# ABSTRACT: interface to Mandrill email services

use PBS::Setup::Moo;
use JSON::XS ();
use Carp ();

################
# WebHook parser

method parse_webhook_payload ($json, $cb) {
  my $data = JSON::XS::decode_json($json);

  if ($cb) {
    for my $i (@$data) {
      my $ev = delete $i->{event};
      my $ms = delete $i->{msg};
      my $ts = delete $i->{ts};

      Carp::confess("[FATAL]: unrecognized keys in event hash - " . join(', ', map {"'$_'"} sort keys %$i)) if %$i;

      $cb->($ev, $ms, $ts);
    }
  }

  return $data;
}

1;
