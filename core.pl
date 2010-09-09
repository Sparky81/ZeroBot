#!/usr/bin/perl

####################################
#      ZeroNET's Perl IRC Bot      #
#           Core Script            #
####################################
#       ZeroNET Information        #
#      Host - irc.zeronet.us       #
#          SSL Port: 6697          #
#    Project Channel - #ZeroBot    #
#################################### 

use strict;
use warnings;
require HelpTree;
require Persist;
require Class::Environment;
my $env = Environment->new();
my (@admin,@owner,@channels,$config);
loadconfig();
readchandb();
my $me = $config->{IRCnick};
my $ht_none = HelpTree::hnormal();
my $ht_admin = HelpTree::hadmin();
my $ht_owner = HelpTree::howner();
my $YES;

our @acl_none = ('ATS', 'BAN', 'CALC', 'DTS', 'KICK', 'KB', 'SAY', 'LAST', 'ACT', 'PING', 'ENVINFO', 'TRIGGER', 'UNBAN', 'WHOAMI');
our @acl_admin = ('ATS', 'BAN', 'CALC', 'CYCLE', 'DTS', 'LAST', 'JOIN', 'KICK', 'KB', 'PING', 'RAW', 'SAY', 'ACT', 'ENVINFO', 'ADMIN', 'JOIN', 'TRIGGER', 'PART', 'UNBAN', 'WHOAMI', 'WALLCHAN');
our @acl_owner = ('ATS', 'DELCHAN', 'ADDCHAN', 'MODLOAD', 'BAN', 'CALC', 'CYCLE', 'DTS', 'LAST', 'JOIN', 'KICK', 'KB', 'NICK', 'PING', 'RAW', 'SAY', 'ACT', 'ADMIN', 'ENVINFO', 'JOIN', 'TRIGGER', 'PART', 'UNBAN', 'DIE', 'RESTART', 'RELOAD', 'WHOAMI', 'WALLCHAN');
our @modlist = ();

# We will use a raw socket to connect to the IRC server.
use IO::Socket;

# Connect to the IRC server.
my $sock;
if ($config->{SSL})
{
	use IO::Socket::SSL;
	$sock = IO::Socket::SSL->new(
		PeerAddr	=>	$config->{IRCserver},
		PeerPort	=>	$config->{IRCport},
		Proto		=> 'tcp',
		Timeout		=> '30'
	) or die "Could not connect to ".$config->{IRCserver}.":".$config->{IRCport}." - $!\n";
} else {
	$sock = IO::Socket::INET->new(
		PeerAddr	=>	$config->{IRCserver},
		PeerPort	=>	$config->{IRCport},
		Proto		=>	'tcp',
		Timeout		=> '30'
	) or die "Could not connect to ".$config->{IRCserver}.":".$config->{IRCport}." - $!\n";
}

# Log on to the server.
senddata('NICK '.$config->{IRCnick});
senddata('USER '.$config->{IRCname}.' 8 * :Sparky\'s Perl IRC Bot');
my (%user,%channel,%cmd_);
# Read lines from the server until it tells us we have connected.
while (my $input = <$sock>) {
    $YES = 1;
    if ($input =~ /004/) {
		autojoin();
	if ($config->{ns_pass}) { privmsg('NickServ','IDENTIFY '.$config->{ns_pass}); }
        last;
    }
    elsif ($input =~ /433/) {
        $me = $me.'-';
		nick($me);
    }
}

