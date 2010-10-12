ZeroBot
===

*	ZeroBot is a Perl IRC Bot that was created by Sparky as a way to learn Perl.
	Coding for the project is assisted by Cooper and miniCruzer on ZeroNET.

*	ZeroNET IRC Network Information:
 	- Host: irc.zeronet.us
 	- Port: 6667
 	- SSL:  6697

*	As of this release, there is a new table in database. You should add it before being able
	to use the *QUOTE system. You can add it using the following command exactly:
	- $ sqlite3 zero.db "CREATE TABLE QUOTES (quoteskey INTEGER PRIMARY KEY, quote TEXT, creator TEXT);"

	Optionally, you may rm zero.db, and run ./mydbgen.sh again.

*	Before you can start the bot, you need to generate a database with SQLite3. SQLite
	is available in most repositories. ZeroBot also requires the DBI module to communicate
	with the SQLite Database. You can install that with:
	- $ sudo cpan -i DBD::SQLite
	
*	After installing SQLite, use the following command to generate a database:
	- $ ./mydbgen

*	Once installed use this to start the bot:
	- $ ./core.pl &
