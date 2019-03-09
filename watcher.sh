#!/bin/bash

BASE_DIR="dirname $0"
v_temp_file="/tmp/temp_$$.sql"
v_spool_file="/tmp/spool_$$.log"
v_badsamples=$BASE_DIR/badsamples.dat
v_output_log=$BASE_DIR/watcher.log

V_JIRA_TASK="<jira issue id>"
V_JIRA_SERVER="<some jira server>"
V_JIRA_LOGIN="<some jira-account>"
V_OPR_DBNAME="<some opr database-value>"
V_JIRA_PASSW=`/usr/sbin/opr -r $V_OPR_DBNAME $V_JIRA_LOGIN | tr -d [:cntrl:]`


export PATH=/usr/bin:/bin:/usr/sbin:/sbin:/opt/oracle/goldengate11.2_11:/opt/oracle/product/11.2.0_se/bin:/opt/rias//sbin:/opt/rias//bin:/opt/oracle/goldengate12.2_12:/opt/rias//sbin:/opt/rias//bin:/opt/oracle/goldengate12.2_11:/opt/oracle/product/11.2.0_ee/bin:/opt/rias//sbin:/opt/rias//bin
#---- Sub routines -----
done_program() {
 local exit_code=${1:-"0"}
 [ -f "$v_temp_file" ] && rm -f $v_temp_file
 [ -f "$v_spool_file" ] && rm -f $v_spool_file
 exit $exit_code
}


post_comment2jiratask() {
local v_msg="$1"
echo "{\"body\":\"${v_msg}\"}" > ${v_spool_file}
curl -k -u ${V_JIRA_LOGIN}:${V_JIRA_PASSW} -X POST --data @${v_spool_file} -H "Content-Type: application/json" https://${V_JIRA_SERVER}/rest/api/2/issue/${V_JIRA_TASK}/comment 1>/dev/null 2>/dev/null
}

#---- Main routine -----
[ -f "$v_output_log" ] && cat /dev/null > $v_output_log
$BASE_DIR/get_state_vector.sh
v_response=`/usr/bin/python $BASE_DIR/classifier.py -p "$BASE_DIR/patternset.dat" -c "$BASE_DIR/vector.dat" | tr -d [:cntrl:]`
v_ts=`cat $BASE_DIR/vector.dat | awk -F ";" '{print $1}' | tail -n 1 | awk '{x=strftime("%Y-%m-%d-%H:%M",$1); print x" "$0;}' | tr -d [:cntrl:]`
v_hostname=`hostname -f | tr -d [:cntrl:]`

echo "v_response: $v_response $v_hostname $v_ts" >> $v_output_log

if [ "$v_response" != "OK" ]
then
 cat $BASE_DIR/vector.dat >> $v_badsamples
 post_comment2jiratask "$v_response $v_hostname $v_ts"
#else
# echo "v_response: $v_response $v_hostname $v_ts" >> 
fi

done_program