# Keep reading lines from the server.
while (my $input = <$sock>) {
	chop $input;
	$input =~ s/^\s+//g;
	$input =~ s/\s+$//g;
	my @s = split(' ',$input);
	my $from = $s[0];
	$from =~ s/\://g;
	my @n = split('!',$from);
	my $nick = $n[0];
	my $target = $s[2];
	my $channel = $target;
	my $command = $s[1];
	$nick =~ s/\://g;
	if ($input =~ /^PING(.*)$/i) {
		senddata("PONG $1");
	}
	unless ($nick eq $me) {
		if ($command eq 'PRIVMSG') {
			my $cmd = $s[3];			
			$cmd =~ s/\://;
			$cmd = lc $cmd;
			my $trigger = substr($cmd,-(length($cmd)),1);
			my @a = split(' ',$input,5);
			my $args = $a[4];
			$args =~ s/\s+$// if $args;
			if ($target =~ m/^\#/) { # if this is a channel, otherwise it's a private message
				if ($trigger eq $config->{trigger}) {
					$cmd = substr($cmd,1);
					if ($cmd =~ 'help') {
					if (!defined $args) {
                            help($nick, $from);
                        } else { help_cmd($nick, $from, $args); }
					}	
					elsif ($cmd eq 'say') {
					if (!defined($args)) { cmd_needmoreparams($nick,$cmd);
					} else {
							privmsg($channel,$args);
							slog($nick.":SAY:".$args);
						}
					}
					elsif ($cmd eq 'act') {
						if (!defined($args)) { cmd_needmoreparams($nick, $cmd);
						} else {
							act($channel, $args);
							slog($nick.":ACT:".$args);
						}
					}
					elsif ($cmd eq 'raw') {
						if (!defined($args)) { cmd_needmoreparams($nick, $cmd);
						} elsif ((isadmin($from)) or (isowner($from))) {
							senddata($args);
							slog($nick.":RAW:".$args);
						}
					}
					elsif ($cmd eq 'envinfo') {
						envinfo($channel);
					}
					elsif ($cmd eq 'kick') {
						if (!defined($args)) { kick($channel,$nick);
						} elsif  (isop($nick,$channel)) {
							kick($channel,$args);
							slog($nick.":KICK:".$channel.":".$args);
						}
					}
					elsif ($cmd eq 'kickban') {
						if (!defined($args)) { cmd_needmoreparams($nick, $cmd);
						} elsif (isop($nick,$channel)) {
							kickban($channel,$args);
							slog($nick.":KICKBAN:".$channel.":".$args);
						}
					}
					elsif ($cmd eq 'ban') {
						if (!defined($args)) { cmd_needmoreparms($nick, $cmd);
						} elsif (isop($nick,$channel)) {
							ban($channel,$args);
							slog($nick.":BAN:".$channel.":".$args);
						}
					}
					elsif ($cmd =~ m/(j)oin/i) {
						if (!defined($args)) { cmd_needmoreparams($nick, $cmd);
						} elsif ((isadmin($from)) or (isowner($from))) {
							netjoin($args);
							notice($nick,"I have joined: $args");
							slog($nick.":JOIN:".$args);
						}
					}
					elsif ($cmd eq 'wallchan') {
						if (!defined($args)) 
						{ 
							cmd_needmoreparams($nick, $cmd); 
						} elsif ((isadmin($from)) or (isowner($from))) {
								wallchan("$args");
								slog($nick.":WALLCHAN:".$args);
						}
					}
					elsif ($cmd eq 'part') {
						if ((isadmin($from)) or (isowner($from))) {
							if (!defined($args)) 
							{
								 part($nick, $channel);
							} else { 
								part($nick, $channel, $args);
							}
						} else { cmd_failure($nick,$cmd); }
					}
					elsif ($cmd eq 'unban') {
					if (!defined($args)) { cmd_needmoreparams($nick, $cmd);
						} elsif (isop($nick,$channel)) {
							unban($channel,$args);
							slog($nick.":UNBAN:".$args);
						}
					}
					elsif ($cmd eq 'ats') {
						if (!defined($args)) { cmd_needmoreparams($nick, $cmd);
						} elsif (isop($nick,$channel)) {
							my @tt = split(' ',$args,2);
							my $t = $tt[0];
							my $ttt = $tt[1];
							$cmd_{lc($t)} = $ttt;
							notice($nick,"I have added the response that you requested");
							slog($nick.":ATS:".$args);
						}
					}
					elsif ($cmd eq 'uinfo') {
						if (!defined($args)) {
							cmd_needmoreparams($nick, $cmd);
						} elsif (isop($nick,$channel)) {
							privmsg($channel,userinfo($channel,$args));
							slog($nick.":UINFO:".$channel.":".$args);
						}
					}
					elsif ($cmd eq 'dts') {
						if (!defined($args))
						{
							cmd_needmoreparams($nick, $cmd);
						} else {
							delete $cmd_{lc($args)};
							notice($nick,"I have deleted all responses to the command you requested.");
							slog($nick.":DTS:".$args);
						}
					}
					elsif ($cmd eq 'trigger') {
					if (!defined($args))
					{
						cmd_needmoreparams($nick, $cmd);
					} elsif (isop($nick,$channel)) {
							privmsg($channel,"$nick: k.") if length $args eq 1;
							$config->{trigger} = $args;
							slog($nick.":TRIGGER:".$args);
						}
					}
					elsif ($cmd eq 'whoami') {
						if ((isadmin($from)) && (!isowner($from))) { notice($nick, "You are an administrator.");
						} elsif (isowner($from)) { notice($nick, "You are a bot owner.");
						} elsif ((!isadmin($from)) && (!isowner($from)) && (!isop($channel,$nick))) { 
							privmsg($channel, "You have no access on the bot or on this channel.");
						}
					}
					elsif ($cmd eq 'last') {
						lastcmd($channel);
					}
					elsif ($cmd eq 'addchan') {
						if (!defined($args)) { cmd_needmoreparams($nick, $cmd);
						} elsif (isowner($from)) { addchan($nick, $args); }
						else { cmd_failure($nick, $cmd); }
					}
					elsif ($cmd eq 'delchan') {
                        if (!defined($args)) { delchan($nick, $channel);
                        } elsif (isowner($from)) { delchan($nick, $args); }
                        else { cmd_failure($nick, $cmd); }
					}
					elsif ($cmd eq 'die') {
						if (isowner($from)) { signoff($nick, $args);
						} else { cmd_failure($nick, $cmd); }
					}
					elsif ($cmd eq 'modload') {
						if (!defined($args)) { cmd_needmoreparams($nick, $cmd);
						} elsif (isowner($from)) { modload($nick, $args);
						} else { cmd_failure($nick, $cmd); }
					}
					elsif ($cmd eq 'restart') {
						if (isowner($from)) { restart($nick, $args);
						} else { cmd_failure($nick, $cmd); }
					}
					elsif ($cmd eq 'nick') {
					if (!defined($args)) { cmd_needmoreparams($nick, $cmd);
					} elsif (isowner($from)) { 
						nick($args);
                        } else { cmd_failure($nick, $cmd); }
					}
					elsif ($cmd eq 'reload') {
						if (isowner($from)) {
							loadconfig();
							privmsg($channel,'Configuration reloaded.');
						} else { cmd_failure($nick, $cmd); }
					}
					elsif ($cmd eq 'cycle') {
						if ((isadmin($from)) or (isowner($from))) {
							if(!defined($args)) { cycle($nick, $channel);
							} else { cycle($nick, $channel, $args); }
						}
					}
					elsif ($cmd eq 'ping') {
						privmsg($channel, "Pong!");
					}
					elsif ($cmd eq 'calc') {
						if ($args eq 'fork while fork;') { cmd_badparams($nick, $cmd); }
						elsif ($args =~ m/exec(.+)?/i) { cmd_badparams($nick, $cmd); }
						elsif ($args =~ m/system(.+)?/i) { cmd_badparams($nick, $cmd); }
						elsif ($args =~ m/`(.+)?/i) { cmd_badparams($nick, $cmd); }
						elsif ($args =~ m/open(.+)?/i) { cmd_badparams($nick, $cmd); }
						elsif ($args =~ m/restart(.+)?/i) { cmd_badparams($nick, $cmd);	}
						elsif ($args =~ m/die(.+)?/i) { cmd_badparams($nick, $cmd); }
						elsif ($args =~ m/exit(.+)?/i) { cmd_badparams($nick, $cmd); }
						elsif ($args =~ m/notice(.+)?/i) { cmd_badparams($nick, $cmd); }
						elsif ($args =~ m/kill(.*?)/i) { cmd_badparams($nick, $cmd); }
						elsif ($args =~ m/privmsg(.+)?/i) { cmd_badparams($nick, $cmd); }
						elsif ($args =~ m/unshift(.+)?/i) { cmd_badparams($nick, $cmd); }
						elsif ($args =~ m/push(.+)?/i) { cmd_badparams($nick, $cmd); }
						elsif ($args =~ m/admin(.+)?/i) { cmd_badparams($nick, $cmd); }
						elsif ($args =~ m/owner(.+)?/i) { cmd_badparams($nick, $cmd); }
						elsif ($args =~ m/foreach(.+)?/i) { cmd_badparams($nick, $cmd); }
						elsif ($args =~ m/reverse(.+)?/i) { cmd_badparams($nick, $cmd); }
						elsif ($args =~ m/sendata(.+)?/i) { cmd_badparams($nick, $cmd);	}
						elsif ($args =~ m/print(.+)?/i) { cmd_badparams($nick, $cmd); }
						elsif ($args =~ m/cho(m)p(.+)?/i) { cmd_badparams($nick, $cmd); }
						elsif ($args =~ m/\$config/i) { cmd_badparams($nick, $cmd);	}
						else {
								my $result = eval($args); 
								privmsg($channel,"\002$nick\002: $args = $result") if defined $result;
								privmsg($channel,"\002$nick\002: Error.") unless defined $result;
						}
					}
				}
				else {
					if (exists $cmd_{lc($cmd)}) {
						my $ccmd = $cmd_{lc($cmd)};
						$ccmd =~ s/\$nick/$nick/g;
						$ccmd =~ s/\$ident/$user{$nick}{ident}/g;
						$ccmd =~ s/\$host/$user{$nick}{host}/g;
						privmsg($channel,$ccmd);
					}
				}
			} else { # private message
				if ($cmd eq "\1version\1") {
					notice($nick,"\1VERSION ZeroBot - Perl IRC Bot: Created by the ZeroNET Development Team\1");
				}
				if ($cmd eq "\1ping") {
					notice($nick,"\1PING $args");
				}
			}
		}
		if ($command eq 'KICK') {
			if ($s[3] eq $me) {
				netjoin($channel);
			}
		}
		if ($command eq 'MODE') {
			if ($target =~ m/^\#/) {
				who($channel);
			}
		}
		if ($command eq 'JOIN') {
			who($channel);
		}
		if ($command eq 'PART') {
			who($channel);
		}
		if ($command eq 'QUIT') {
			delete $user{$nick};
			foreach my $chn (keys %channel) {
				delete $channel{$chn}{'ops'}{$nick};
				delete $channel{$chn}{'users'}{$nick};
			}
		}
		if ($command eq '352') {
			my @r = split(' ',$input,11);
			my $real = $r[10];
			$channel{$s[3]}{'users'}{$s[7]} = time;
			$user{lc($s[7])}{'nick'} = $s[7];
			$user{lc($s[7])}{'ident'} = $s[4];
			$user{lc($s[7])}{'host'} = $s[5];
			$user{lc($s[7])}{'server'} = $s[6];
			$user{lc($s[7])}{'real'} = $real;
			if ($s[8] =~ m/[\~|\&|\@|\%]/) {
				$channel{$s[3]}{'ops'}{$s[7]} = time;
			}	
		}
		if ($command eq '353') {
			who($s[4]);
		}
	}
}
sub senddata {
	my $send = shift;
	print $sock "$send\r\n";
}
sub privmsg {
	my ($t,$msg) = @_;
	senddata("PRIVMSG $t :$msg");
}
sub act {
	my ($t,$msg) = @_;
	senddata("PRIVMSG $t :\001ACTION $msg\001");
}
sub notice {
	my ($t,$msg) = @_;
	senddata("NOTICE $t :$msg");
}
sub kick {
	my ($chan,$t) = @_;
	senddata("KICK $chan $t");
}
sub kickban {
	my ($chan,$t) = @_;
	my @tt = split(' ',$t,2);
	ban($chan,$tt[0]);
	senddata("KICK $chan $t");
}
sub mode {
	my ($chan,$t) = @_;
	senddata("MODE $chan $t");
}
sub unban {
	my ($chan,$t) = @_;
	$t =~ s/\s//g;
	if ($user{lc($t)}) {
		mode($chan,'-b *!*@'.$user{lc($t)}{'host'});
	}
}
sub ban {
	my ($chan,$t) = @_;
	$t =~ s/\s//g;
	if ($user{lc($t)}) {
		mode($chan,'+b *!*@'.$user{lc($t)}{'host'});
	}
}
sub part {
	my ($dst, $chan, $reason) = @_;
	if (!defined($reason))
	{
		senddata("PART $chan :\002PART\002 used by $dst.");
	} else {
		senddata("PART $chan :$reason");
	}
}
sub cycle {
	my ($dst, $chan, $reason) = @_;
	if (!defined($reason)) {
		senddata("PART $chan :\002CYCLE\002 used by $dst.");
		senddata("JOIN $chan");
	} else {
		senddata("PART $chan :$reason");
		senddata("JOIN $chan");
	}
}
sub netjoin {
	my $channel = $_[0]; 
	senddata("JOIN $channel");
#	push(@channels, $chan);
}
sub signoff {
	my ($dst, $why) = @_;
	if (!defined($why)) { senddata("QUIT :\002DIE\002 used by \002$dst\002 (No reason given.)"); 
	} else { senddata("QUIT :\002DIE\002 used by \002$dst\002 ($why)"); }
}
sub restart {
	my ($dst, $why) = @_;
	if (!defined($why)) { senddata("QUIT :\002RESTART\002 used by \002$dst\002 (No reason given.)");
	} else { senddata("QUIT :\002RESTART\002 used by \002$dst\002 ($why)"); }
	sleep(5);
	system('perl core.pl &');
}
sub who {
	my $chan = shift;
	delete $channel{$chan};
	senddata("WHO $chan");
}
sub isop {
	my ($nick,$chan) = @_;
	if ($channel{$chan}{'ops'}{$nick}) {
		return 1;
	}
	return;
}
sub isadmin {
	my $mask = lc(shift);
	my @adminregexps = ();
	foreach (@admin) {
		my $regexp = $_;
		$regexp =~ s/\./\\\./g;
		$regexp =~ s/\?/\./g;
		$regexp =~ s/\*/\.\*/g;
		$regexp = "^".$regexp."\$";
		$regexp = lc($regexp);
		push(@adminregexps,$regexp);
	}
	foreach (@adminregexps) {
		if ($mask =~ m/$_/) {
			return 1;
		}
	}
}
sub isowner {
    my $mask = lc(shift);
    my @ownerregexps = ();
    foreach (@owner) {
        my $regexp = $_;
        $regexp =~ s/\./\\\./g;
        $regexp =~ s/\?/\./g;
        $regexp =~ s/\*/\.\*/g;
        $regexp = "^".$regexp."\$";
        $regexp = lc($regexp);
        push(@ownerregexps,$regexp);
    }
    foreach (@ownerregexps) {
        if ($mask =~ m/$_/) {
            return 1;
        }
    }
}
sub userinfo {
	my ($chan,$nick) = @_;
	if ($user{lc($nick)}) {
		$nick = $user{lc($nick)}{'nick'};
		my $i;
		$i = 'is an op' if $channel{$chan}{'ops'}{$nick};
		$i = 'is not an op' unless $channel{$chan}{'ops'}{$nick};
		return $nick.'!'.$user{lc($nick)}{'ident'}.'@'.$user{lc($nick)}{'host'}.' ['.$user{lc($nick)}{'real'}.'] - '.$i;
	}
	return '?';
}
sub help {
	my ($dst, $from) = @_;
	@acl_none = sort { uc($a) cmp uc($b) } @acl_none;
	@acl_admin = sort { uc($a) cmp uc($b) } @acl_admin;
	@acl_owner = sort{ uc($a) cmp uc($b) } @acl_owner;

	my $acl = 'None';
	if ((!isadmin($from)) && (!isowner($from))) # normal
    {
		$acl = 'None';
    }
    elsif ((isadmin($from)) && (!isowner($from))) # admin
    {
    	$acl = 'Admin';
    }
    elsif (isowner($from)) # owner!
    {
         $acl = 'Owner';
    }
	
	notice($dst, "Your ACL: \002$acl\002.");
    notice($dst, "You have access to the following commands. To view more about each command, use ".$config->{trigger}."help \002COMMAND\002.");
	
	if ($acl eq 'None') { notice($dst, "@acl_none"); }
	elsif ($acl eq 'Admin') { notice($dst, "@acl_admin"); }
	elsif ($acl eq 'Owner') { notice($dst, "@acl_owner"); }
}
sub help_cmd {
	my ($dst, $host, $cmd) = @_;
    my $acl = 'None';
    if (isowner($host)) # owner!
    {
         $acl = 'Owner';
    }
    elsif ((isadmin($host)) && (!isowner($host))) # admin
						
    {
        $acl = 'Admin';
    }
    else {
	$acl = 'None';
    }

	$cmd = uc($cmd);
	if ($acl eq 'None')
	{ 
		if (exists($ht_none->{"$cmd"}))
		{ 
			notice($dst, "\002$cmd\002: ".$ht_none->{"$cmd"}.""); 
		} elsif ((exists($ht_admin->{"$cmd"})) or (exists($ht_owner->{"$cmd"}))) 
		{ 
			cmd_failure($dst, $cmd); 
		} else {
			cmd_notfound($dst, $cmd);
		}
	}  
	elsif ($acl eq 'Admin') 
	{ 
		if (exists($ht_admin->{"$cmd"}))
		{ 
			notice($dst, "\002$cmd\002: ".$ht_admin->{"$cmd"}.""); 
		} elsif (exists($ht_owner->{"$cmd"})) 
		{ 
			cmd_failure($dst, $cmd); 
		} else {
			cmd_notfound($dst, $cmd);
		}
	}
	elsif ($acl eq 'Owner') 
	{
		if (exists($ht_owner->{"$cmd"})) 
		{ 
		notice($dst, "\002$cmd\002: ".$ht_owner->{"$cmd"}."");
		} else {
			cmd_notfound($dst, $cmd);
		}
	}
}
sub addchan {
	my ($dst, $newchan) = @_;
	netjoin($newchan);
	open(DB, ">>channels.db") or notice($dst, "Could not open channels.db. ($!)");
	print DB "$newchan\n";
	close(DB);
	notice($dst, "Added \002$newchan\002 to database.");
}
sub delchan {
	my ($dst, $delchan) = @_;
	part($delchan);
	if (-e 'channels.db') {
		open(DB, 'channels.db');
		my @chans = <DB>;
		close(DB);
		
		@chans = grep !/^$delchan/, @chans;

		open(DB, '>channels.db');
		print DB @chans;
		close(DB);
		notice($dst, "Removed \002$delchan\002.");
	} else { notice($dst, "Could not locate \002channels.db\002."); }
}
sub readchandb {
	if (-e 'channels.db') {
		open(DB, 'channels.db');
		my @lines = <DB>;
		close(DB);
	    foreach my $line (@lines) {
	        chomp($line);
			unshift(@channels, $line);
		}
	}
}
sub nick {
	my $newnick = shift;
	senddata("NICK $newnick");
}
sub get_timestamp {
   my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
   if ($mon < 10) { $mon = "0$mon"; }
   if ($hour < 10) { $hour = "0$hour"; }
   if ($min < 10) { $min = "0$min"; }
   if ($sec < 10) { $sec = "0$sec"; }
   $year=$year+1900;

   return $mday . '-' . $hour . ':' . $min . ':' . $sec;
}
sub slog {
	my $data = shift;
	my $ts = get_timestamp();
	open(LOG, ">>log.txt");
	print LOG "[$ts] $data\n";
	close(LOG);
}
sub lastcmd {
	my $dst = shift;
	my $last = '';
	open(LOG, "log.txt");
	while(<LOG>) {
		$last = $_ if eof;
	}
	close(LOG);
	privmsg($dst, $last);
}
sub cmd_failure {
	my ($dst, $cmd) = @_;
	my $ts = get_timestamp();
	open(LOG, ">>log.txt");
	print LOG "[$ts] $dst FAILED to audit $cmd\n";
	close(LOG);
	notice($dst, "You are not authorized to audit \002$cmd\002. Your attempt has been logged.");
}
sub cmd_notfound {
	my ($dst, $cmd) = @_;
	notice($dst, "Command \002$cmd\002 is not found. Please check your spelling and try again.");
}
sub envinfo {
	my $dst = shift;
	privmsg($dst, "Operating System: ".$env->os);
	privmsg($dst, "UID: ".$env->uid);
	privmsg($dst, "Uptime: ".$env->uptime);
	privmsg($dst, "PID: ".$env->pid);
	privmsg($dst, "Working Path: ".$env->path);
}
sub cmd_needmoreparams {
	my ($dst, $cmd) = @_;
	$cmd = uc($cmd);
	notice($dst, "Not enough parameters for \002$cmd\002.");
}
sub cmd_badparams {
	my ($dst, $cmd) = @_;
	$cmd = uc($cmd);
	notice($dst, "Bad parameters supplied for \002$cmd\002.");
}
sub autojoin {
	foreach my $join (@channels) {
		netjoin($join);
	}
}
sub wallchan {
	my $wall = shift;
	foreach (@channels) {
		privmsg($_, $wall);
	}
}
sub loadconfig {
	open(CONFIG,'zerobot.conf') or die "Configuration could not be read\n";
	my @lines = <CONFIG>;
	@admin = ();
	@owner = ();
	close(CONFIG);
	my $i = 0;
	CONFPARSE: foreach my $line (@lines) {
		$i++;
		chomp($line);
		if ($line =~ m/^\#/) {
			next CONFPARSE;
		}
		if ($line =~ m/^server:(.+)$/) {
			$config->{'IRCserver'} = $1;
			next CONFPARSE;
		}
		if ($line =~ m/^port:([\d]+)$/) {
			$config->{'IRCport'} = $1;
			next CONFPARSE;
		}
		if ($line =~ m/^ssl:([true|false]+)$/) {
			$config->{'SSL'} = 1 if ($1 eq 'true');
			$config->{'SSL'} = 0 unless ($1 eq 'true');
			next CONFPARSE;
		}
		if ($line =~ m/^nick:(.+)$/) {
			$config->{'IRCnick'} = $1;
			my $me = $config->{'IRCnick'};
			next CONFPARSE;
		}
		if ($line =~ m/^ident:(.+)$/) {
			$config->{'IRCname'} = $1;
			next CONFPARSE;
		}
		if ($line =~ m/^channel:(.+)$/) {
		#	$config->{'homechan'} = $1;
			push(@channels, $1);
			next CONFPARSE;
		}
		if ($line =~ m/^nickserv:(.+)$/) {
			$config->{'ns_pass'} = $1;
			next CONFPARSE;
		}
		if ($line =~ m/^trigger:(.+)$/) {
			$config->{'trigger'} = $1;
			next CONFPARSE;
		}
		if ($line =~ m/^admin:(.+)$/) {
			push(@admin,$1);
			next CONFPARSE;
		}
		if ($line =~ m/^owner:(.+)$/) {
			push(@owner,$1);
			next CONFPARSE;
		}
		if ($line =~ m/^\s/) {
			next CONFPARSE;
		}
		die "Line $i of the configuration is invalid.\n";
	}
}
