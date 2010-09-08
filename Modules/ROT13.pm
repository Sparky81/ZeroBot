# Copyright (c) 2010 Samuel Hoffman

# The following must be done for ALL modules:
require HelpTree;
require 'core.pl';

# Adding to HELP TREES:
my $ht_none = HelpTree::hnormal();
my $ht_admin = HelpTree::hadmin();
my $ht_owner = HelpTree::howner();

# Access Level, Command Name, Command Description
# Access Levels: None, Admin, Owner

modinit('None',	'ROT13', 'Convert normal text to ROT13 and vice versa');

# Add to modlist to make sure it gets added:
push(@modlist, "ROT13");

# Code for command:
 
sub txt2rot {
	my ($dst, $txt) = @_;
	if (my($rot13) = $txt) {
		my $rot13 =~ tr[a-zA-Z][n-za-mN-ZA-M];
	}
	return $rot13;
}

1;
