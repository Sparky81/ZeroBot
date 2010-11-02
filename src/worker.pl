#!/usr/bin/env perl
# Copyright (c) 2010 Samuel Hoffman
# Copyright (c) 2010 Mitchel Cooper
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
use System;
use ACL;
load();
start($$config{server}, $$config{port}, $$config{ssl}) if $$config{ssl};
start($$config{server}, $$config{port}) if !$$config{ssl};

my $me = $$config{nick};

puts "NICK $me";
puts "USER $$config{ident} 8 * :$$config{gecos}";
sleep(3);
netjoin $config->{homechan};
while (my $buffer = <$Sock::sock>)
{
  chop $buffer;
  $buffer =~ s/^\s+//g;
  $buffer =~ s/\s+$//g;
  my @s = split(' ', $buffer);
  my $from = $s[0];
  $from =~ s/\://g;
  my @n = split('!', $from);
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
      my $trigger = substr($cmd,-(length($cmd)), 1);
      my @a = split(' ', $buffer, 5);
      my $args = $a[4];
      $args =~ s/\s+$// if $args;
      if ($target =~ m/^\#/) {
        if ($trigger eq $config->{trigger}) {
          $cmd = substr($cmd, 1);
          if (exists $chancmds{$cmd})
          {
            if ($chancmds{$cmd}{acl})
            {
              my $acl = lc($chancmds{$cmd}{acl});
              if ($acl eq 'op')
              {
                if (isop $channel, $nick)
                {
                  $chancmds{$cmd}{code}->($channel, $nick, $args) if $args;
                  $chancmds{$cmd}{code}->($channel, $nick) if !$args;
                } else { notice $nick, "$cmd requires $acl"; }
              }
              if ($acl eq 'admin')
              {
                if ((isadmin $from) or (isowner $from))
                {
                  $chancmds{$cmd}{code}->($channel, $nick, $args) if $args;
                  $chancmds{$cmd}{code}->($channel, $nick) if !$args;
                } else {
                  notice $nick, "$cmd requires $acl";
                }
              }
              if ($acl eq 'owner')
              {
                if (isowner $from)
                {
                  $chancmds{$cmd}{code}->($channel, $nick, $args) if $args;
                  $chancmds{$cmd}{code}->($channel, $nick) if !$args;
                } else {
                  notice $nick, "$cmd requires $acl";
                }
              }
            } else {
              $chancmds{$cmd}{code}->($channel, $nick, $args) if $args;
              $chancmds{$cmd}{code}->($channel, $nick) if !$args;
            }
          }
        } 
      }
    }
    if ($command eq '352')
    {
      user_add($buffer, @s);
    }
    if ($command eq 'JOIN')
    {
      $channel = substr $channel, 1;
      foreach (sort keys %jcmds)
      {
        $jcmds{$_}{code}->($channel, $n[0]);
      }
      who $channel;
    }
    if ($command eq 'PART')
    {
      who $channel;
    }
    if ($command eq '353')
    {
      who $s[4];
    }
    if ($command eq 'KICK')
    {
      who $channel;
    }
    if ($command eq 'MODE')
    {
      if ($target =~ /^\#/)
      {
        who $channel;
      }
    }
    if ($command eq 'QUIT')
    {
      System::user_del($nick);
    }
  }
}
