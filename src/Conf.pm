# Copyright (c) 2010 Samuel Hoffman
use strict;
use warnings;
package Conf;
use Config::JSON;
use Cwd;
use base 'Exporter';
our @EXPORT = qw(load set get delete $c $config $channels @admin @owner);
our ($c, $config, $channels, @admin, @owner);
my $path = &getpath;
$c = Config::JSON->new($path);

sub getpath {
  my $dir = fastgetcwd;
  my $truncate = 0;
  while ($truncate < 3)
  {
      chop $dir;
        $truncate++;
  }
  $dir = $dir."zerobot.conf";
  return $dir;
}

sub load {
  $$config{server} = $c->get('IRC/server');
  $$config{ssl} = $c->get('IRC/ssl');
  $$config{port} = $c->get('IRC/port');
  $$config{homechan} = $c->get('IRC/home');

  $$config{nick} = $c->get('client/nick');
  $$config{ident} = $c->get('client/ident');
  $$config{gecos} = $c->get('client/gecos');

  $$config{trigger} = $c->get('client/trigger');

  @owner = $c->get('owners');
  @admin = $c->get('admins');
  my @chan = $c->get('channels');
  foreach (@chan) {
    $$channels{$_} = 'config';
  }
}

sub set {
  my ($dst, $directive, $value) = @_;
  $c->set($directive, $value) = @_;
  if ($@) { notice $dst, $@ and return }
  notice $dst, "Set \2$directive\2 to \2$value\2.";
}

sub delete {
  my ($dst, $directive) = @_;
  $c->delete($directive);
  if ($@) { notice $dst, $@ and return }
  notice $dst, "Deleted \2$directive\2.";
}

sub get {
  my ($directive) = @_;
  my $value = $c->get($directive);
  return $value;
}

1;
