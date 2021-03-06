#!/usr/bin/env perl

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

use Carp qw(carp cluck confess croak);
use DBI;
use Config::JSON;
my $c = Config::JSON->new(pathToFile => 'zerobot.conf');
require HelpTree;
require Persist;
$SIG{INT} = 'die';
$SIG{HUP} = 'rehash';
open ERROR, '>', "error.log" or croak "Could not open the error log. $!\n";
STDERR->fdopen(\*ERROR, 'w') or croak "Could not open the error log. $!\n";
unlink "pid.zerobot";
open(PID, ">>pid.zerobot") or confess "Could not open PID file. ($!)\n";
print PID "$$\n";
close(PID);
my ($greets,$blacklist,$config,@admin,@owner,$sock,$channels,$quoteslist);
&loadconfig;
my $dbargs = {
	AutoCommit => 1,
	RaiseError => 1 };
my $db = DBI->connect("dbi:SQLite:dbname=zero.db","","",$dbargs);
&dbread;
my $me = $$config{IRCnick};
my $ht_none = HelpTree::hnormal();
my $ht_admin = HelpTree::hadmin();
my $ht_owner = HelpTree::howner();
my $YES;

our @acl_none = ('ATS', 'ADDQUOTE', 'RANDQUOTE', 'LIST', 'BAN', 'CALC', 'DTS', 'KICK', 'KB', 'SAY', 'LAST', 'ACT', 'PING', 'SYSINFO', 'TRIGGER', 'UNBAN', 'WHOAMI');
our @acl_admin = ('ATS', 'DUMP', 'ADDGREET', 'DELGREET', 'ADDNIG', 'DELNIG', 'BAN', 'LIST', 'CALC', 'ADDQUOTE', 'RANDQUOTE', 'DELQUOTE', 'CYCLE', 'DTS', 'LAST', 'JOIN', 'KICK', 'KB', 'PING', 'RAW', 'SAY', 'ACT', 'SYSINFO', 'ADMIN', 'JOIN', 'TRIGGER', 'PART', 'UNBAN', 'WHOAMI', 'WALLCHAN');
our @acl_owner = ('ATS', 'CFG', 'DUMP', 'DELCHAN', 'LIST', 'ADDNIG', 'ADDGREET', 'DELGREET', 'DELNIG', 'ADDCHAN', 'MODLOAD', 'BAN', 'CALC', 'CYCLE', 'ADDQUOTE', 'DELQUOTE', 'RANDQUOTE', 'DTS', 'LAST', 'KICK', 'KB', 'NICK', 'PING', 'RAW', 'SAY', 'ACT', 'ADMIN', 'SYSINFO', 'JOIN', 'TRIGGER', 'PART', 'UNBAN', 'CROAK', 'RESTART', 'RELOAD', 'WHOAMI', 'WALLCHAN');
our @modlist = ();

use IO::Socket;

if ($config->{SSL})
{
	require IO::Socket::SSL;
	$sock = IO::Socket::SSL->new(
		PeerAddr	=>	$config->{IRCserver},
		PeerPort	=>	$config->{IRCport},
		Proto		=> 'tcp',
		Timeout		=> '30'
	) or croak "Could not connect to ".$config->{IRCserver}.":+".$config->{IRCport}." - $!\n";
} else {
	$sock = IO::Socket::INET->new(
		PeerAddr	=>	$config->{IRCserver},
		PeerPort	=>	$config->{IRCport},
		Proto		=>	'tcp',
		Timeout		=> '30'
	) or croak "Could not connect to ".$config->{IRCserver}.":".$config->{IRCport}." - $!\n";
}

