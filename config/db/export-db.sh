#!/bin/sh

DB="gold"


cd ./config/db

# dump the db schema, without the data, and then remove any autoincrement stuff, so the diffs
# look nice
mysqldump --host 127.0.0.1 -u linkuser --no-data --skip-comments $DB | sed 's/ AUTO_INCREMENT=[0-9]* / /' > ../$DB.sql

# to restore locally
# cat redditstream.sql | /c/xampp/mysql/bin/mysql -u linkuser redditstream
