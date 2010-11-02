# Copyright (c) 2010 Samuel Hoffman
package Modules::Greet;
use strict;
use warnings;
use Commands::Server;
use Module;
use Message;
use Database;

our ($greets);

cmd_add_chan({
  cmd => 'addgreet',
  acl => 'admin',
  help => 'Add a greet message to be displayed each time a specified user joins a channel.',
  syntax => '<nick> <message>',
  code => sub {
    my ($chan, $dst, $args) = @_;
    my ($nick, $msg);
    if ($args =~ m/^(.*?) (.+)/i)
    {
      $nick = $1; $msg = $2;
    }
    $$greets{lc($nick)} = $msg;
    notice $dst, "Not enough parameters." if ((!$msg) or (!$nick)) and return;
    my $row = $db->do("INSERT INTO GREETS (NICK, MSG) VALUES ('".lc($nick)."', '$msg');");
    notice $dst, ($row ? 'Successfully added greet.' : "Could not add greet. ($!) ($@)");
  },
  init => sub {
    my $greetlist = $db->selectall_arrayref("SELECT * FROM GREETS;");
    foreach my $row (@$greetlist) {
      my ($nick, $msg) = @$row;
      $nick = lc($nick);
      $$greets{$nick} = $msg;
    }
  }
});

cmd_add_chan({
  cmd => 'delgreet',
  acl => 'admin',
  help => 'Remove a greet message.',
  code => sub {
    my ($chan, $dst, $nick) = @_;
    if (!$$greets{lc($nick)}) {
      notice $dst, "\2$nick\2 does not have a greet message.";
      return;
    }
    delete $$greets{lc($nick)};
    notice $dst, "Greet for \2$nick\2 has been removed.";
  }
});

cmd_add_chan({
  cmd => 'listgreets',
  help => 'List all greets in the system',
  code => sub {
    my ($chan, $dst) = @_;
    notice $dst, "Greet List:";
    foreach (sort keys %$greets) {
      notice $dst, "\2NICK\2: $_, \2GREET\2: $$greets{$_}";
    }
  }
});

on_join({
  title => 'greet-on-join',
  code => sub {
    my ($chan, $jnick) = @_;
    if (exists $$greets{lc($jnick)})
    {
      msg $chan, "[$jnick] ".$$greets{lc($jnick)}."";
    }
  }
});

1;