senddata('NICK '.$config->{IRCnick});
senddata('USER '.$config->{IRCident}.' 8 * :'.$config->{IRCgecos});
my (%user,%channel,%cmd_);
&dbread;
while (my $input = <$sock>) {
	$YES = 1;
    if ($input =~ /004/) {
		senddata("MODE $me +B");
		autojoin();
		netjoin($config->{homechan});
	if ($config->{ns_pass}) { privmsg('NickServ','IDENTIFY '.$config->{ns_pass}); }
        last;
    }
    elsif ($input =~ /433/) {
	warn "It appears $me is already in use on ".$config->{IRCserver}.", concatenating to :".$me."-";
        $me = $me.'-';
		nick($me);
    }
}

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
			if ($target =~ m/^\#/) { 
				if ($trigger eq $config->{trigger}) {
					$cmd = substr($cmd,1);
					unless($cmd eq 'last') { slog($channel.":".$from.":".$cmd.":".$args) if ($args); }
					unless($cmd eq 'last') { slog($channel.":".$from.":".$cmd) if (!$args); }
					if ($cmd =~ 'help') {
						if (!defined $args) {
							help($nick, $from);
						} else { help_cmd($nick, $from, $args); }
					}	
					elsif ($cmd eq 'say') {
					if (!defined($args)) { cmd_needmoreparams($nick,$cmd);
					} else {
							privmsg($channel,$args);
						}
					}
					elsif ($cmd eq 'act') {
						if (!defined($args)) { cmd_needmoreparams($nick, $cmd);
						} else {
							act($channel, $args);
						}
					}
					elsif ($cmd eq 'raw') {
						if (!defined($args)) { cmd_needmoreparams($nick, $cmd);
						} elsif ((isadmin($from)) or (isowner($from))) {
							senddata($args);
						}
					}
					elsif ($cmd eq 'sysinfo') {
						sysinfo($channel);
					}
					elsif ($cmd eq 'list') {
						list($nick, $args);
					}
					elsif ($cmd =~ m/k(ick)?/i) {
						if (!defined($args)) { kick($channel,$nick);
						} elsif (isop($nick,$channel)) {
							kick($channel,$args);
						}
					}
					elsif ($cmd =~ m/(kickban|kb)/i) {
						if (!defined($args)) { cmd_needmoreparams($nick, $cmd);
						} elsif (isop($nick,$channel)) {
							kickban($channel,$args);
						}
					}
					elsif ($cmd eq 'ban') {
						if (!defined($args)) { cmd_needmoreparms($nick, $cmd);
						} elsif (isop($nick,$channel)) {
							ban($channel,$args);
						}
					}
					elsif ($cmd =~ m/j(oin)?/i) {
						if (!defined($args)) { cmd_needmoreparams($nick, $cmd);
						} elsif ((isadmin($from)) or (isowner($from))) {
							netjoin($args);
							notice($nick,"I have joined: $args");
						}
					}
					elsif ($cmd eq 'wallchan') {
						if (!defined($args)) 
						{ 
							cmd_needmoreparams($nick, $cmd); 
						} elsif ((isadmin($from)) or (isowner($from))) {
								wallchan("$args");
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
						}
					}
					elsif ($cmd eq 'ats') {
						if (!defined($args)) { cmd_needmoreparams($nick, $cmd);
						} elsif ((isowner($from)) or (isadmin($from))) {
							my @tt = split(' ',$args,2);
							my $t = $tt[0];
							my $ttt = $tt[1];
							$cmd_{lc($t)} = $ttt;
							my $row_ats = $db->do("INSERT INTO ATS (CALL, RESPONSE) VALUES (\"".lc($tt[0])."\", \"$tt[1]\");");
							if ($row_ats) { notice($nick,"Every time I see '\002$tt[0]\002', I will respond with, '\002$tt[1]\002'.");
							} else { notice($nick,"Could not add '$tt[0]' into the database. ($DBI::errstr)"); }
							slog($nick.":ATS:".$args);
						} else { cmd_failure($nick, $cmd); }
					}
					elsif ($cmd eq 'uinfo') {
						if (!defined($args)) {
							cmd_needmoreparams($nick, $cmd);
						} elsif (isop($nick,$channel)) {
							privmsg($channel,userinfo($channel,$args));
							slog($nick.":UINFO:".$channel.":".$args);
						}
					}
					elsif ($cmd eq 'cfg') {
						if(!defined($args)) {
							cmd_needmoreparams($nick, $cmd);
						} elsif (isowner($from)) {
							cfg($nick, $args);
						} else { cmd_failure($nick, $args); }
					}
					elsif ($cmd eq 'dts') {
						if (!defined($args))
						{
							cmd_needmoreparams($nick, $cmd);
						} elsif ((isowner($from)) or (isadmin($from))) {
							delete $cmd_{lc($args)};
							my @tt_rm = split(' ', $args, 2);
							my $t_rm = $tt_rm[0];
							my $delts = $db->do("DELETE FROM ATS WHERE CALL=\"".lc($tt_rm[0])."\";");
							notice($nick,"I will no longer respond when I see '\002$tt_rm[0]\002'.") if ($delts);
							slog($nick.":DTS:".$args);
						} else { cmd_failure($nick, $cmd); }
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
					elsif ($cmd eq 'randquote') {
						randquote($nick, $channel);
					}
					elsif ($cmd eq 'addquote') {
						addquote($nick, $args);
					}
					elsif ($cmd eq 'delquote') {
						if ((isadmin($from)) or (isowner($from))) {
							delquote($nick, $args);
						} else { cmd_failure($nick, $cmd); }
					}
					elsif ($cmd eq 'addnig') {
						if ((isadmin($from)) or (isowner($from))) {
							addnig($channel, $nick, $args);
						} else { cmd_failure($nick, $cmd) }
					}
                                        elsif ($cmd eq 'dump') {
                                                if ((isadmin($from)) or (isowner($from))) {
                                                        &dump($nick, $args);
                                                } else { cmd_failure($nick, $cmd) }
                                        }
					elsif ($cmd eq 'delnig') {
						if ((isadmin($from)) or (isowner($from))) {
							delnig($nick, $args);
						} else { cmd_failure($nick, $cmd); }
					}
					elsif ($cmd eq 'addgreet') {
						if ((isadmin($from)) or (isowner($from))) {
							addgreet($nick, $args);
						} else { cmd_failure($nick, $cmd); }
					}
					elsif ($cmd eq 'delgreet') {
						if ((isadmin($from)) or (isowner($from))) { delgreet($nick, $args);
						} else { cmd_failure($nick, $cmd); }
					}
					elsif ($cmd eq 'croak') {
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
							loadconfig($nick);
							privmsg($channel,'Configuration reloaded.');
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
                privmsg($channel, "$@") if $@;
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
				if ($cmd eq "\1ping\1") {
					notice($nick,"\1PING $args\1");
				}
			}
		}
		if ($command eq 'KICK') {
			if ($s[3] eq $me) {		
				netjoin($channel);
				cluck "I was just kicked from $channel";
			}
		}
		if ($command eq 'MODE') {
			if ($target =~ m/^\#/) {
				who($channel);
			}
		}
		if ($command eq 'JOIN') {
			who($channel);
			if (defined($$greets{lc($n[0])}))
			{
				privmsg(substr($channel, 1), "[$n[0]] ".$$greets{lc($n[0])});
			}
			if ((isowner($from) and (isop($me, substr($channel, 1)))) and ($$config{autoop_owner} == 1)) {
				senddata("MODE ".substr($channel, 1)." +o $n[0]");
			}
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
			my $checkhost = $s[7].'!'.$s[4].'@'.$s[5];
			if (isnig($checkhost)) {
				privmsg($s[3], "\002$s[7]\002, you match a blacklisted host in my database.") if (isop($s[3], $me));
				kickban($s[3], $s[7]) if (isop($s[3], $me));
			}
		}
		if ($command eq '353') {
			who($s[4]);
		}
		if ($command eq '474') {
			carp "I've been banned from $s[3]";
			if ($s[3] ne $$config{homechan}) { privmsg($$config{homechan}, "I've been banned from \002$s[3]\002."); }
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
	if ($t ne $me) {
		senddata("KICK $chan $t");
	} else { privmsg($chan, "I'm not going to kick myself."); }
}
sub kickban {
	my ($chan,$t) = @_;
	if ($t ne $me) {
		my @tt = split(' ',$t,2);
		ban($chan,$tt[0]);
		senddata("KICK $chan $t");
	} else { privmsg($chan, "I'm not going to ban myself."); }
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
	if (defined($chan)) {
		if (!defined($reason))
		{
			senddata("PART $chan :\002PART\002 used by $dst.");
		} else {
			senddata("PART $chan :$reason");
		}
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
}
sub signoff {
	my ($dst, $why) = @_;
	if (!defined($why)) { senddata("QUIT :\002CROAK\002 used by \002$dst\002 (No reason given.)");
							croak "DIE used by $dst\n"; 
	} else { senddata("QUIT :\002CROAK\002 used by \002$dst\002 ($why)"); }
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
sub timestamp {
  my $now = time;
  return $now;
}
sub now {
  my $now = localtime;
  return $now;
}
sub dump {
  my ($dst, $opt) = @_;
  open(DUMP, ">dump.txt") or notice $dst, "Could not open file for dumping. ($!)" and return;
  
  print DUMP "NOW => (\n";
  print DUMP "\tTIMESTAMP => '".&timestamp."'\n";
  print DUMP "\tLOCAL => '".&now."'\n";
  print DUMP ");\n\n";

  # Dump Channels:
  print DUMP "channels {\n";
  foreach my $key (sort(keys(%$channels))) {
    print DUMP "\t$key => '$$channels{$key}'\n";
  }
  print DUMP "};\n\n";

  # Dump Admins:
  print DUMP "admins {\n";
  foreach (@admin) {
    print DUMP "\t'$_'\n";
  }
  print DUMP "};\n\n";

  # Dump Owners
  print DUMP "owners {\n";
  foreach (@owner) {
    print DUMP "\t'$_'\n";
  }
  print DUMP "};\n\n";

  # Dump Users 
  print DUMP "users {\n";
  while (my($key, $value) = each(%user)) {
    print DUMP "\t$key => '$value'\n";
  }
  print DUMP "};\n\n";

  # Dump Who
  print DUMP "who {\n";
  while (my($key, $value) = each(%channel)) {
    print DUMP "\t$key => '$value'\n";
  }
  print DUMP "};\n\n";

  print DUMP "ts {\n";
  while (my($key, $value) = each(%cmd_)) {
   print DUMP "\t$key => '$value'\n";
  }
  print DUMP "};\n\n";

  print DUMP "quotes {\n";
  while (my($key, $value) = each(%$quoteslist)) {
    print DUMP "\t$key => '$value'\n";
  }
  print DUMP "};\n\n";

  print DUMP "greets {\n";
  while (my($key, $value) = each(%$greets)) {
    print DUMP "\t$key => '$value'\n";
  }
  print DUMP "};\n\n";

  print DUMP ":EOF\n";
  close(DUMP) or notice $dst, "Could not save dumpfile. ($!)";
  notice $dst, "Dump complete and saved to \2dump.txt\2.";
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
sub isnig {
        my $mask = lc(shift);
        my @nigregexps = ();
	foreach my $key (sort(keys(%$blacklist))) {
		my $regexp = $$blacklist{$key};
                $regexp =~ s/\./\\\./g;
                $regexp =~ s/\?/\./g;
                $regexp =~ s/\*/\.\*/g;
                $regexp = "^".$regexp."\$";
                $regexp = lc($regexp);
                push(@nigregexps,$regexp);
        }
        foreach (@nigregexps) {
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
sub cfg {
	my ($dst, $setting) = @_;
	if ($setting =~ m/autoop_owner ([0-1])/i)
	{
		$c->set('set/autoop_owner', 1) if ($1 == 1);
		$c->set('set/autoop_owner', 0) if ($1 == 0);
		notice($dst, "Will now Auto Op all bot owners if they join a channel I have op in.") if ($1 == 1);
		notice($dst, "Owners will not be auto opped on join.") if ($1 == 0);
	}
	elsif ($setting =~ m/autoop_admin ([0-1])/i)
	{
		$c->set('set/autoop_admin', 1) if ($1 == 1);
		$c->set('set/autoop_admin', 0) if ($1 == 0);
		notice($dst, "will now Auto Op all bot admins if they join a channel I ahve op in.") if ($1 == 1);
		notice($dst, "Admins will not be auto opped on join.") if ($1 == 0);
	} else { notice($dst, "\2$setting\2 is invalid for command \2CFG\2."); }
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
sub addgreet {
	my ($dst, $greet) = @_;
	if ($greet =~ m/^([A-Za-z]+) (.+)/)
	{
		my $gnick = lc($1);
		my $gmsg = $2;
		my $row = $db->do("INSERT INTO GREETS (NICK, MSG) VALUES (\"$gnick\", \"$gmsg\");");
		if ($row) {
			$$greets{$gnick} = $gmsg;
			notice($dst, "Each time \002$gnick\002 joins a channel I'm in, I will say: '[$gnick] $gmsg'");
		} else { notice($dst, "Unable to add a greet message for \002$gnick\002."); }
	}
}
sub delgreet {
	my ($dst, $nick) = @_;
	$nick = lc($nick);
	if ($$greets{$nick}) {
		my $row = $db->do("DELETE FROM GREETS WHERE NICK=\"$nick\";");
		notice($dst, "Deleted \002${nick}'s greet message, which was: '\002$$greets{$nick}\002'.");
		delete($$greets{$nick});
	} else { notice($dst, "Unable to delete greet message for \002$nick\002."); }
}
sub addchan {
	my ($dst, $newchan) = @_;
	$newchan = lc($newchan);
	if ($newchan =~ m/^#/) {
		if (-e 'zero.db') {
			netjoin($newchan);
			my $row = $db->do("INSERT INTO CHANNELS (CHANNEL) VALUES (\"$newchan\");");
			if (defined($row))
			{
				$channels->{$newchan} = 'db';
				notice($dst, "\002$newchan\002 succesfully added to database.");
			} else { notice($dst, "Could not add \002$newchan\002 to the database."); }
		} else { notice($dst, "Could not add $newchan because \002zero.db\002 does not exist."); }
	} else { notice($dst, "\002$newchan\002 is not a valid channel name! Prefix it with '#', and try again."); }
}
sub delchan {
	my ($dst, $delchan) = @_;
	$config->{homechan} = lc($config->{homechan});
	$delchan = lc($delchan);
	if ($delchan =~ m/^#/) {
		if ((-e 'zero.db') and ($delchan ne $config->{homechan}) and (defined($channels->{$delchan}))) {
	        	my $row = $db->do("DELETE FROM CHANNELS WHERE CHANNEL=\"$delchan\";");
			if (defined($row))
			{
				delete($channels->{"$delchan"});
				part($dst, $delchan, "Channel ($delchan) being removed by \002$dst\002.");
				notice($dst, "Removed \002$delchan\002.");
			} else { notice($dst, "Could not remove \002$delchan\002 from the database."); }
		} elsif ($delchan eq $config->{homechan}) { notice($dst, "Cannot delete \002$delchan\002, it's my home channel."); 
		} elsif (!$channels->{$delchan}) { notice($dst, "\002$delchan\002 is non-existant."); } else { notice ($dst, "Cannot locate database file."); }
	} else { notice($dst, "Cannot delete \002$delchan\002 from database: it is not a valid channel, so it won't exist!"); }
}
sub addnig {
	my ($channel, $dst, $nighost) = @_;
	if (!$nighost) {
		notice($dst, "You did not specify a host to blacklist.");
		return;
	}
	if (($nighost eq '*!*@*') or ($nighost eq '*@*'))
	{
		notice($dst, "Banning \002$nighost\002 is too large of a subnet. Be more specific.");
		return;
	}
	if ((isadmin($nighost)) or (isowner($nighost))) {
		notice($dst, "\002$nighost\002 matches that of an admin/owner, so it will not be added to the blacklist.");
		return;
	}
	if ((isnig($nighost)) or ($$blacklist{$nighost})) {
		notice ($dst, "\002$nighost\002 already matches a blacklisted host, so there's no reason to add it.");
		return;
	}
	if ($nighost !~ m/^(.*)!(.*)\@(.*)/) {
		notice($dst, "\002$nighost\002 is not a valid hostmask.");
		return;
	}
	my $row = $db->do("INSERT INTO BLACKLIST (HOST) VALUES (\"$nighost\");");
	if ($row) {
		$$blacklist{$nighost} = $nighost;
		notice($dst, "Added \002$nighost\002 to the blacklist. All users matching this host on their next join to a channel I have +o in will be kickbanned.");
		who($channel);
	} else { notice($dst, "Unable to add \002$nighost\002 to the blacklist."); }
}
sub delnig {
	my ($dst, $nighost) = @_;
	if ((!isnig($nighost) or (!$$blacklist{$nighost}))) {
		notice($dst, "\002$nighost\002 does not match a blacklisted host, so there's no use in trying to remove it.");
		return;
	}
	my $row = $db->do("DELETE FROM BLACKLIST WHERE HOST=\"$nighost\";");
	if ($row) {
		delete($$blacklist{$nighost});
		notice($dst, "Removed \002$nighost\002 from the blacklist. Users matching this host will be able to rejoin without being kickbanned.");
	}
}
sub list {
	my ($dst, $option) = @_;
	my ($o_limit, $n_limit, $a_limit, $g_limit, $t_limit, $c_limit, $q_limit) = 0;
	$option = lc($option);
	if ($option eq 'greets')
	{
		notice($dst, "\2GREET LIST\2:");
		foreach my $key (sort(keys(%$greets))) {
			$g_limit++;
			notice($dst, "\2NICK\2: $key, \2GREET\2: \"$$greets{$key}\"");
		}
		cluck "$g_limit entries in the greet list. LIsting may cause lag/flood" if ($g_limit > 10);
	}
	elsif ($option eq 'channels')
	{
		notice($dst, "\002CHANNEL LIST\002:");
                notice($dst, "\002Home Channel\002: $config->{homechan}");
                foreach my $key (sort(keys(%$channels))) {
			$c_limit++;
			notice($dst, "$key [$$channels{$key}]");
    		}
		cluck "$c_limit entries in channels table. Listing may cause lag/flood." if ($c_limit > 10);
	}
	elsif ($option eq 'owners')
	{
		$o_limit++;
		notice($dst, "\002BOT OWNER LIST\002:");
		foreach (@owner) { notice($dst, "$_"); }
		cluck "$o_limit entries in the owners array. Listing may cause lag/flood." if ($o_limit > 10);
	}
	elsif ($option eq 'admins')
	{
		$a_limit++;
		notice($dst, "\002BOT ADMIN LIST\002:");
		foreach (@admin) { notice($dst, "$_"); }
		cluck "$a_limit entries in the admins array. Listing may cause lag/flood." if ($a_limit > 10);
	}
	elsif ($option eq 'ts')
	{
		notice($dst, "\002CALL-RESPONSE LIST\002:");
		foreach my $key (sort(keys(%cmd_))) {
			$t_limit++;
			notice($dst, "CALL: \"\002$key\002\" RESPONSE: \"\002$cmd_{$key}\002\"");
		}
		cluck "$t_limit entries in the TS table. Listing may cause lag/flood." if ($t_limit > 10);
	}
	elsif ($option eq 'quotes')
	{
		notice($dst, "\002QUOTES DATABASE\002:");
		foreach my $key (sort(keys(%$quoteslist))) {	
			$q_limit++;
			notice($dst, "#:\002$key\002, QUOTE:\"\002$$quoteslist{$key}\002\"");
		}
		cluck "$q_limit entires in Quotes table. Listing may cause lag/flood." if ($q_limit > 10);
	}
	elsif ($option eq 'nigs')
	{
		$n_limit++;
		foreach my $key (sort(keys(%$blacklist))) {
			notice($dst, "$$blacklist{$key}");
		
		}
		cluck "$n_limit entries in niglist. Listing may cause lag/flood" if ($n_limit > 10);
	} else { notice($dst, "\2".uc($option)."\2 is not a valid flag for \2LIST\2."); }

}
sub nick {
	my $newnick = shift;
	senddata("NICK $newnick");
	$me = $newnick;
}
sub die {
  senddata("QUIT :Caught SIGINT, exiting.");
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
	my $ts = now();
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
	cluck "$dst attempted to audit $cmd.";
	close(LOG);
	notice($dst, "You are not authorized to audit \002$cmd\002. Your attempt has been logged.");
}
sub cmd_notfound {
	my ($dst, $cmd) = @_;
	carp "$dst issued $cmd, which could not be found.";
	notice($dst, "Command \002$cmd\002 is not found. Please check your spelling and try again.");
}
sub sysinfo {
	my $dst = shift;
	my $uptime = `uptime`;
	my $uname = `uname -a`;
	my $issue = `cat /etc/issue`;
	my $version = `cat /proc/version`;
	privmsg($dst, "\2Kernel\2: $^O :: \2Uptime\2: $uptime");
	privmsg($dst, "\2PID\2: $$ :: \2Issue\2: $issue");
	privmsg($dst, "\2Version\2: $version");
	privmsg($dst, "\2Uname\2: $uname");
}
sub cmd_needmoreparams {
	my ($dst, $cmd) = @_;
	$cmd = uc($cmd);
	carp "$dst issued $cmd, but did not supply enough parameters.";
	notice($dst, "Not enough parameters for \002$cmd\002.");
}
sub cmd_badparams {
	my ($dst, $cmd) = @_;
	$cmd = uc($cmd);
	carp "$dst issued $cmd, but supplied wrong parameters.";
	notice($dst, "Bad parameters supplied for \002$cmd\002.");
}
sub autojoin {
  	my $ajoin = 0;
    while (my($key, $value) = each(%$channels)) {
        netjoin($key);
	$ajoin++;
    }
	cluck "I've joined over $ajoin channels at once." if ($ajoin > 10);
}
sub wallchan {
	my $wall = shift;
    	while (my($key, $value) = each(%$channels) ) {
        	privmsg($key, "$wall");
    	}

}
sub addquote {
	my ($dst, $quote) = @_;
	if ($quote) {
		my $aq_row = $db->do("INSERT INTO QUOTES (QUOTE, CREATOR) VALUES (\"$quote\", \"$dst\");");
		my $count = $db->selectrow_array("SELECT COUNT(*) FROM QUOTES;");
		my $q_newnum = $count + 1;
		$$quoteslist{$q_newnum} = $quote;
		notice($dst, "Added \"\002$quote\002\" to database.") if $aq_row;
		notice($dst, "Unable to add quote to database.") if !$aq_row;
	} else { notice($dst, "You did not supply a quote to add."); }
}
sub delquote {
	my ($dst, $qnum) = @_;
	if ($qnum) {
		my $dq_row = $db->do("DELETE FROM QUOTES WHERE QUOTESKEY=\"$qnum\";");
		delete($$quoteslist{$qnum});
		notice($dst, "Removed quote \002#$qnum\002 from the database.") if $dq_row;
		notice($dst, "Could not find \002#$qnum\002 in the database.") if !$dq_row;
	} else { notice($dst, "You have not defined which number quote to delete."); }
}
sub randquote {
	my ($dst, $channel) = @_;
        my $count = $db->selectrow_array("SELECT COUNT(*) FROM QUOTES;");
	if ($count) {
		my $rand = int(rand($count)) + 1;
		my $quote = $db->selectall_arrayref("SELECT * FROM QUOTES WHERE QUOTESKEY=\"$rand\";");
		foreach my $quoterow (@$quote) {
			my ($n, $q, $c) = @$quoterow;
			privmsg($channel, "[#] Quote \002$n\002/$count [#] $q [#] Added by \002$c\002. [#]");
		}
	} else { privmsg($channel, "There appear to be no quotes in the database. Add some with $$config{trigger}ADDQUOTE."); }
}
sub dbread {
	my $chans = $db->selectall_arrayref("SELECT * FROM CHANNELS;");
	my $tslist = $db->selectall_arrayref("SELECT * FROM ATS;");
	my $quotes = $db->selectall_arrayref("SELECT * FROM QUOTES;");
	my $blacklist_db = $db->selectall_arrayref("SELECT * FROM BLACKLIST;");
	my $greetlist = $db->selectall_arrayref("SELECT * FROM GREETS;");

	foreach my $chanrow (@$chans) {
		my ($cname) = @$chanrow;
		$channels->{ $cname } = 'db'; 
	}

	foreach my $tsrow (@$tslist) {
		my ($call, $response) = @$tsrow;
		$cmd_{$call} = $response;
	}

	foreach my $quoterow (@$quotes) {
		my ($n, $q, $c) = @$quoterow;
		$$quoteslist{$n} = $q;
	}

	foreach my $blrow (@$blacklist_db) {
		my ($host) = @$blrow;
		$$blacklist{$host} = $host;
	}

	foreach my $grow (@$greetlist) {
		my ($nick, $msg) = @$grow;
		$nick = lc($nick);
		$$greets{$nick} = $msg;
	}
}
sub loadconfig {
	my $dst = shift;
	if (-e 'zerobot.conf') {
		$$config{IRCnick} = $c->get('client/nick');
		$$config{IRCident} = $c->get('client/ident');
		$$config{IRCgecos} = $c->get('client/gecos');
		$$config{IRCserver} = $c->get('IRC/server');
		$$config{IRCport} = $c->get('IRC/port');
		$$config{trigger} = $c->get('client/trigger');
		$$config{homechan} = $c->get('IRC/home');
		$$config{ns_pass} = $c->get('client/nickserv');
		$$config{SSL} = $c->get('IRC/ssl');
		
		if (($c->get('set/autoop_owner') == 1) or ($c->get('set/autoop_owner') == 0))
		{
			$$config{autoop_owner} = $c->get('set/autoop_owner');
		} else { 
			notice($dst, "\2".$c->get('set/autoop_owner')."\2 is not a valid setting for \2set/autoop_owner\2") if ($dst);
			croak $c->get('set/autoop_owner')." is not a valid setting for set/autoop_owner" if (!$dst);
		}
	
		my $confchans = $c->get('channels');
		my $confowners = $c->get('owners');
		my $confadmins = $c->get('admins');
		
		foreach (@$confchans) {
			$$channels{$_} = 'config';
		}

		foreach (@$confowners) {
			push(@owner, $_);
		}

		foreach (@$confadmins) {
			push(@admin, $_);
		}
	
	} else {
		if ($dst) {
			notice($dst, "FATAL: Could not find zerbot.conf. Do not attempt to run any commands until I have found it.");
			cluck "Could not find zerbot.conf - this is fatal";
		} else { croak "Could not find zerbot.conf."; }
	}
		if ($dst) {
		if(!$config->{IRCnick}) { notice($dst, "You have not defined a nickname for the bot. This is required."); }
		if(!$config->{IRCident}) { notice($dst, "You have not defined an ident for the bot. This is required."); }
		if(!$config->{IRCport}) { notice($dst, "You have not defined a port for the bot to connect to. This is required."); }
		if(!$config->{IRCserver}) { notice($dst, "You have not defined an IRC Server for the bot to connect to. This is required."); }
		if(!$config->{IRCgecos}) { notice($dst, "You have not defined a GECOS (realname) for the bot. This is required."); }
		if(!$config->{trigger}) { notice($dst, "You have not defined a valid command trigger for the bot. This is required."); }
		if(!$config->{homechan}) { notice($dst, "You ahve not defined a home channel. This is required."); }
	} 
}
