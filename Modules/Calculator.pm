# Copyright (c) 2010 Samuel Hoffman
require Persist;
use WWW::Google::Calculator;
modinit('None',	'CALCULATOR', 'Use Google Calculator to evaluate an expression.');
my $calc = WWW::Google::Calculator->new;
sub gcalc {
	my ($dst, $exp) = @_;
	privmsg($dst, $calc->calc("$exp"));	
}
glob *gcalc;
1;
