#!/bin/sh
# try using this command to deploy the script more easily:
# scp config/pr-deploy.sh reednj@servralert.com:~/code/`basename "$PWD"`.git/.git/hooks/pr-deploy

WEB=~/gold.reddit-stream.com
SRC=~/code/redditgold.git
SCRIPTS=~/scripts/redditgold
CONFIG=~/code/config_backup/redditgold

# copy the required files to the website
rm -rf $WEB/*
cp -R $SRC/* $WEB
rm -rf $WEB/sh

mkdir $WEB/tmp
touch $WEB/tmp/restart.txt

echo "Website deployed"

# now to the script folder
rm -rf $SCRIPTS/*
mkdir $SCRIPTS/sh
cp -R $SRC/sh/* $SCRIPTS/sh
cp $CONFIG/esql.dbpass.php $SCRIPTS/sh/lib

echo "Script deployed"
