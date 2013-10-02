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
      my $ev = $i->{event};
      my $ms = $i->{msg};
      my $ts = $i->{ts};

      $cb->($ev, $ms, $ts, $i);
    }
  }

  return $data;
}

1;
