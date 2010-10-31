# Copyright (c) 2010 Samuel Hoffman
package Modules::Calculator;
use strict;
use warnings;
use Message;
use Module;
use WWW::Google::Calculator;

cmd_add_chan({
  cmd => 'calc',
  help => 'Evaluate an expression using Google\'s Calculator.',
  code => sub {
    my ($chan, $dst, $expr) = @_;
    my $gc = WWW::Google::Calculator->new();
    msg $chan, "$dst: '$expr' = '".$gc->calc($expr)."'";
  }
});

1;
