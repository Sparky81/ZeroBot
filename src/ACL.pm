# Copyright (c) 2010 Samuel Hoffman
# Copyright (c) 2010 Mitchel Cooper
package ACL;
use strict;
use warnings;
use base 'Exporter';
our @EXPORT = qw(isowner isadmin isop isnig);
use Conf;
use System;

sub isadmin {
  my $mask = lc(shift);
  my @adminregexps = ();
  foreach (@admin) {
    my $regexp = $_;
    $regexp =~ s/\./\\\./g;
    $regexp =~ s/\?/\./g;
    $regexp =~ s/\*/\.\*/g;
    $regexp = "^".$regexp."\$";
    $regexp = lc($regexp);
    push(@adminregexps,$regexp);
  }
  foreach (@adminregexps) {
    if ($mask =~ m/$_/) {
      return 1;
    }
  }
  return 0;
}

sub isnig {
  my $mask = lc(shift);
  my @nigregexps = ();
  foreach my $key (sort(keys(%$blacklist))) {
    my $regexp = $$blacklist{$key};
    $regexp =~ s/\./\\\./g;
    $regexp =~ s/\?/\./g;
    $regexp =~ s/\*/\.\*/g;
    $regexp = "^".$regexp."\$";
    $regexp = lc($regexp);
    push(@nigregexps,$regexp);
  }
    foreach (@nigregexps) {
      if ($mask =~ m/$_/) {
        return 1;
      }
    }
  return 0
}

sub isowner {
    my $mask = lc(shift);
    my @ownerregexps = ();
    foreach (@owner) {
        my $regexp = $_;
        $regexp =~ s/\./\\\./g;
        $regexp =~ s/\?/\./g;
        $regexp =~ s/\*/\.\*/g;
        $regexp = "^".$regexp."\$";
        $regexp = lc($regexp);
        push(@ownerregexps,$regexp);
    }
    foreach (@ownerregexps) {
        if ($mask =~ m/$_/) {
            return 1;
        }
    }
    return 0;
}

sub isop {
        my ($nick, $chan) = @_;
        if ($channel{$chan}{'ops'}{$nick}) {
                return 1;
        }
        return 0;
}

1;
