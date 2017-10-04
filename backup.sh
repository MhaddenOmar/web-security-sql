#!/bin/bash
# This script will backup the postgresql database
# and store it in a specified directory

# PARAMETERS
# $1 database name (if none specified run pg_dumpall)

# CONSTANTS
# postgres home folder backups directory
# !! DO NOT specify trailing '/' as it is included below for readability !!
BACKUP_DIRECTORY="/home/omarmhadden/Desktop/backups"

# Date stamp (formated YYYYMMDD)
# just used in file name
CURRENT_DATE=$(date "+%Y%m%d")

# !!! Important pg_dump command does not export users/groups tables
# still need to maintain a pg_dumpall for full disaster recovery !!!

# this checks to see if the first command line argument is null
if [ -z "$1" ]
then
# No database specified, do a full backup using pg_dumpall
pg_dumpall | gzip - > $BACKUP_DIRECTORY/pg_dumpall_$CURRENT_DATE.sql.gz

else
# Database named (command line argument) use pg_dump for targed backup
pg_dump $1 | gzip - > $BACKUP_DIRECTORY/$1_$CURRENT_DATE.sql.gz

fi