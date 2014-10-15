#!/bin/bash
# To do: Report CRAB3 vs CRAB2 jobs
#        DAG jobs remove from held table

if [ -z $glideinWMSMonitor_RELEASE_DIR ] ; then
  echo "ERROR: glideinWMSMonitor source code missing."
  exit 1
else
  source $glideinWMSMonitor_RELEASE_DIR/bashrc
fi

# get the latest dumped history file from the web server:
ORIGINAL_FILE=$glideinWMSMonitor_OUTPUT_DIR/`ls -1rt $glideinWMSMonitor_OUTPUT_DIR \
  | grep ^monitor-anaops-history | grep \.txt$ | tail -1`
FILE="/crabprod/CSstoragePath/Monitor/monitor-anaops-overflow-history-latest.txt"
$glideinWMSMonitor_RELEASE_DIR/select_overflow_from_history.sh $ORIGINAL_FILE > $FILE

NOW=`ls -l --time-style=+%s $FILE | awk '{print $6}'`

echo OVERFLOW HISTORY FILE: $ORIGINAL_FILE
echo

nabort=`grep "^JobStatus=3" $FILE                           | wc -l`
ngood=` grep "^JobStatus=4" $FILE  | grep    'ExitCode=0\ ' | wc -l`
nbad=`  grep "^JobStatus=4" $FILE  | grep -v 'ExitCode=0\ ' | wc -l` 

abortWC=`grep "^JobStatus=3" $FILE                            | grep -o  RemoteWallClockTime=[0-9]* \
  | awk -F\= 'BEGIN{x=0}{x+=$2}END{print int(x/86400.)}'`
goodWC=` grep "^JobStatus=4" $FILE  | grep    'ExitCode=0\ '  | grep -o  RemoteWallClockTime=[0-9]* \
  | awk -F\= 'BEGIN{x=0}{x+=$2}END{print int(x/86400.)}'`
badWC=`  grep "^JobStatus=4" $FILE  | grep -v 'ExitCode=0\ '  | grep -o  RemoteWallClockTime=[0-9]* \
  | awk -F\= 'BEGIN{x=0}{x+=$2}END{print int(x/86400.)}'`

abortCPU=`grep "^JobStatus=3" $FILE                           | grep -o  RemoteUserCpu=[0-9]* \
  | awk -F\= 'BEGIN{x=0}{x+=$2}END{print int(x/86400.)}'`
goodCPU=` grep "^JobStatus=4" $FILE  | grep    'ExitCode=0\ ' | grep -o  RemoteUserCpu=[0-9]* \
  | awk -F\= 'BEGIN{x=0}{x+=$2}END{print int(x/86400.)}'`
badCPU=`  grep "^JobStatus=4" $FILE  | grep -v 'ExitCode=0\ ' | grep -o  RemoteUserCpu=[0-9]* \
  | awk -F\= 'BEGIN{x=0}{x+=$2}END{print int(x/86400.)}'`

# need to REMOVE DAG JOBS FROM HERE!!
read nheld heldWC heldCPU <<< $(grep "^JobStatus=5" $FILE | awk -v now=$NOW ' \
BEGIN {
  yesterday=now-86400
  SumRemoteWallClockTime=0
  SumRemoteUserCpu=0
  SumHeld=0
}
{
  skip=1
  for (i=1; i<=NF; i++) {
    split($i,subfields,"=")
    if (subfields[1]=="EnteredCurrentStatus") {
      EnteredCurrentStatus=subfields[2] 
      if (EnteredCurrentStatus>yesterday) { skip=0 }
    }
    if (skip==0 && subfields[1]=="RemoteWallClockTime")   { SumRemoteWallClockTime+=subfields[2] }
    if (skip==0 && subfields[1]=="RemoteUserCpu")         { SumRemoteUserCpu+=subfields[2] }
  }
  if ( skip==0 ) { SumHeld+=1 }
}
END{
  SumRemoteWallClockTime/=86400.
  SumRemoteUserCpu/=86400.
  print SumHeld
  print SumRemoteWallClockTime
  print SumRemoteUserCpu
}
')

ntotal=`  echo $nabort  $ngood  $nbad  $nheld  | awk '{print $1+$2+$3+$5}'`
totalWC=` echo $abortWC $goodWC $badWC $heldWC | awk '{print $1+$2+$3+$5}'`
totalCPU=`echo $abortCPU $goodCPU $badCPU $heldCPU | awk '{print $1+$2+$3+$5}'`

abortpct=`echo $abortWC $totalWC | awk '{if($2>0){print $1/$2*100.0}else{print 0}}'`
goodpct=` echo $goodWC  $totalWC | awk '{if($2>0){print $1/$2*100.0}else{print 0}}'`
badpct=`  echo $badWC   $totalWC | awk '{if($2>0){print $1/$2*100.0}else{print 0}}'`
heldpct=` echo $heldWC  $totalWC | awk '{if($2>0){print $1/$2*100.0}else{print 0}}'`

