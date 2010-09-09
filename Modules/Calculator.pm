# Copyright (c) 2010 Samuel Hoffman
require Persist;
use WWW::Google::Calculator;
modinit('None',	'CALCULATOR', 'Use Google Calculator to evaluate an expression.');
my $calc = WWW::Google::Calculator->new;

my $cmd = our $cmd_export;
my $args = our $args_export;
my $channel = our $channel_export;

if ($cmd eq 'gcalc')
{
	if(defined($args)) {
		my $result = gcalc($channel, $args);
		privmsg($channel, $result);
	}
}

sub gcalc {
	my ($dst, $exp) = @_;
	privmsg($dst, $calc->calc("$exp"));	
}
glob *gcalc;
1;
