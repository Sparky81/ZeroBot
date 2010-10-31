# Copyright (c) 2010 Samuel Hoffman
# Copyright (c) 2010 Mitchel Cooper
package System;
use strict;
use warnings;
use base 'Exporter';
our @EXPORT = qw(user_del user_add %user %channel);

our (%user, %channel);

sub user_add { # /WHO
  my ($input, @s) = @_;
  my @r = split ' ', $input, 11;
  my $real = $r[10];
  $channel{$s[3]}{users}{$s[7]} = time;
  $user{lc($s[7])}{'nick'} = $s[7];
  $user{lc($s[7])}{'ident'} = $s[4];
  $user{lc($s[7])}{'host'} = $s[5];
  $user{lc($s[7])}{'server'} = $s[6];
  $user{lc($s[7])}{'real'} = $real;
  if ($s[8] =~ m/[\~|\&|\@|\%]/) {
    $channel{$s[3]}{'ops'}{$s[7]} = time;
  }
}

sub user_del {
  my ($nick) = lc(shift);
  delete $user{$nick};
  foreach (keys %channel)
  {
    delete $channel{$_}{ops}{$nick};
    delete $channel{$_}{users}{$nick};
  }
}

1;
