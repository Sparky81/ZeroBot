# Copyright (c) 2010 Samuel Hoffman
package Module;
use strict;
use warnings;
use base 'Exporter';
our @EXPORT = qw(
  command_add
  command_del
  %commands
  %acl
  %code
);

our (%commands, %acl, %code);

sub command_add {
  my $class = caller;
  foreach (@_) {
    $commands{$_->{cmd}} = $_->{help};
    $acl{$_->{cmd}} = $_->{acl};
    $code{$_->{cmd}} = $_->{code};
  }
}

sub command_del {
  my $class = caller;
  my $cmd = shift;
  delete $commands{$_->{cmd}};
  delete $acl{$_->{cmd}};
  delete $code{$_->{cmd}};
}

1;
