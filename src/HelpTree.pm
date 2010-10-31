# Copyright (c) 2010 ZeroNet Development Group
package HelpTree;
use strict;
use warnings;
use Module;
use Message;
use Conf;
use base 'Exporter';
our @EXPORT = qw(shorthelp help help_cmd);
our @chancmds;

sub conf {
  my $directive = shift;
  return $c->get($directive);
}

sub shorthelp {
  foreach (sort keys %chancmds) {
    push @chancmds, $_;
  }
}

sub help {
  my $dst = shift;
  shorthelp();
  notice $dst, "You have access to the following commands. To see more information about each, use ".&conf('client/trigger')."HELP \2COMMAND\2.";
  notice $dst, "@chancmds";
}

sub help_cmd {
  my ($dst, $cmd) = @_;
  if (!exists $chancmds{$cmd})
  {
    notice $dst, "\2".uc($cmd)."\2 not found.";
    return;
  }

  notice $dst, "\2".uc($cmd)."\2: $chancmds{$cmd}{help}";
}

1;
