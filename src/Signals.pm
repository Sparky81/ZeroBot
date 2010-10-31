# Copyright (c) 2010 Samuel Hoffman
package Signals;
use strict;
use warnings;
use Sock;
use Message;
use Conf;
use base 'Exporter';
our @EXPORT = qw(end rehash ignore);
$SIG{INT} = 'end';
$SIG{HUP} = 'rehash';
$SIG{PIPE} = 'ignore';

sub end {
  puts "QUIT :Received SIGINT, exiting.";
  close($Sock::sock);
  exit 0;
}

sub rehash {
  msg $$config{homechan}, "Caught SIGHUP, rehashing...";
  load();
}

sub ignore { () }
