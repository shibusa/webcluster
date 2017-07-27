#!/usr/bin/env bash
projectname="ghquery"
user="shibusa"
password="password"

sudo su - postgres << NEWSHELL

psql << PSQLSHELL
CREATE DATABASE $projectname;
CREATE USER $user WITH PASSWORD '$password';
ALTER ROLE $user SET client_encoding TO 'utf8';
ALTER ROLE $user SET default_transaction_isolation TO 'read committed';
ALTER ROLE $user SET timezone TO 'UTC';
GRANT ALL PRIVILEGES ON DATABASE ghquery TO $user;
\q
PSQLSHELL
exit
NEWSHELL
