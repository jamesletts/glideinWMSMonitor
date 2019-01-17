#!/bin/bash

# Leap years not handled - 2020 !

YEAR=$1
if [ -x $YEAR ] ; then
 echo "Usage $0 [year]"
 exit 1
fi
NEXT_YEAR=$[$YEAR+1]


dashboard_users() {
  date1=$1
  date2=$2
  tier=$3
  url="http://dashb-cms-job.cern.ch/dashboard/request.py/jobsummary-plot-or-table2?user=&site=&submissiontool=&application=&activity=&status=&check=submitted&tier=${tier}&sortby=user&ce=&rb=&grid=&jobtype=&submissionui=&dataset=&submissiontype=&task=&subtoolver=&genactivity=&outputse=&appexitcode=&accesstype=&date1=${date1}&date2=${date2}&prettyprint"
  users=`curl -sk $url | grep \"name\": | grep -v "unknown/cmsdataops" | grep -v "unknown/unknown" | wc -l`
  echo $users
  return 0
}


dashboard_user_report() {
  GRANULARITY=$1
  NUMBER_OF_PERIODS=$2
  DATE1=$3
  printf "%10s,%10s,%10s,%10s\n" date1 date2 nusers nuserst2
  if [ -x $DATE1 ]; then
    date1=`date -dlast-monday +%F`
  else
    date1=$DATE1
  fi
  for (( i=1; i<=$NUMBER_OF_PERIODS; i++ )) ; do
    date2=$date1
    date1=`date -d "$date2 -$GRANULARITY days" +%F`
    nusers=`  dashboard_users $date1 $date2     | awk '{print $1}'`
    nuserst2=`dashboard_users $date1 $date2 2.0 | awk '{print $1}'`
    printf "%10s,%10s,%10s,%10s\n" $date1 $date2 $nusers $nuserst2
  done
  return
}


OUTFILE=weekly-report-user-${YEAR}.txt
dashboard_user_report 7 56 > $OUTFILE

OUTFILE=$glideinWMSMonitor_OUTPUT_DIR/monthly-report-user-${YEAR}.txt
dashboard_user_report 31 1 ${YEAR}-02-01            > $OUTFILE
dashboard_user_report 28 1 ${YEAR}-03-01 | tail -1 >> $OUTFILE
dashboard_user_report 31 1 ${YEAR}-04-01 | tail -1 >> $OUTFILE
dashboard_user_report 30 1 ${YEAR}-05-01 | tail -1 >> $OUTFILE
dashboard_user_report 31 1 ${YEAR}-06-01 | tail -1 >> $OUTFILE
dashboard_user_report 30 1 ${YEAR}-07-01 | tail -1 >> $OUTFILE
dashboard_user_report 31 1 ${YEAR}-08-01 | tail -1 >> $OUTFILE
dashboard_user_report 31 1 ${YEAR}-09-01 | tail -1 >> $OUTFILE
dashboard_user_report 30 1 ${YEAR}-10-01 | tail -1 >> $OUTFILE
dashboard_user_report 31 1 ${YEAR}-11-01 | tail -1 >> $OUTFILE
dashboard_user_report 30 1 ${YEAR}-12-01 | tail -1 >> $OUTFILE
dashboard_user_report 31 1 ${NEXT_YEAR}-01-01 | tail -1 >> $OUTFILE

exit
