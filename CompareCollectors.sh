#!/bin/sh
COLLECTOR1=$1
COLLECTOR2=$2

list_all_glidein_names() {
  condor_status -pool $COLLECTOR1 -format '%s\n' Name 
  condor_status -pool $COLLECTOR2 -format '%s\n' Name 
}


unique=`list_all_glidein_names | sort | uniq | wc -l`
regto2=`list_all_glidein_names | sort | uniq -c | awk '($1==2){print $0}' | wc -l`
pct=$[$[$unique-$regto2]*100/$unique]

echo Unique pilots on either collector:    $unique
echo Pilots registered to both collectors: $regto2
echo  ... troublesome pilots = $pct \%

exit 0
