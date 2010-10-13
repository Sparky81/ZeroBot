# Copyright (c) 2010 ZeroNet Development Group
package HelpTree;
my $trigger = gettrigger();
our %helptree = (
	WHATIS => 'View more information about a specific command',
    ADDNIG => 'Add a host to the blacklist.',
    DELNIG => 'Remove a host from the blacklist.',

	CALC => 'Calculate an expression.',
	RANDQUOTE => 'Get a random quote from the database. (Added via ADDQUOTE)',
	ADDQUOTE => 'Add a quote to the database.',
        SAY => 'PRIVMSG a channel with data.',
	LAST => 'View last command sent to the bot.',
	HELP => 'View more information on a command.',
	PING => 'For users to check if they\'re still alive',
	LIST => 'List data about the bot. Valid options are CHANNELS, ADMINS, TS, QUOTES, NIGS, and OWNERS. (Syntax: LIST CHANNELS).',
	ACT => 'Equivalent to /me sending to a channel.',
	WHOAMI => 'View your access level in the channel and/or bot.',
	SYSINFO => 'View working environment information',
);
our %helptree_o = (
    ATS => 'Associate word with response.',
    BAN => 'Ban a user from a channel.',
    CALC => 'Calculate an expression.',
    HELP => 'View more information on a command.',
    DTS => 'Delete a word association.',
    LIST => 'List data about the bot. Valid options are CHANNELS, ADMINS, TS, QUOTES, NIGS, and OWNERS. (Syntax: LIST CHANNELS).',
    KICK => 'Kick a user from a channel.',
    ADDNIG => 'Add a host to the blacklist.',
    DELNIG => 'Remove a host from the blacklist.',

    WHOAMI => 'View your access level in the channel and/or bot.',
    KB => 'Kick and Ban a user from a channel.',
    SAY => 'PRIVMSG a channel with data.',
    LAST => 'View last command sent to the bot.',
    PING => 'For users to check if they\'re still alive',
    ACT => 'Equivalent to /me sending to a channel.',
    SYSINFO => 'View working environment information',
    TRIGGER => 'Change command trigger. (Current Trigger: .'.&gettrigger.')',
    UNBAN => 'Unban an address from the channel ban list.'
);
our %helptree_a = (
    ATS => 'Associate word with response.',
    BAN => 'Ban a user from a channel.',
    HELP => 'View more information on a command.',
    SYSINFO => 'View working environment information',
    CALC => 'Calculate an expression.',
        RANDQUOTE => 'Get a random quote from the database. (Added via ADDQUOTE)',
	DELQUOTE => 'Remove a quote from the database. Specify which number to remove.',
        ADDQUOTE => 'Add a quote to the database.',
	CYCLE => 'Have the bot cycle (part/join) a channel',
    LIST => 'List data about the bot. Valid options are CHANNELS, ADMINS, TS, QUOTES, NIGS, and OWNERS. (Syntax: LIST CHANNELS).',
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
    ADDNIG => 'Add a host to the blacklist.',
    DELNIG => 'Remove a host from the blacklist.',
	ADMIN => 'Checks to see if user is an admin (you are if you\'re seeing this)',
	JOIN => 'NETJOIN the bot to a channel',
    TRIGGER => 'Change command trigger. (Current Trigger: .'.&gettrigger.')',
	PART => 'NETPART the bot from a channel',
    UNBAN => 'Unban an address from the channel ban list.'
);
our %helptree_q = (
    ATS => 'Associate word with response.',
    ADDNIG => 'Add a host to the blacklist.',
    DELNIG => 'Remove a host from the blacklist.',
    BAN => 'Ban a user from a channel.',
    WALLCHAN => 'Message each channel defined in configuration.',
    CYCLE => 'Have the bot cycle (part/join) a channel',
        RANDQUOTE => 'Get a random quote from the database. (Added via ADDQUOTE)',
        DELQUOTE => 'Remove a quote from the database. Specify which number to remove.',
        ADDQUOTE => 'Add a quote to the database.',
    CALC => 'Calculate an expression.',
    LAST => 'View last command sent to the bot.',
    LIST => 'List data about the bot. Valid options are CHANNELS, ADMINS, TS, QUOTES, NIGS and OWNERS. (Syntax: LIST CHANNELS).',
    HELP => 'View more information on a command.',
    SYSINFO => 'View working environment information',
    DTS => 'Delete a word association.',
    JOIN => 'Have bot join a channel.',
    PING => 'For users to check if they\'re still alive',
    KICK => 'Kick a user from a channel.',
    KB => 'Kick and Ban a user from a channel.',
    DELCHAN => 'Remove a channel from the channel database. Note: Cannot remove any channels defined in zerobot.conf.',
	RAW => 'Print raw data to the IRC Server.',
	NICK => 'Change bot\'s current nick.',
    SAY => 'PRIVMSG a channel with data.',
    ACT => 'Equivalent to /me sending to a channel.',
    ADDCHAN => 'Join a channel and add it to the channel database.',
	ADMIN => 'Checks to see if user is an admin (you are if you\'re seeing this)',
    JOIN => 'NETJOIN the bot to a channel',
	MODLOAD => 'Load a custom module (Example: MODLOAD Modules/Password.pm)',    	
	PART => 'NETPART the bot from a channel',
    UNBAN => 'Unban an address from the channel ban list.',
    TRIGGER => 'Change command trigger. (Current Trigger: '.&gettrigger.')',
	CROAK => 'Force the bot to quit from the server and end its PID ('.$$.')',
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
