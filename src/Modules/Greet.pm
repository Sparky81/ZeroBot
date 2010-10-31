# Copyright (c) 2010 Samuel Hoffman
package Modules::Greet;
use strict;
use warnings;
use ServerCommands;
use Module;
use Message;

our ($greets);

command_add({
  cmd => 'addgreet',
  acl => 'admin',
  help => 'Add a greet message to be displayed each time a specified user joins a channel.',
  code => sub {
    my ($dst, $nick, $msg) = @_;
    $$greets{lc($nick)} = $msg;
    notice $dst, "Added greet for \2$nick\2.";
  }
});

command_add({
  cmd => 'delgreet',
  acl => 'admin',
  help => 'Remove a greet message.',
  code => sub {
    my ($dst, $nick) = @_;
    if (!$$greets{lc($nick)}) {
      notice $dst, "\2$nick\2 does not have a greet message.";
      return;
    }
    delete $$greets{lc($nick)};
    notice $dst, "Greet for \2$nick\2 has been removed.";
  }
});

command_add({
  cmd => 'listgreets',
  help => 'List all greets in the system',
  code => sub {
    my $dst = shift;
    notice $dst, "Greet List:";
    foreach (sort keys %$greets) {
      notice $dst, "\2NICK\2: $_, \2GREET\2: $$greets{$_}";
    }
  }
});

1;
