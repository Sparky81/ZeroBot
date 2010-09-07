# Copyright (c) 2010 ZeroNet Development Group
package HelpTree;
my $trigger = gettrigger();
our %helptree = (
	WHATIS => 'View more information about a specific command',
	CALC => 'Calculate an expression.',
	SAY => 'PRIVMSG a channel with data.',
	LAST => 'View last command sent to the bot.',
	HELP => 'View more information on a command.',
	PING => 'For users to check if they\'re still alive',
	ACT => 'Equivalent to /me sending to a channel.',
    WHOAMI => 'View your access level in the channel and/or bot.',
	ENVINFO => 'View working environment information',
);
our %helptree_o = (
    ATS => 'Associate word with response.',
    BAN => 'Ban a user from a channel.',
    CALC => 'Calculate an expression.',
    HELP => 'View more information on a command.',
    DTS => 'Delete a word association.',
    KICK => 'Kick a user from a channel.',
    WHOAMI => 'View your access level in the channel and/or bot.',
    KB => 'Kick and Ban a user from a channel.',
    SAY => 'PRIVMSG a channel with data.',
    LAST => 'View last command sent to the bot.',
    PING => 'For users to check if they\'re still alive',
    ACT => 'Equivalent to /me sending to a channel.',
    ENVINFO => 'View working environment information',
    TRIGGER => 'Change command trigger. (Current Trigger: .'.$config->{trigger}.')',
    UNBAN => 'Unban an address from the channel ban list.'
);
our %helptree_a = (
    ATS => 'Associate word with response.',
    BAN => 'Ban a user from a channel.',
    HELP => 'View more information on a command.',
    ENVINFO => 'View working environment information',
    CALC => 'Calculate an expression.',
	CYCLE => 'Have the bot cycle (part/join) a channel',
    DTS => 'Delete a word association.',
    PING => 'For users to check if they\'re still alive',
    LAST => 'View last command sent to the bot.',
    JOIN => 'Have bot join a channel.',
    KICK => 'Kick a user from a channel.',
    KB => 'Kick and Ban a user from a channel.',
    WALLCHAN => 'Message each channel defined in configuration.',
	RAW => 'Print raw data to the IRC Server.',
    WHOAMI => 'View your access level in the channel and/or bot.',
    SAY => 'PRIVMSG a channel with data.',
    ACT => 'Equivalent to /me sending to a channel.',
	ADMIN => 'Checks to see if user is an admin (you are if you\'re seeing this)',
	JOIN => 'NETJOIN the bot to a channel',
    TRIGGER => 'Change command trigger. (Current Trigger: .'.$config->{trigger}.')',
	PART => 'NETPART the bot from a channel',
    UNBAN => 'Unban an address from the channel ban list.'
);
our %helptree_q = (
    ATS => 'Associate word with response.',
    BAN => 'Ban a user from a channel.',
    WALLCHAN => 'Message each channel defined in configuration.',
    CYCLE => 'Have the bot cycle (part/join) a channel',
    CALC => 'Calculate an expression.',
    LAST => 'View last command sent to the bot.',
    HELP => 'View more information on a command.',
    ENVINFO => 'View working environment information',
    DTS => 'Delete a word association.',
    JOIN => 'Have bot join a channel.',
    PING => 'For users to check if they\'re still alive',
    KICK => 'Kick a user from a channel.',
    KB => 'Kick and Ban a user from a channel.',
    RAW => 'Print raw data to the IRC Server.',
	NICK => 'Change bot\'s current nick.',
    SAY => 'PRIVMSG a channel with data.',
    ACT => 'Equivalent to /me sending to a channel.',
    ADMIN => 'Checks to see if user is an admin (you are if you\'re seeing this)',
    JOIN => 'NETJOIN the bot to a channel',
    PART => 'NETPART the bot from a channel',
    UNBAN => 'Unban an address from the channel ban list.',
    TRIGGER => 'Change command trigger. (Current Trigger: '.$config->{trigger}.')',
	DIE => 'Force the bot to quit from the server and end its PID ('.$$.')',
	RESTART => 'Force the bot to disconnect from the server, and restart itself',
	WHOAMI => 'View your access level in the channel and/or bot.',
	RELOAD => 'Reload the configuration file and update admins, owners, etc.'
);

sub hnormal { return \%helptree; }
sub hop { return \%helptree_o; }
sub hadmin { return \%helptree_a; }
sub howner { return \%helptree_q; }
sub gettrigger {
	open(CONFIG,'zerobot.conf') or die "Configuration could not be read\n";
	my @lines = <CONFIG>;
	close(CONFIG);
	foreach my $line (@lines) {
		if ($line =~ m/^trigger:(.+)$/) {
			return $1;
		}
	}
}

1;
