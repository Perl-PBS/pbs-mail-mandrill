package PBS::Util::Mail::Mandrill;

# ABSTRACT: interface to Mandrill email services

use PBS::Setup::Moo;
use JSON::XS ();
use Carp     ();

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


##################
# Blacklist loader

method load_email_blacklist ($path) {
  ## FIXME: use PBS::Exception
  Carp::confess('FATAL: to use email_blacklist, email_blacklist_path is required, must be directory')
    unless defined $path and (!-e $path or -d _);

  require Path::Tiny;
  $path = Path::Tiny::path($path);

  my %bl;
  my $iter = $path->iterator;
  while ($path = $iter->()) {
    unless ($path->basename =~ qr{^[A-F0-9]{8}-[A-F0-9]{4}-[A-F0-9]{4}-[A-F0-9]{4}-[A-F0-9]{12}$}) {
      warn "File '$path' ignored, bad filename\n";
      next;
    }

    my $payload = _parse_payload($path);
    unless (defined $payload) {
      warn "File '$path' ignored, could not parse it\n";
      next;
    }

    try {
      $self->parse_webhook_payload(
        $payload,
        sub {
          my ($ev, $msg, $ts) = @_;
          my $addr = $msg->{email};
          return unless defined $addr;

          my $info = $bl{$addr} ||= { ts => $ts };
          return if $info->{ts} > $ts;    # Keep only last report per addr

          if    ($ev eq 'hard_bounce') { $info->{skip} = 1 }
          elsif ($ev eq 'soft_bounce') { $info->{skip} = $ts > time() - 30 * 24 * 60 * 60 }    ## retry after 30 days
        }
      );
    }
    catch {
      warn "File '$path' ignored, could not parse JSON: $payload ($_)\n";
    };
  }

  return \%bl;
}

func _parse_payload ($path) {
  my $p = eval $path->slurp_raw;    # yeah, bad idea, I know...
  Carp::confess($@) if $@;

  $p->{args}{mandrill_events};
}


1;
