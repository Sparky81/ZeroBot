# Copyright (c) 2010 Samuel Hoffman
package Module;
use strict;
use warnings;
use base 'Exporter';
use Conf;
use Module::Load;
our @EXPORT = qw(
  cmd_add_chan cmd_add_privmsg on_join
  cmd_del_chan cmd_del_privmsg on_join_rm
  %chancmds %privmsgcmds %jcmds modload modunload
);

our (%chancmds, %privmsgcmds, %jcmds);

sub cmd_add_chan {
  my $class = caller;
  foreach (@_) {
    $chancmds{$_->{cmd}}{help} = $_->{help};
    $chancmds{$_->{cmd}}{code} = $_->{code};
    $chancmds{$_->{cmd}}{acl} = $_->{acl} if $_->{acl};
    $chancmds{$_->{cmd}}{syntax} = $_->{syntax} if $_->{syntax};
    $chancmds{$_->{cmd}}{init} = $_->{init} if $_->{init};
    $chancmds{$_->{cmd}}{init}->() if $_->{init};
    $chancmds{$_->{cmd}}{class} = $class;
  }
}

sub cmd_add_privmsg {
  my $class = caller;
  foreach (@_) {
    $privmsgcmds{$_->{cmd}}{help} = $_->{help};
    $privmsgcmds{$_->{cmd}}{code} = $_->{code};
    $privmsgcmds{$_->{cmd}}{class} = $class;
    $privmsgcmds{$_->{cmd}}{syntax} = $_->{syntax} if $_->{syntax};
    $privmsgcmds{$_->{cmd}}{acl} = $_->{acl} if $_->{acl};
    $privmsgcmds{$_->{cmd}}{init} = $_->{init} if $_->{init};
    $privmsgcmds{$_->{cmd}}{init}->() if $_->{init};
  }
}


sub on_join {
  my $class = caller;
  foreach (@_) {
    $jcmds{$_->{title}}{code} = $_->{code};
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

sub on_join_rm {
  my $class = caller;
  my $title = shift;
  if (!exists $jcmds{$title})
  {
    return;
  }
  delete $jcmds{$title};
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

sub modload {
  my $mod = shift;
  if (!$mod)
  {
    @module = ();
    foreach (@module) {
      if (eval { require $_; 1; }) {
        load $_;
      } else {
        return;
      }
    }
    return;
  }
  load $mod if $mod;
}

sub modunload {
  my $module = shift;
  delete $$module{$module};
}
1;
