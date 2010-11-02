# Copyright (c) 2010 Samuel Hoffman
package Database;
use strict;
use warnings;
use DBI;
use DBD::SQLite;
use base 'Exporter';
our @EXPORT = qw($db);

our ($db, $dbargs);

$dbargs = {
  AutoCommit => 1,
  RaiseError => 1 
};
                  
$db = DBI->connect("dbi:SQLite:dbname=zero.db","","",$dbargs);

1;
