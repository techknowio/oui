#!/bin/bash
IFS=$'\n'
TABLE=oui
EXECUTE=1 #this will autoload the file into the DB
MYSQLUSERNAME="monitor"
MYSQLPASSWORD="" #Blank will cause it to be asked
MYSQLDB="monitor"

################################Let'er Rip#############################
#download the latest OUI (it's a biggen)
wget http://standards-oui.ieee.org/oui.txt -O oui-new.txt

#create an MD5
md5sum oui-new.txt | cut -d " " -f 1 > oui-new.md5
touch oui.md5
FIRST=`cat oui.md5`
SECOND=`cat oui-new.md5`

if [ "$FIRST" = "$SECOND" ]; then
    echo "OUI is up to date"
    exit
fi

mv oui-new.txt oui.txt

echo "DROP table if exists $TABLE;" > oui.sql
echo "create table oui (base16 varchar(25), name text);">> oui.sql
echo "create index base16_index on oui(base16);">> oui.sql
MAC=(`cat oui.txt | tr -s '[:space:]' |grep "(base 16)" | sed "s/(base\ 16)//" | awk '{print $1}'`)
NAME=(`cat oui.txt | tr -s '[:space:]' |grep "(base 16)" | sed "s/(base\ 16)//" | cut -d ' ' -f 1 --complement | sed -e 's/^[ \t]*//'`)



for ((i=0;i<${#MAC[@]};++i)); do
    NAME=`echo ${NAME[i]} | tr -d "\r"`
    NAME=${NAME/\'/"\'"}

    echo "INSERT into oui (base16,name) values ('${MAC[i]}','$NAME');" >> oui.sql
done

if [ "$EXECUTE" = "1" ]; then
    mysql -u $MYSQLUSERNAME -p$MYSQLPASSWORD $MYSQLDB < oui.sql
fi

mv oui-new.md5 oui.md5