aborteff=` echo $abortCPU $abortWC | awk '{if($2>0){print $1/$2*100.0}else{print 0}}'`
goodeff=`  echo $goodCPU  $goodWC  | awk '{if($2>0){print $1/$2*100.0}else{print 0}}'`
badeff=`   echo $badCPU   $badWC   | awk '{if($2>0){print $1/$2*100.0}else{print 0}}'`
heldeff=`  echo $heldCPU  $heldWC  | awk '{if($2>0){print $1/$2*100.0}else{print 0}}'`
totaleff=` echo $totalCPU $totalWC | awk '{if($2>0){print $1/$2*100.0}else{print 0}}'`

abortperjob=`echo $abortWC $nabort | awk '{if($2>0){print $1/$2*24.}else{print 0}}'`
goodperjob=` echo $goodWC  $ngood  | awk '{if($2>0){print $1/$2*24.}else{print 0}}'`
badperjob=`  echo $badWC   $nbad   | awk '{if($2>0){print $1/$2*24.}else{print 0}}'`
heldperjob=` echo $heldWC  $nheld  | awk '{if($2>0){print $1/$2*24.}else{print 0}}'`
totalperjob=`echo $totalWC $ntotal | awk '{if($2>0){print $1/$2*24.}else{print 0}}'`

echo
echo "SUMMARY TABLE OF JOBS WHICH COMPLETED IN THE PAST 24 HOURS:"
echo
printf "Job Result  %10s %10s %10s %10s %10s\n"          "Number"  "WC(d)"    "WC(%)"     "WC/job(h)"   "CPU/WC(%)"
printf "ExitCode=0  %10.0f %10.0f %10.1f %10.1f %10.1f\n" $ngood    $goodWC    $goodpct    $goodperjob   $goodeff
printf "ExitCode!=0 %10.0f %10.0f %10.1f %10.1f %10.1f\n" $nbad     $badWC     $badpct     $badperjob    $badeff
printf "Removed     %10.0f %10.0f %10.1f %10.1f %10.1f\n" $nabort   $abortWC   $abortpct   $abortperjob  $aborteff
printf "Held        %10.0f %10.0f %10.1f %10.1f %10.1f\n" $nheld    $heldWC    $heldpct    $heldperjob   $heldeff
echo
printf "Sum         %10.0f %10.0f %10.1f %10.1f %10.1f\n" $ntotal   $totalWC   "100"       $totalperjob  $totaleff


echo
echo EXIT CODE BREAKDOWN OF COMPLETED JOBS:
echo
printf "%8s %9s %9s  %-11s\n" "Jobs" "Condor"   "CMSSW"    "Explanation"
printf "%18s %9s\n"                "ExitCode" "ExitCode" 
COUNT_EXIT_CODES=`cat $FILE | grep "^JobStatus=4" | grep -o ExitCode=[0-9]* | sort | uniq -c \
  | awk '($1>0){print $0}' | sed 's/ExitCode=//'  | sort -n -r -k 1 | awk '{printf("%8i:%-8i",$1,$2)}'`
for x in $COUNT_EXIT_CODES ; do
  n=`               echo $x | awk -F\: '{print $1}'` 
  condor_exit_code=`echo $x | awk -F\: '{print $2}'` 
  cmssw_exit_code=`       condor_exit_codes $condor_exit_code | awk -F\- '{print $1}' | tail -1`
  explanation=`           condor_exit_codes $condor_exit_code | awk -F\- '{print $2}' | tail -1`
  second_cmssw_exit_code=`condor_exit_codes $condor_exit_code | awk -F\- '{print $1}' | head -1`
  if [ $condor_exit_code -eq 0 ] ; then 
    cmssw_exit_code=0
    second_cmssw_exit_code=0
    explanation="Success" 
  fi
  printf "%8i  %8i  %8i  " $n $condor_exit_code $cmssw_exit_code
  echo $explanation

  if [ $cmssw_exit_code -ne $second_cmssw_exit_code ] ; then
    second_explanation=`    condor_exit_codes $condor_exit_code | awk -F\- '{print $2}' | head -1`
    printf "%28i  " $second_cmssw_exit_code
    echo $second_explanation
  fi
done


echo
echo
echo "Sites with ExitCode=92 (8028) TO WHICH jobs overflowed:"
echo
grep ExitCode=92 $FILE | grep -o 'GLIDEIN_CMSSite=.*\s' | awk '{print $1}' | sort | uniq -c | sort -n -r 
echo
echo

echo "SEs with ExitCode=92 (8028) FROM WHICH jobs overflowed:"
echo
grep ExitCode=92 $FILE | grep -o 'DESRIED_SEs=.*\s' | awk '{print $1}' | sort | uniq -c | sort -n -r 
echo
echo
