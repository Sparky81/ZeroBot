# Copyright (c) 2010 Samuel Hoffman
package Modules::Calculator;
use strict;
use warnings;
use Message;
use Module;
use WWW::Google::Calculator;

our ($calc, $result);

$calc = WWW::Google::Calculator->new;

cmd_add_privmsg({
  cmd => 'calc',
  help => 'Evaluate an expression using Google\'s Calculator.',
  code => sub {
    my ($chan, $dst, $expr) = @_;

    if (!eval { require WWW::Google::Calculator; 1; }) {
      notice $dst, "Please install WWW::Google::Calculator before running this command.";
      return;
    }

    $result = $calc->calc("$expr");
    notice $dst, $result;
  }
});

1;
