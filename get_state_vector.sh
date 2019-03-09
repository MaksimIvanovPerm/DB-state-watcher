#!/bin/bash

source /etc/profile.d/ora_env.sh

v_dbid=""
v_char=";"
v_temp_file="/tmp/temp_$$.sql"
v_spool_file="/tmp/spool_$$.log"
v_sleep="20"

BASE_DIR="dirname $0"
v_sample1_file="$BASE_DIR/sample1.dat"; [ -f "$v_sample1_file" ] && cat /dev/null > $v_sample1_file
v_sample2_file="$BASE_DIR/sample2.dat"; [ -f "$v_sample2_file" ] && cat /dev/null > $v_sample2_file
v_output_file="$BASE_DIR/vector.dat"; #[ -f "$v_output_file" ] && rm -f $v_output_file
v_debug="debug.txt"; [ -f "$v_debug" ] && cat /dev/null > $v_debug
v_dodebug="0"

v_db_user="..."
v_db_alias="..."
v_db_pwd=`/usr/sbin/opr -r $v_db_alias $v_db_user | tr -d [:cntrl:]`

#---- Sub. routines ----
done_program() {
 local exit_code=${1:-"0"}
 [ -f "$v_temp_file" ] && rm -f $v_temp_file
 [ -f "$v_spool_file" ] && rm -f $v_spool_file
 exit $exit_code
}

init() {

echo -e "set head off
set pagesize 0
set feedback off
set verify off

select ''||dbid as dbid from sys.v_\$database;

exit" > $v_temp_file

 $ORACLE_HOME/bin/sqlplus -S ${v_db_user}/${v_db_pwd}@${v_db_alias} @$v_temp_file > $v_spool_file
 v_dbid=`cat $v_spool_file | tr -d [:cntrl:]`
 #echo "dbid: ${v_dbid}"

}

get_sample() {
 local v_sample_file=$1

echo -e "set head off
set pagesize 0
set feedback off
set verify off

define v_dbid=$v_dbid

SELECT stat_class||comp_id||' '||stat_value as col
FROM (SELECT 'e' AS stat_class, en.event_id AS comp_id, ''||Nvl(se.TIME_WAITED_MICRO,0) AS stat_value
               from sys.wrh\$_event_name en, sys.V_\$SYSTEM_EVENT se
               WHERE en.dbid=&&v_dbid
               AND se.event_id(+)=en.event_id
               ORDER BY en.event_id)
UNION ALL
SELECT stat_class||comp_id||' '||stat_value as col
FROM (SELECT 's' AS stat_class, sn.stat_id AS comp_id, ''||Nvl(st.Value,0) AS stat_value 
               FROM sys.wrh\$_stat_name sn, sys.v_\$sysstat st 
               WHERE sn.dbid=&&v_dbid  AND st.stat_id(+)=sn.stat_id
                 AND sn.stat_id NOT IN (SELECT DISTINCT tm.stat_id FROM sys.WRH\$_SYS_TIME_MODEL tm WHERE tm.dbid=&&v_dbid)
               ORDER BY sn.stat_id)
UNION all
SELECT stat_class||comp_id||' '||stat_value as col
FROM (SELECT 't' AS stat_class, tm.stat_id AS comp_id, ''||Nvl(tm.Value,0) AS stat_value 
      FROM sys.V_\$SYS_TIME_MODEL tm ORDER BY tm.stat_id)
;

exit" > $v_temp_file

 $ORACLE_HOME/bin/sqlplus -S ${v_db_user}/${v_db_pwd}@${v_db_alias}  @$v_temp_file > $v_sample_file
}

#---- Main routine ----
init

get_sample "$v_sample1_file"
sleep $v_sleep
get_sample "$v_sample2_file"

# order of files in join is important
join -j 1 $v_sample1_file $v_sample2_file | awk -v v_delay="$v_sleep"  'BEGIN{x="";}{x=($3-$2)/v_delay; if ( x < 0 ){x=0;} printf "%s %f\n", $1, x;}' > $v_temp_file

v_timestamp=`date +%s | tr -d [:cntrl:]`
cat $v_temp_file | awk -v v_sep="$v_char" '{if ( NR == 1 ) {printf "ts;%s",$1;} else {printf "%s%s",v_sep,$1}}END{printf "\n";}' > $v_output_file
cat $v_temp_file | awk -v ts="$v_timestamp" -v v_sep="$v_char" 'BEGIN{printf "%s%s",ts,v_sep;}{if ( NR == 1 ) {printf "%s",$2;} else {printf "%s%s",v_sep,$2}}END{printf "\n";}' >> $v_output_file

done_program

