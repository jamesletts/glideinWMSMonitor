#!/bin/sh

source /etc/profile.d/condor.sh

getClassAds() {
  POOLNAME=$1 ; shift
  SCHEDDNAME=$1 ; shift
  MACHINENAME=$1 ; shift
  # function to dump a particular set of ClassAds from command such as
  # condor_history or condor_q
  command="$@ \
      -format 'JobStatus=%i\ '              JobStatus \
      -format 'LastJobStatus=%i\ '          LastJobStatus \
      -format 'ExitCode=%i\ '               ExitCode \
      -format 'EnteredCurrentStatus=%i\ '   EnteredCurrentStatus \
      -format 'ImageSize=%i\ '              ImageSize \
      -format 'RemoteWallClockTime=%i\ '    RemoteWallClockTime \
      -format 'RemoteUserCpu=%i\ '          RemoteUserCpu \
      -format 'LastRemoteHost=%s\ '         LastRemoteHost \
      -format 'MATCH_GLIDEIN_CMSSite=%s\ '  MATCH_GLIDEIN_CMSSite \
      -format 'DESRIED_Sites=%s\ '          DESIRED_Sites \
      -format 'DESRIED_SEs=%s\ '            DESIRED_SEs \
      -format 'Owner=%s\ '                  Owner \
      -format 'AccountingGroup=%s\ '        AccountingGroup \
      -format 'Iwd=%s\ '                    Iwd \
      -format 'HoldReasonCode=%i\ '         HoldReasonCode \
      -format 'HoldReasonSubCode=%i\ '      HoldReasonSubCode \
      -format 'HoldReason=%s\ '             HoldReason \
      -format 'GlobalJobId=%s\\n'           GlobalJobId"
  eval $command -pool $POOLNAME -name $SCHEDDNAME || gsissh $MACHINENAME $command
  rc=$?
  return $rc
}


get_pilots_by_site() {
  # Get pilots for each site. Args are poolname and any addition arguments for condor_status like -claimed
  PILOTS=`mktemp -t PILOTS.txt.XXXXXXX` || return 1
  condor_status -pool $@ -format '{%s}\n' GLIDEIN_CMSSite | sort | uniq -c > $PILOTS || return 2
  echo $PILOTS
  return 0
}

get_DESIRED_Sites() {
  # Get all queued jobs DESIRED_Sites, translating from SE if needed.
  # If DESIRED_Sites exists, take that. Otherwise take DESIRED_SEs and translate using SEDFILE from SiteDB.
  # Note that DAG jobs do not have DESIRED_Sites defined and are not counted here.
  POOLNAME=$1

  source /home/letts/scripts/sitedb_functions.sh
  SEDFILE=`translate_se_names_in_sitedb_to_cmssite`

  SCHEDDS=`condor_status -pool $POOLNAME  -const '(TotalIdleJobs>0)' -schedd -format ' -name %s' Name ` || return 1
  DESIRED=`mktemp -t DESIRED.txt.XXXXXXX` || return 2

  # run condor_q if there are queued jobs in the pool only:
  if [ `echo $SCHEDDS | wc -w` -ne 0 ] ; then 
    condor_q $SCHEDDS -pool $POOLNAME -const '(JobStatus=?=1)' \
      -format '%s' DESIRED_Sites -format ' %s' DESIRED_SEs -format ' %s\n' Owner \
      | awk '{print $1}' | sed -f $SEDFILE >> $DESIRED || exit 8
  fi

  echo $DESIRED
  rm $SEDFILE
  return 0
}

condor_history_dump() {
  POOLNAME=$1
  SCHEDDS=`condor_status -pool $POOLNAME -schedd -format '%s\,' Name -format '%s\n' Machine`
  for SCHEDD in $SCHEDDS ; do
    SCHEDDNAME=` echo $SCHEDD | awk -F\, '{print $1}'`
    MACHINENAME=`echo $SCHEDD | awk -F\, '{print $2}'`
    getClassAds $POOLNAME $SCHEDDNAME $MACHINENAME "condor_history -const '(CurrentTime-EnteredCurrentStatus<86400)'"
    getClassAds $POOLNAME $SCHEDDNAME $MACHINENAME "condor_q"
  done
  return 0
}
