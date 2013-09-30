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


done_testing();
