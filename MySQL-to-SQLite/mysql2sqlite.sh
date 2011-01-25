#!/bin/sh

MYSQL_PATH=/Applications/XAMPP/xamppfiles/bin

if [ "x$1" == "x" ]; then
  echo "Usage: $0 <dbname>"
  exit
fi

if [ -e "$1.db" ]; then
   	echo "$1.db already exists.  I will overwrite it in 15 seconds if you do not press CTRL-C."
  	COUNT=15
  	while [ $COUNT -gt 0 ]; do
        echo "$COUNT"
        sleep 1
    	COUNT=$((COUNT - 1))
  	done
	rm $1.db
fi

$MYSQL_PATH/mysqldump -u root -p --compatible=ansi --skip-opt $1 | 
grep -v ' KEY "' |
grep -v ' UNIQUE KEY "' |
grep -v ' PRIMARY KEY ' |
sed '/^SET/d' |
sed 's/ unsigned / /g' |
sed 's/ auto_increment/ primary key autoincrement/g' |
sed 's/ COLLATE utf8_unicode_ci//g' |
sed 's/ smallint([0-9]*) / integer /g' |
sed 's/ tinyint([0-9]*) / integer /g' |
sed 's/ int([0-9]*) / integer /g' |
sed 's/ character set [^ ]* / /g' |
sed 's/ enum([^)]*) / varchar(255) /g' |
sed 's/ on update [^,]*//g' |
sed 's/\\r\\n/\\n/g' |
sed 's/\\"/"/g' |
perl -e 'local $/;$_=<>;s/,\n\)/\n\)/gs;print "begin;\n";print;print "commit;\n"' |
perl -pe '
if (/^(INSERT.+?)\(/) {
  $a=$1;
  s/\\'\''/'\'\''/g;
  s/\\n/\n/g;
  s/\),\(/\);\n$a\(/g;
}
' > $1.sql
cat $1.sql | sqlite3 $1.db > $1.err
ERRORS=`cat $1.err | wc -l`
if [ $ERRORS == 0 ]; then
  echo "Conversion completed without error. Output file: $1.db"
  rm $1.sql
  rm $1.err
else
  echo "There were errors during conversion.  Please review $1.err and $1.sql for details."
fi
