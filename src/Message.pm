# Copyright (c) 2010 Samuel Hoffman
use strict;
use warnings;
package Message;
use Sock;
use base 'Exporter';
our @EXPORT = qw(msg notice act);
sub msg {
  my ($target, $msg) = @_;
  puts "PRIVMSG $target :$msg";
}

sub notice {
  my ($target, $msg) = @_;
  puts "NOTICE $target :$msg";
}

sub act {
  my ($target, $msg) = @_;
  msg $target, "\1ACTION $msg\1";
}

1;
