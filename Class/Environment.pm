# Copyright (c) 2010 Samuel Hoffman
# All Rights Reserved
package Environment;
use Moose;
my $uptime = `uptime`;
my $path = `pwd`;

has 'uptime' => (
	isa => 'Str',
	is => 'ro',
	default => $uptime
);

has 'os' => (
	isa => 'Str',
	is => 'ro',
	default => $^O
);

has 'pid' => (
	isa => 'Int',
	is => 'ro',
	default => $$
);

has 'uid' => (
	isa => 'Int',
	is => 'ro',
	default => $<
);

has 'path' => (
	isa => 'Str',
	is => 'ro',
	default => $path
);

1;
