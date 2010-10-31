#!/usr/bin/env perl
# Copyright (c) 2010 Samuel Hoffman
use strict;
use warnings;
use Carp qw(cluck confess carp);
use Sock;
use Conf;
use ServerCommands;

BEGIN {
  our $path = $ENV{PATH};
  print "Starting!\n";
}

load();

start($$config{server}, $$config{port}, $$config{ssl}) if $$config{ssl};
start($$config{server}, $$config{port}) if !$$config{ssl};

our $me = $$config{nick};

puts "NICK $me";
puts "USER $$config{ident} 8 * :$$config{gecos}";

while (my $buffer = <$Sock::sock>)
{
  if ($buffer =~ /004/) {
    puts("MODE $me +B");
    netjoin($$config{homechan});
  } 

  if ($buffer =~ /433/) {
    cluck "It appears $me is already in use on ".$config->{IRCserver}.", concatenating to :".$me."-";
    $me = $me.'-';
    nick($me);
  }

  if ($buffer =~ /^PING(.*)$/) {
    puts "PONG $1";
  }
}

END {
  &Sock::close("Shutting down ZeroBot");
}
