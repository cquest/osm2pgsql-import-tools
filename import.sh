#!/bin/bash

. $(dirname $0)/config.sh

if [ "a$1" == "a" ]; then
echo "usage : ./import.sh <.bz2 or .pbf file to import (can be an http/https/ftp url or local file) >"
echo "ex : ./import.sh /here/is/my/file.pbf"
echo "ex : ./import.sh http://site/file.pbf"
exit
fi

filename=$(basename "$1")
extension="${filename##*.}"

if [ $extension == "pbf" ] ; then
  parsing_mode="pbf"
  #FIXME I can't find a way to pass the | in the variable
  external_bunzip2="cat"
else
  external_bunzip2="bunzip2 -c"
  parsing_mode="libxml2"
fi

if [[ $1 =~ "http://" ]] || [[ $1 =~ "ftp://" ]] || [[ $1 =~ "https://" ]] ; then
  data_pipe="wget -q -O - $1 "
else
  data_pipe="cat $1 "
fi

echo $data_pipe $osm2pgsql $import_osm2pgsql_options -r $parsing_mode /dev/stdin

$data_pipe | $external_bunzip2 | $osm2pgsql $import_osm2pgsql_options -r $parsing_mode /dev/stdin

# Cet reconstruction d'index a pour but de palier un "bug" dans osm2pgsql qui 
# fait que le planificateur de requête de postgresql préfère faire un seq   
# scan ensuite plutôt qu'utiliser l'indexe
cat $(dirname $0)/requetes-sql-indexes-et-autre/index-planet_osm_ways-a-reindexer.sql | psql $base_osm

if [ ! -z $end_of_import_email ] ; then
  echo "End of $1 import with osm2pgsql on `hostname`" | mail -s "This email does'nt tell you that this import went well, it tells you it ended ;-)" $end_of_import_email -- -f $end_of_import_email
fi
