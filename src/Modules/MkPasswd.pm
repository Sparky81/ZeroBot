# Copyright (c) 2010 Samuel Hoffman
use strict;
use warnings;
use Message;
use Module;

cmd_add_chan({
  cmd => 'mkpasswd',
  help => 'Hash a password with Linux\'s "mkpasswd" command.',
  code => sub {
    my ($chan, $dst, $passwd) = @_;
    my $mkpasswd = `mkpasswd $passwd`;
    notice $dst, "Hash for $passwd is $mkpasswd";
  }
});

1;
