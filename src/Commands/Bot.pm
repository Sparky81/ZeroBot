# Copyright (c) 2010 Samuel Hoffman
package Commands::Bot;
use strict;
use warnings;
use Message;
use HelpTree;
use Module;

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
    modload $module;
  }
});

cmd_add_chan({
  cmd => 'modunload',
  help => 'Unload a module.',
  acl => 'owner',
  code => sub {
    my ($channel, $dst, $module) = @_;
    $module = tr/::/\//;
    $module = $module.".pm";
    print $module;
    modunload $module;
  }
});

1;
