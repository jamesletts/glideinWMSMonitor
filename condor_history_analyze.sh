#!/bin/bash
# discover the exit code explantions?
# DAG jobs not included in held table.
# report CRAB3 vs CRAB2 jobs

POOLNAME=$1

if [ -z $POOLNAME ] ; then
  echo "ERROR: Please specify a pool name."
  exit 1
fi

if [ -z $glideinWMSMonitor_RELEASE_DIR ] ; then
  echo "ERROR: glideinWMSMonitor source code missing."
  exit 1
else
  source $glideinWMSMonitor_RELEASE_DIR/bashrc
fi

# get the latest dumped history file from the web server:
FILE=$glideinWMSMonitor_OUTPUT_DIR/`ls -1rt /crabprod/CSstoragePath/Monitor \
  | grep ^monitor-anaops-history | grep \.txt$ | tail -1`
NOW=`ls -l --time-style=+%s $FILE | awk '{print $6}'`

echo HISTORY FILE: $FILE
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
  HeldPerJob=SumRemoteWallClockTime/SumHeld*24.
  HeldEff=SumRemoteUserCpu/SumRemoteWallClockTime*100.
  #printf "Held        %10i %10.1f %10.1f %10.1f\n",SumHeld,SumRemoteWallClockTime,HeldPerJob,HeldEff
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
  | awk '($1>100){print $0}' | sed 's/ExitCode=//'  | sort -n -r -k 1 | awk '{printf("%8i:%-8i",$1,$2)}'`
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
echo "N.B. Exit Code explanations taken from https://twiki.cern.ch/twiki/bin/viewauth/CMS/JobExitCodes."
echo "     Only categories with more than 100 jobs are shown."
echo "     Some ambiguity exists in the error codes from HTCondor. Additional possibilities for exit"
echo "        code mappings are listed on the following line in those cases, e.g. HTCondor exit code"
echo "        84 can map to 84 or 8020, since 8020%256=84."

echo
echo HELD JOBS IN THE PAST 24 HOURS:
echo
printf "%-20s %8s %8s %8s %10s\n" "Site" "Held Jobs" "Users" "Pilots" "WC(d)"

grep "^JobStatus=5" $FILE | awk -v now=$NOW ' \
{
  MATCH_GLIDEIN_CMSSite=unknown
  Owner=unknown
  LastRemoteHost=unknown

  HoldReasonCode=0
  HoldReasonSubCode=0
  RemoteWallClockTime=0
  RemoteUserCpu=0

  yesterday=now-86400
  skip=1

  for (i=1; i<=NF; i++) {
    split($i,subfields,"=")
    if (subfields[1]=="EnteredCurrentStatus") {
      EnteredCurrentStatus=subfields[2] 
      if (EnteredCurrentStatus>yesterday) {
        skip=0
      }
    }
    if (subfields[1]=="MATCH_GLIDEIN_CMSSite") { MATCH_GLIDEIN_CMSSite=subfields[2] }
    if (subfields[1]=="Owner")                 { Owner=subfields[2] }
    if (subfields[1]=="LastRemoteHost")        { LastRemoteHost=subfields[2] }
    if (subfields[1]=="HoldReasonCode")        { HoldReasonCode=subfields[2] }
    if (subfields[1]=="HoldReasonSubCode")     { HoldReasonSubCode=subfields[2] }
    if (subfields[1]=="RemoteWallClockTime")   { RemoteWallClockTime=subfields[2] }
    if (subfields[1]=="RemoteUserCpu")         { RemoteUserCpu=subfields[2] }
  }

  if ( skip==0 && MATCH_GLIDEIN_CMSSite~/^T/ ) {
    HeldJobs[MATCH_GLIDEIN_CMSSite]+=1
    HeldOwners[MATCH_GLIDEIN_CMSSite,Owner]+=1
    HeldPilots[MATCH_GLIDEIN_CMSSite,LastRemoteHost]+=1
    HeldWCtime[MATCH_GLIDEIN_CMSSite]+=RemoteWallClockTime
    HeldUserCpu[MATCH_GLIDEIN_CMSSite]+=RemoteUserCpu
  }
}
END {
  SumHeldJobs=0
  SumWallClockTime=0
  for ( site in HeldJobs ) { 

    nOwners=0
    for ( combined in HeldOwners ) {
      split(combined, separate, SUBSEP)
      if ( site == separate[1] ) { nOwners+=1 }
    }

    nPilots=0
    for ( combined in HeldPilots ) {
      split(combined, separate, SUBSEP)
      if ( site == separate[1] ) { nPilots+=1 }
    }

    WCtime=HeldWCtime[site]/86400.

    SumHeldJobs+=HeldJobs[site]
    SumWallClockTime+=WCtime

    printf "%-20s  %8i %8i %8i %10.1f\n",site,HeldJobs[site],nOwners,nPilots,WCtime
  }
  printf "TOTAL %24i %28.1f\n", SumHeldJobs, SumWallClockTime
}
' | grep ^T | sort

echo
echo
echo USER PRIORITIES:
echo
condor_userprio -all -pool $POOLNAME
#condor_userprio -allusers -all -pool $POOLNAME

$glideinWMSMonitor_RELEASE_DIR/debug.sh $FILE

exit
