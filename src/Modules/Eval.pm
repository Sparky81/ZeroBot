# Copyright (c) 2010 Samuel Hoffman
package Modules::Eval;
use strict;
use warnings;
use Message;
use Module;

cmd_add_chan({
  cmd => 'eval',
  help => 'Evaluate an expression with the Perl Interpreter. WARNING: This is unfiltered! You can permanently damage your system if used incorrectly.',
  acl => 'admin',
  code => sub {
    my ($chan, $dst, $expr) = @_;
    my $result = eval($expr);
    msg $chan, "'$expr' = '$result'" if !$@;
    msg $chan, $@ if $@;
  }
});

1;
