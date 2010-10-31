#!/usr/bin/env perl
# Copyright (c) 2010 Samuel Hoffman
use strict;
use warnings;
use Carp qw(cluck confess carp);
use Sock;
use Conf;
use Message;
use Commands::Server;
use Commands::Bot;
use Signals;
use Module;
use base 'Exporter';
our @EXPORT = qw(%users me);
load();
our ($me, %users);
start($$config{server}, $$config{port}, $$config{ssl}) if $$config{ssl};
start($$config{server}, $$config{port}) if !$$config{ssl};

$me = $$config{nick};

puts "NICK $me";
puts "USER $$config{ident} 8 * :$$config{gecos}";
sleep(3);
netjoin $config->{homechan};
while (my $buffer = <$Sock::sock>)
{
  chop $buffer;
  $buffer =~ s/^\s+//g;
  $buffer =~ s/\s+$//g;
  my @s = split(' ',$buffer);
  my $from = $s[0];
  $from =~ s/\://g;
  my @n = split('!',$from);
  my $nick = $n[0];
  my $target = $s[2];
  my $channel = $target;
  my $command = $s[1];
  $nick =~ s/\://g;
  if ($buffer =~ /^PING(.*)$/i) {
    puts("PONG $1");
  }
  unless ($nick eq $me) {
    if ($command eq 'PRIVMSG')
    {
      my $cmd = $s[3];
      $cmd =~ s/\://;
      $cmd = lc $cmd;
      my $trigger = substr($cmd,-(length($cmd)),1);
      my @a = split(' ',$buffer,5);
      my $args = $a[4];
      $args =~ s/\s+$// if $args;
      if ($target =~ m/^\#/) {
        if ($trigger eq $config->{trigger}) {
          $cmd = substr($cmd,1);
          if (exists $chancmds{$cmd})
          {
            $chancmds{$cmd}{code}->($channel, $nick, $args) if $args;
            $chancmds{$cmd}{code}->($channel, $nick) if !$args;
          }
        }
      }
    }
    if (($command eq 'PART') or ($command eq 'JOIN') or ($command eq 'KICK') or ($command eq 'MODE'))
    {
      # event!
    }
  }
}

END {
  &Sock::close("Error: $!") if $! and !$@;
  &Sock::close("Error: $@") if $@ and !$!;
  &Sock::close("Error: ($!) ($@)") if $@ and $!;
  &Sock::close("Dying of unknown error.") if !$@ and !$!;
  exit 0;
}
