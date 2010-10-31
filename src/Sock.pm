# Copyright (c) 2010 Samuel Hoffman
package Sock;
use strict;
use warnings;

use base 'Exporter';

use IO::Socket;
use Conf;

our @EXPORT = qw(start puts close sock);
our $sock;

sub start {
  my ($srv, $port, $ssl) = @_;
  if ($ssl)
  {
    require IO::Socket::SSL;
    $sock = IO::Socket::SSL->new(
      PeerAddr => $srv,
      PeerPort => $port,
      Timeout => '30',
      Proto => 'tcp'
      ) or die "Could not start socket. ($!)\n";
  } else {
    $sock = IO::Socket::INET->new(
      PeerAddr => $srv,
      PeerPort => $port,
      Timeout => '30',
      Proto => 'tcp'
      ) or die "Could not start socket. ($!)\n";
  }
}

sub puts {
  my ($packet) = shift;
  print $sock "$packet\n";
}

sub close {
  my ($reason) = shift;
  puts "QUIT $reason";
}

1;
