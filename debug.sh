#!/bin/bash

FILE=$1

export TZ=UTC0

count_entries_in_history_file() {
  STATUS=$1
  TITLE=$2
  echo
  echo $TITLE
  printf "%-35s %8s %-35s\n" "schedd Name" "Jobs" "Earliest Entry Time"
  #SCHEDDS=`cat $FILE | awk -F\= '{print $NF}' | awk -F\# '{print $1}' | sort | uniq | sort`
  SCHEDDS=`condor_status -schedd -format '%s\n' Name`
  for SCHEDD in $SCHEDDS ; do
    earliest=`grep ^JobStatus=$STATUS $FILE | grep $SCHEDD\# | grep -o 'EnteredCurrentStatus=[0-9]*' \
      | sort -n -r | tail -1 | awk -F\= '{print strftime("%c",$2)}'`
    n=`grep ^JobStatus=$STATUS $FILE | grep $SCHEDD\# | wc -l`
    printf "%-35s %8i %-35s\n" $SCHEDD $n "$earliest"
  done
}

echo
echo "====================================== BEGIN DEBUG ======================================="
echo
echo $FILE
echo
count_entries_in_history_file 4 "COMPLETED JOBS:"
count_entries_in_history_file 3 "REMOVED JOBS:"
count_entries_in_history_file 5 "HELD JOBS:"
echo "======================================= END DEBUG ========================================"
echo

exit
