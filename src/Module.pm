# Copyright (c) 2010 Samuel Hoffman
package Module;
use strict;
use warnings;
use base 'Exporter';
use Conf;
use Module::Load;
our @EXPORT = qw(
  cmd_add_chan cmd_add_privmsg cmd_add_numeirc
  cmd_del_chan cmd_del_privmsg cmd_del_numeirc
  %chancmds %privmsgcmds %numericcmds
);

our (%chancmds, %privmsgcmds, %numericcmds);

sub cmd_add_chan {
  my $class = caller;
  foreach (@_) {
    $chancmds{$_->{cmd}}{help} = $_->{help};
    $chancmds{$_->{cmd}}{code} = $_->{code};
    $chancmds{$_->{cmd}}{acl} = $_->{acl} if $_->{acl};
  }
}

sub cmd_add_privmsg {
  my $class = caller;
  foreach (@_) {
    $privmsgcmds{$_->{cmd}}{help} = $_->{help};
    $privmsgcmds{$_->{cmd}}{code} = $_->{code};
    $privmsgcmds{$_->{cmd}}{acl} = $_->{acl} if $_->{acl};
  }
}

sub cmd_add_numeric {
  my $class = caller;
  foreach (@_) {
    $numericcmds{$_->{cmd}}{code} = $_->{code};
  }
}

sub cmd_del_chan {
  my $class = caller;
  my ($cmd) = shift;
  if (!exists $chancmds{$cmd}) {
    warn "Command ($cmd) called to unload, but not found";
    return;
  }
  delete $chancmds{$cmd};
}

sub cmd_del_privmsg {
  my $class = caller;
  my ($cmd) = shift;
  if (!exists $privmsgcmds{$cmd}) {
    warn "Command ($cmd) called to unload, but not found";
    return;
  }
  delete $privmsgcmds{$cmd};
}

sub cmd_del_numeric {
  my $class = caller;
  my ($cmd) = shift;
  if (!exists $numericcmds{$cmd}) {
    warn "Command ($cmd) called to unload, but not found";
    return;
  }
  delete $numericcmds{$cmd};
}

sub modload {
  foreach (@module) {
    load $_;
  }
}

sub modunload {
  my $module = shift;
  delete $$module{$module};
}
1;
