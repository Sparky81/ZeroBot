# Copyright (c) 2010 Samuel Hoffman
package Commands::Server;
use strict;
use warnings;
use Sock;
use Message;
use base 'Exporter';
our @EXPORT = qw(nick netjoin part kick who);

sub netjoin {
  my ($channel, $dst) = @_;
  puts "JOIN $channel";
  notice $dst, "Joined \2$channel\2." if $dst;
}

sub part {
  my ($channel, $reason, $dst) = @_;
  if (($dst) and ($reason))
  {
    puts "PART $channel :PART by \2$dst\2 ($reason)";
  }
  elsif (($dst) and (!$reason))
  {
    puts "PART $channel :PART by \2$dst\2 (No reason given.)";
  }
  elsif ((!$dst) and (!$reason))
  {
    puts "PART $channel";
  }
}

sub kick {
  my ($dst, $channel, $client, $reason) = @_;
  puts "KICK $channel $client :($dst) $reason";
}

sub who {
  my ($channel) = shift;
  puts "WHO $channel";
}

sub nick {
  my ($nick) = shift;
  puts "NICK $nick";
}

1;
