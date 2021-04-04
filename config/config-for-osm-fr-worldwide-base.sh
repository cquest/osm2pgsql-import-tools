#!/bin/bash
project_dir=$(dirname $0)

#If those are in your path just set :
osm2pgsql=osm2pgsql
osmosis=osmosis
#if you want relative path use $project_dir instead like $project_dir/../path-to-binary or $project_dir/path-to-binary
#$project_dir beeing the directory this config.sh file is

#binary paths
#osm2pgsql=$project_dir/../osm2pgsql/osm2pgsql
#osmosis=$project_dir/../osmosis-0.43.1/bin/osmosis

#database name to choose
base_osm=osm

#directory where temporary diff files will be stored, timeing for import, pid lock files and log files 
#/run/shm/ for a ram disk place is good if you don't care about timeings and logs after reboot
work_dir=/run/shm/osm2pgsql-import

#directory where expire files are stored, to be used when rendering is done on another machine
#if empty, expire files won't be kept
expire_dir=/data/work/osm2pgsql/expire_list/

#0 doesn't print anything out, 1 prints every commands that we run + output of commands
verbosity=0

#record timeings of osm2pgsql, osmosis and tile generation processing
with_timeings=1

#For osm2pgsql options (database name is not hardcoded here because some scripts needs it as a variable, so we just make use of it here)
#--tag-transform-script $project_dir/script.lua (pensez à faire des chemin absolu ou utilisez $project_dir sinon, ça foire quand c'est pas lancé du dossier en cours)
common_osm2pgsql_options=" -k -m -G -s -S $project_dir/osm2pgsql-choosen.style -d $base_osm --keep-coastlines --flat-nodes /rpool/flatnodes"
diff_osm2pgsql_options="--number-processes=4 -a -C 1024 $common_osm2pgsql_options"
import_osm2pgsql_options="--create -C 18000 --number-processes=16 $common_osm2pgsql_options "

#post import sql scripts in requetes-sql-indexes-et-autre to run, separated by spaces
operations_post_import="index-planet_osm_ways-a-reindexer.sql indexes-admin_level.sql indexes-ref.sql index-ref-sandre.sql"

#Rendering related
#osm2pgsql expire list creation options (if empty no expiration list is built)
osm2pgsql_expire_option="-e12-17"

osm2pgsql_expire_tile_list=$work_dir/expire.list

#List of rendering style to run thru the render_expired commands
#Be sure that this script as the filesystem rights to access tiles 
#if empty, no expiration will occure, you'll have to do it with the expiry tile files in an other way
rendering_styles_tiles_to_expire=""
render_expired_options="--min-zoom=12 --touch-from=12 --max-zoom=20"

#You can use this to execute the render_expired with another user like "sudo -u www-data"
render_expired_prefix="sudo -u www-data"

#Email to send end of initial import notice (Leave it empty for not warning of import end)
end_of_import_email=""

#Passed this system load, don't run any update at all, set it to empty to disable
max_load=""
