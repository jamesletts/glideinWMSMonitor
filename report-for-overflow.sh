#!/bin/sh
cd /home/letts/Monitor/glideinWMSMonitor
#FILES=`ls -1rtc /crabprod/CSstoragePath/Monitor/monitor-anaops-history-2014-09*Z00:*`

FILES='/crabprod/CSstoragePath/Monitor/monitor-anaops-history-2014-09-17-Z00:00.txt'

echo "date,cpu/wc of,cpu/wc us not of,cpu/wc not us,slot of,slot us not of,slot not us"
for FILE in $FILES ; do

  OUTFILE=overflow/overflow-`basename $FILE`
  if [ ! -f $OUTFILE ] ; then
    #./select_overflow_from_history.sh $FILE > $OUTFILE
    continue
  fi
  DATE=`basename $FILE | sed 's/monitor-anaops-history-//' | sed 's/-Z00:00.txt//' `

  goodWCof=` grep "^JobStatus=4" $OUTFILE  | grep    'ExitCode=0\ '  | grep -o  RemoteWallClockTime=[0-9]* \
    | awk -F\= 'BEGIN{x=0}{x+=$2}END{print int(x/86400.)}'`
  goodCPUof=` grep "^JobStatus=4" $OUTFILE  | grep    'ExitCode=0\ ' | grep -o  RemoteUserCpu=[0-9]* \
    | awk -F\= 'BEGIN{x=0}{x+=$2}END{print int(x/86400.)}'`
  allWCof=` grep "^JobStatus=4" $OUTFILE  | grep -o  RemoteWallClockTime=[0-9]* \
    | awk -F\= 'BEGIN{x=0}{x+=$2}END{print int(x/86400.)}'`

  goodWCus=` grep "^JobStatus=4" $FILE  \
    | grep 'MATCH\_GLIDEIN\_CMSSite\=T2\_US' | grep -v 'MATCH\_GLIDEIN\_CMSSite\=T2\_US\_Vanderbilt' \
    | grep    'ExitCode=0\ '  | grep -o  RemoteWallClockTime=[0-9]* \
    | awk -F\= 'BEGIN{x=0}{x+=$2}END{print int(x/86400.)}'`
  goodCPUus=` grep "^JobStatus=4" $FILE \
    | grep 'MATCH\_GLIDEIN\_CMSSite\=T2\_US' | grep -v 'MATCH\_GLIDEIN\_CMSSite\=T2\_US\_Vanderbilt' \
    | grep    'ExitCode=0\ ' | grep -o  RemoteUserCpu=[0-9]* \
    | awk -F\= 'BEGIN{x=0}{x+=$2}END{print int(x/86400.)}'`
  allWCus=` grep "^JobStatus=4" $FILE  \
    | grep 'MATCH\_GLIDEIN\_CMSSite\=T2\_US' | grep -v 'MATCH\_GLIDEIN\_CMSSite\=T2\_US\_Vanderbilt' \
    | grep -o  RemoteWallClockTime=[0-9]* \
    | awk -F\= 'BEGIN{x=0}{x+=$2}END{print int(x/86400.)}'`

  goodWCall=` grep "^JobStatus=4" $FILE  | grep    'ExitCode=0\ '  | grep -o  RemoteWallClockTime=[0-9]* \
    | awk -F\= 'BEGIN{x=0}{x+=$2}END{print int(x/86400.)}'`
  goodCPUall=` grep "^JobStatus=4" $FILE  | grep    'ExitCode=0\ ' | grep -o  RemoteUserCpu=[0-9]* \
    | awk -F\= 'BEGIN{x=0}{x+=$2}END{print int(x/86400.)}'`
  allWCall=` grep "^JobStatus=4" $FILE  | grep -o  RemoteWallClockTime=[0-9]* \
    | awk -F\= 'BEGIN{x=0}{x+=$2}END{print int(x/86400.)}'`

  goodWCnous=$[$goodWCall-$goodWCus]
  goodCPUnous=$[$goodCPUall-$goodCPUus]

  goodWCusnof=$[$goodWCus-$goodWCof]
  goodCPUusnof=$[$goodCPUus-$goodCPUof]

  goodeffof=`   echo $goodCPUof    $goodWCof    | awk '{if($2>0){print $1/$2*100.0}else{print 0}}'`
  goodeffnous=` echo $goodCPUnous  $goodWCnous  | awk '{if($2>0){print $1/$2*100.0}else{print 0}}'`
  goodeffusnof=`echo $goodCPUusnof $goodWCusnof | awk '{if($2>0){print $1/$2*100.0}else{print 0}}'`

  echo $DATE,$goodeffof,$goodeffusnof,$goodeffnous,$allWCof,$[$allWCus-$allWCof],$[$allWCall-$allWCus]

done

exit
