#!perl

use PBS::Setup::Tests ':std';

use_ok('PBS::Util::Mail::Mandrill');

my $m = PBS::Util::Mail::Mandrill->new;

subtest 'parse_webhook_payload' => sub {
  my $p1 =
    '[{"event":"send","ts":1362130663,"msg":{"ts":1362130663,"subject":"Test","email":"test@example.com","tags":["tag1","tag2"],"opens":[],"clicks":[],"state":"sent","_id":"42","sender":"sent@example.com"}}]';

  cmp_deeply(
    $m->parse_webhook_payload($p1),
    [ { event => 'send',
        ts    => 1362130663,
        msg   => {
          ts      => 1362130663,
          subject => 'Test',
          email   => 'test@example.com',
          tags    => ['tag1', 'tag2'],
          opens   => [],
          clicks  => [],
          state   => 'sent',
          _id     => 42,
          sender  => 'sent@example.com'
        }
      }
    ],
    'parsed small payload ok'
  );

  my @item;
  $m->parse_webhook_payload($p1, sub { @item = @_ });
  cmp_deeply(
    \@item,
    [ 'send',

      { ts      => 1362130663,
        subject => 'Test',
        email   => 'test@example.com',
        tags    => ['tag1', 'tag2'],
        opens   => [],
        clicks  => [],
        state   => 'sent',
        _id     => 42,
        sender  => 'sent@example.com'
      },
      1362130663
    ],
    'callback-based parser also triggers with expected data'
  );
};


subtest 'big payload example' => sub {
  my $payload = do {
    my $file = 't/pbs/util/mail/data/test.json';
    local $/;
    open(my $fh, '<', $file) or die "FATAL: could not open file '$file',";
    <$fh>;
  };

  my %meta;
  my $cb = sub {
    my ($type, $msg, $ts) = @_;
    $meta{total}++;
    $meta{msg_type}{$type}++;

    return unless $type eq 'hard_bounce' or $type eq 'soft_bounce';
    $meta{msg_key}{$_}{$type}{ (defined($msg->{$_}) ? $msg->{$_} : '<undef>') }++ for qw( bounce_description );
  };

  $m->parse_webhook_payload($payload, $cb);
  cmp_deeply(
    \%meta,
    { msg_key => {
        bounce_description => {
          hard_bounce => { bad_mailbox => 111 },
          soft_bounce => {
            general        => 24,
            invalid_domain => 10,
            mailbox_full   => 3
          }
        }
      },
      total    => 760,
      msg_type => {
        hard_bounce => 111,
        send        => 609,
        reject      => 3,
        soft_bounce => 37
      }
    },
    'expected data from parsing all the messages'
  );
};


done_testing();
