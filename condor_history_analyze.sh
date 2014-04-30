#!/bin/sh
# discover the exit code explantions?
# DAG jobs not included in held table.
# report CRAB3 vs CRAB2 jobs

POOLNAME=$1

if [ -z $glideinWMSMonitor_RELEASE_DIR ] ; then
  echo "ERROR: glideinWMSMonitor source code missing."
  exit 1
fi

# get the latest dumped history file from the web server:
FILE=$glideinWMSMonitor_OUTPUT_DIR/`ls -1rt /crabprod/CSstoragePath/Monitor \
  | grep ^monitor-anaops-history | grep \.txt$ | tail -1`
NOW=`ls -l --time-style=+%s $FILE | awk '{print $6}'`

cat <<EOF
HISTORY FILE: $FILE

SCHEDDS CONSIDERED IN THE HISTORY:

 Queued
   Jobs Schedd Name
EOF
grep '^JobStatus=[125]' $FILE | grep -o GlobalJobId=.* | awk -F\= '{print $2}' | awk -F\# '{print $1}' | sort | uniq -c 
cat <<EOF

   Done
   Jobs Schedd Name
EOF
grep '^JobStatus=[34]' $FILE | grep -o GlobalJobId=.* | awk -F\= '{print $2}' | awk -F\# '{print $1}' | sort | uniq -c 
echo
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
cat $FILE | grep "^JobStatus=4" | grep -o ExitCode=[0-9]* | sort | uniq -c \
  | awk '($1>100){print $0}' | tr \= \  | sort -n -r -k 1 \
  | awk '
{
  id=0
  explanation="not listed yet"
  if ($3==0)   {id=0;     explanation="Success"}
  if ($3==59)  {id=10043; explanation="Unable to bootstrap WMCore libraries (most likely site python is broken)"}
  if ($3==65)  {id=8001;  explanation="Other CMS Exception, or 65: End of job from user application (CMSSW)"}
  if ($3==83)  {id=8019;  explanation="FileInPathError"}
  if ($3==84)  {id=8020;  explanation="FileOpenError (Likely a site error), or 84: Some required file not found"}
  if ($3==85)  {id=8021;  explanation="FileReadError (May be a site error)"}
  if ($3==92)  {id=8028;  explanation="FileOpenError with fallback"}
  if ($3==112) {id=70000; explanation="Output_sandbox too big for WMS, or 50800: Application segfaulted"}
  if ($3==127) {id=127;   explanation="Error while loading shared library"}
  if ($3==142) {id=60302; explanation="Output file(s) not found"}
  if ($3==147) {id=60307; explanation="Failed to copy an output file to the SE"}
  if ($3==148) {id=60308; explanation="An output file was saved to fall back local SE after failing to copy"}
  if ($3==157) {id=60317; explanation="Forced timeout for stuck stage out"}
  if ($3==158) {id=60318; explanation="Internal error in Crab cmscp.py stageout script"}
  if ($3==195) {id=50115; explanation="cmsRun did not produce a valid job report at runtime (often means cmsRun segfaulted)"}
  if ($3==228) {id=50660; explanation="Application terminated by wrapper because using too much RAM (RSS)"}
  if ($3==232) {id=50664; explanation="Application terminated by wrapper because using too much Wall Clock time"}
  if ($3==237) {id=50669; explanation="Application terminated by wrapper for not defined reason"}
  printf("%8i %9i %9i  %-24s\n",$1,$3,id,explanation)
}'
echo
echo "N.B. Exit Code explanations copied from https://twiki.cern.ch/twiki/bin/viewauth/CMS/JobExitCodes"

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

exit

echo
echo
echo USER PRIORITIES:
echo
#condor_userprio -allusers -all -pool $POOLNAME
condor_userprio -all -pool $POOLNAME

exit
