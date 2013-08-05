#!/bin/sh

WEB=~/gold.popacular.com
SRC=~/code/redditgold.git
SCRIPTS=~/scripts/redditgold
CONFIG=~/code/config_backup/redditgold

# copy the required files to the website
rm -rf $WEB/*
cp -R $SRC/* $WEB
rm -rf $WEB/sh
cp $CONFIG/db.rb $WEB/config/

mkdir $WEB/tmp
touch $WEB/tmp/restart.txt

echo "Website deployed"

# now to the script folder
rm -rf $SCRIPTS/*
mkdir $SCRIPTS/sh
cp -R $SRC/sh/* $SCRIPTS/sh
cp $CONFIG/esql.dbpass.php $SCRIPTS/sh/lib

echo "Script deployed"