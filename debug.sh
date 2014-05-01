#!/bin/bash

count_entries_in_history_file() {
  STATUS=$1
  TITLE=$2
  echo
  echo $TITLE
  printf "%-35s   %-35s  %15s\n" "schedd Name" "Earliest Entry" "Number of Jobs"
  #SCHEDDS=`cat $FILE | awk -F\= '{print $NF}' | awk -F\# '{print $1}' | sort | uniq | sort`
  SCHEDDS=`condor_status -schedd -format '%s\n' Name`
  for SCHEDD in $SCHEDDS ; do
    grep ^JobStatus=$STATUS $FILE | grep $SCHEDD | grep -o 'EnteredCurrentStatus=[0-9]*' \
      | awk -F\= -v now=`/bin/date +%s` -v schedd=$SCHEDD \
      'BEGIN{x=now;n=0}{if($2<x){x=$2};n+=1}END{printf("%-35s   %-35s  %15i\n",schedd,strftime("%c",x),n)}' 
  done
}

echo
echo "====================================== BEGIN DEBUG ======================================="
count_entries_in_history_file 4 "COMPLETED JOBS:"
count_entries_in_history_file 3 "REMOVED JOBS:"
count_entries_in_history_file 5 "HELD JOBS:"
echo "======================================= END DEBUG ========================================"
echo

exit
