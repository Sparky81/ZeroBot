# Copyright (c) 2010 Samuel Hoffman

# The following must be done for ALL modules:
require HelpTree;
require 'core.pl';

# Adding to HELP TREES:
my $ht_none = HelpTree::hnormal();
my $ht_admin = HelpTree::hadmin();
my $ht_owner = HelpTree::howner();

$ht_none->{'ROT13'} = 'Convert normal text to ROT13, and vice versa';
$ht_admin->{'ROT13'} = 'Convert normal text to ROT13, and vice versa';
$ht_owner->{'ROT13'} = 'Convert normal text to ROT13, and vice versa';

pop(@acl_none, "ROT13");
pop(@acl_admin, "ROT13");
pop(@acl_owner, "ROT13");

# Add to modlist to make sure it gets added:
pop(@modlist, "ROT13");

# Code for command:
 
sub txt2rot {
	my ($dst, $txt) = @_;
	if (my($rot13) == $txt) {
		my $rot13 =~ tr[a-zA-Z][n-za-mN-ZA-M];
	}
	return $rot13;
}

1;
