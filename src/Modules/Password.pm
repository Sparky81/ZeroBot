# Copyright (c) 2010 Samuel Hoffman
package Modules::Password;
use strict;
use warnings;
use Module;
use Message;
our ($password, $_rand);

cmd_add_chan({
  cmd => 'passwd',
  help => 'Generate a random password. Default length is 10 characters.',
  code => sub {
  	my ($chan, $dst, $length) = @_;
    
  	if (!$length) {
         	$length = 10;
     }

  	my @chars = split(" ",
      	"a b c d e f g h i j k l m n o
      	p q r s t u v w x y z - _ % # |
        0 1 2 3 4 5 6 7 8 9");

    srand;

    for (my $i=0; $i <= $length ;$i++) {
      $_rand = int(rand 41);
      $password .= $chars[$_rand];
    }
    notice $dst, "$password";
  }
});

1;
