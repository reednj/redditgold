#!/bin/sh

BASE=~/gold.popacular.com

# copy the required files to the website
rm -rf $BASE/*
cp -R ~/code/redditgold.git/* $BASE/*
rm -rf $BASE/sh
cp ~/code/config_backup/redditgold/esql.dbpass.php $BASE/config/

# now to the script folder

