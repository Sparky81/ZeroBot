#!/bin/bash
echo "Creating \"zero.db\" for usage. Make sure the following are installed:"
echo " - sqlite3 (package)"
echo " - DBD::SQLite (Perl Module)"
echo " - DBI (Perl Module)"
if [ -e 'zero.db' ]; then
	echo "zero.db already exists!"
	exit 0

else
	touch zero.db
	chmod a+x zero.db
	sqlite3 zero.db "CREATE TABLE CHANNELS (channel TEXT);"
	sqlite3 zero.db "CREATE TABLE OWNERS (host TEXT);"
	sqlite3 zero.db "CREATE TABLE ADMINS (host TEXT);"
	sqlite3 zero.db "CREATE TABLE ATS (call TEXT, response TEXT);"
	sqlite3 zero.db "CREATE TABLE QUOTES (quoteskey INTEGER PRIMARY KEY, quote TEXT, creator TEXT);"
	sqlite3 zero.db "CREATE TABLE BLACKLIST (host TEXT);"
	sqlite3 zero.db "CREATE TABLE GREETS (nick TEXT, msg TEXT);"
	echo "Creaton completed. If there were errors, check dependencies."
fi
exit 0
