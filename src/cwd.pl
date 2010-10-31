#!/usr/bin/env perl
use strict;
use warnings;

use Cwd;

my $dir = cwd;
my $truncate = 0;
print "Before: $dir\n";
while ($truncate < 3)
{
  chop $dir;
  $truncate++;
}
$dir = $dir."zerobot.conf";
print "After: $dir\n";
