# Copyright (c) 2010 Samuel Hoffman
package Commands::Bot;
use strict;
use warnings;
use Message;
use HelpTree;
use Module;
use System;

cmd_add_chan({
  cmd => 'help',
  help => 'View help information on specific commands.',
  code => sub {
    my ($channel, $dst, $args) = @_;
    help $dst if !$args;
    help_cmd $dst, $args if $args;
  }
});

cmd_add_chan({
  cmd => 'modload',
  help => 'Load a module via runtime to the bot.',
  acl => 'owner',
  code => sub {
    my ($channel, $dst, $module) = @_;
    if (eval {
      modload $module;
      1;
    }) {
      modload $module;
      notice $dst, "Loaded $module";
    } else {
      notice $dst, "Cannot find \2$module\2";
      return;
    }
  }
});

cmd_add_chan({
  cmd => 'modunload',
  help => 'Unload a module.',
  acl => 'owner',
  code => sub {
    my ($channel, $dst, $module) = @_;
    modunload $module;
  }
});

cmd_add_chan({
  cmd => 'restart',
  help => 'Disconnect from IRC, kill the current process, and start bot again.',
  acl => 'admin',
  code => sub {
    my ($channel, $dst, $reason) = @_;
    if (!$reason) {
      &Sock::close("RESTART by \2$dst\2 (No reason given.)");
      system "../../bot.sh";
      die;
    }
    elsif ($reason) {
      &Sock::close("RESTART by \2$dst\2 ($reason)");
      system "../bot.sh";
      die;
    }
  }
});

cmd_add_chan({
  cmd => 'die',
  help => 'Disconnect from IRC, and kill the current process ('.$$.')',
  acl => 'owner',
  code => sub {
    my ($channel, $dst, $reason) = @_;
      &Sock::close("DIE by \2$dst\2 (".($reason ? 'No reason given' : "$reason").")");
      die;
  }
});

cmd_add_chan({
  cmd => 'rehash',
  help => 'Re-read database and zerobot.conf.',
  code => sub {
    my ($channel, $dst) = @_;
    Conf::load();
    notice $dst, "Configuration reloaded.";
  }
});

cmd_add_chan({
  cmd => 'whoami',
  help => 'Check your status on the bot.',
  code => sub {
    my ($chan, $dst) = @_;
    my $host = $dst.'!'.$user{lc($dst)}{ident}.'@'.$user{lc($dst)}{host};
    my $admin = ACL::isadmin($host);
    my $owner = ACL::isowner($host);
    my $op = ACL::isop($chan, $dst);
    notice $dst, "Checked against host '$host'";
    notice $dst, "Admin: $admin";
    notice $dst, "Owner: $owner";
    notice $dst, "Op: $op";
  }
});

1;
