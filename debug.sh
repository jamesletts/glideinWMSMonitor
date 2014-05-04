#!/bin/bash

FILE=$1
export TZ=UTC0

echo
echo "====================================== BEGIN DEBUG ======================================="
echo
echo HISTORY FILE: $FILE
echo
printf "%-35s %8s %-35s\n" "schedd Name" "#Jobs" "Earliest Entry Time"
SCHEDDS=`condor_status -schedd -format '%s\n' Name`
for SCHEDD in $SCHEDDS ; do
  n=`       cat $FILE | grep $SCHEDD\# | wc -l`
  earliest=`cat $FILE | grep $SCHEDD\# | grep -o 'EnteredCurrentStatus=[0-9]*' \
    | sort -n -r | tail -1 | awk -F\= '{print strftime("%a %b %d %H:%M:%S %Z %Y",$2)}'`
  printf "%-35s %8i %-35s\n" $SCHEDD $n "$earliest"
done
echo
echo "======================================= END DEBUG ========================================"
echo

exit
