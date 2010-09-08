# Copyright (c) 2010 Samuel Hoffman
#
# None of this is actually used (yet), we're saving it
# to see if anyone can actually fix the bug:
# Can't modify non-lvalue subroutine call at ./core.pl line 708.
# When using $config->IRCserver rather than $config->{'IRCserver'}
package Config;
use Moose;

has 'IRCserver' => (
	isa => 'Str',
	is => 'rw',
);

has 'IRCport' => (
	isa => 'Int',
	is => 'rw',
);

has 'ssl' => (
	isa => 'Str',
	is => 'rw',
	default => 'false'
);

has 'IRCnick' => (
	isa => 'Str',
	is => 'rw',
	default => 'ZeroBot'
);

has 'IRCname' => (
	isa => 'Str',
	is => 'rw',
	default => 'ZeroBot'
);

has 'nickserv' => (
	isa => 'Str',
	is => 'rw'
);

has 'trigger' => (
	isa => 'Str',
	is => 'rw',
	default => '~'
);

1;
