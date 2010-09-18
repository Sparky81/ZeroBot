#!/usr/bin/perl -w
# Copyright (c) 2010 Samuel Hoffman
require Persist;
use strict;
modinit('None',	'PASSWD', 'Generate a random password.');

sub randomPassword {
	my ($password, $_rand);
	my ($password_length) = shift;
    
	if (!$password_length) {
        	$password_length = 10;
    }

	my @chars = split(" ",
    	"a b c d e f g h i j k l m n o
    	p q r s t u v w x y z - _ % # |
    	0 1 2 3 4 5 6 7 8 9");

	srand;

	for (my $i=0; $i <= $password_length ;$i++) {
    	$_rand = int(rand 41);
    	$password .= $chars[$_rand];
	}
	return $password;
}

glob *randomPassword;
1;
