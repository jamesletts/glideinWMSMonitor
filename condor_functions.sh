#!/bin/bash

# BUG: -const '(CurrentTime-EnteredCurrentStatus<86400)' is being ignored!
# Worse, its being taken as the opposite ... ????

getClassAds() {
  # Function to dump a set of ClassAds for queued, running and jobs 
  # from the past 24h of condor history. If the command fails remotely,
  # then one can try to gsissh to the node to execute the query.
  #
  # Usage:
  #    getClassAds $POOLNAME $SCHEDDNAME $MACHINENAME "condor_history"
  #    getClassAds $POOLNAME $SCHEDDNAME $MACHINENAME "condor_q"
  # Output:
  #    Space separated list of job ClassAds, one row per job.
  #
  # Called from condor_history_dump

  POOLNAME=$1    ; shift
  SCHEDDNAME=$1  ; shift
  MACHINENAME=$1 ; shift

  NOW=`/bin/date +%s`
  YESTERDAY=$[$NOW-86400]
  command="$@ \
      -const  '(EnteredCurrentStatus>$YESTERDAY)' \
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
  # Function to list the number of pilots running per site.
  #
  # Usage:
  #    get_pilots_by_site POOLNAME [optional args for condor_status]
  # Output:
  #    File name of temporary file containing the numbers of pilots
  #    running at CMSSites, one line per site.

  PILOTS=`mktemp -t PILOTS.txt.XXXXXXX` || return 1
  condor_status -pool $@ -format '{%s}\n' GLIDEIN_CMSSite | sort | uniq -c > $PILOTS || return 2
  echo $PILOTS
  return 0
}

get_DESIRED_Sites() {
  # Get all queued jobs' DESIRED_Sites, translating from DESIRED_SEs
  # if needed (i.e. for CRAB2). If DESIRED_Sites exists, take that. 
  # Otherwise take DESIRED_SEs and translate using SEDFILE from SiteDB.
  # Note that DAG jobs do not have DESIRED_Sites defined since they
  # run on a schedd and are not counted here.
  #
  # Usage:
  #    get_DESIRED_Sites $POOLNAME
  # Output:
  #    File name of temporary file containing the list of DESIRES_Sites,
  #    one line per job.

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
  # Function to dump all ClassAds defined in getClassAds
  # for all queued, running and jobs that completed in the
  # past day in a glideinWMS pool.
  #
  # Usage:
  #    condor_history_dump $POOLNAME
  # Output:
  #    ClassAd values, one line per job.
  #
  POOLNAME=$1
  SCHEDDS=`condor_status -pool $POOLNAME -schedd -format '%s\,' Name -format '%s\n' Machine`
  for SCHEDD in $SCHEDDS ; do
    SCHEDDNAME=` echo $SCHEDD | awk -F\, '{print $1}'`
    MACHINENAME=`echo $SCHEDD | awk -F\, '{print $2}'`
    getClassAds $POOLNAME $SCHEDDNAME $MACHINENAME "condor_history"
    getClassAds $POOLNAME $SCHEDDNAME $MACHINENAME "condor_q"
  done
  return 0
}

condor_exit_codes() {
  # Function to extract the possible matching CMSSW error codes given the %256 
  # ExitCode from HTCondor. The CMSSW exit codes can be found in the $URL but
  # it is not publically visible yet. Later you can download periodically to 
  # the release directory.
  #
  # Usage:
  #   condor_error_codes $CONDOR_EXIT_CODE
  # Output:
  #   CMSSW exit code matches and text explanations.
  #
  CONDOR_EXIT_CODE=$1
  #
  # Exit code explanation file, check its age and download a new one if too old:
  #
  FILE=$glideinWMSMonitor_RELEASE_DIR/JobExitCodes.html
  #NOW=`/bin/date +%s`
  #FILE_created=`date -r $FILE +%s`
  #age_of_FILE=`echo $NOW $FILE_created | awk '{print int(($1-$2)/86400.)}'`
  #if [ $age_of_FILE -gt 30 ] ; then
  #  URL=https://twiki.cern.ch/twiki/bin/viewauth/CMS/JobExitCodes
  #  echo "Please update $FILE from $URL !"
  #  wget -o $FILE $URL
  #fi
  #
  # grep the explanation of a particular code(s).
  #
  grep \- $FILE  | grep -o [0-9]*\ \-\ .*  | sed 's/<.*>//g' \
    | awk -F\- -v code=$CONDOR_EXIT_CODE '(code==$1%256){print $0}' 
  return 0
}

condor_hold_codes() {
  # Ref: http://research.cs.wisc.edu/htcondor/manual/v7.6/10_Appendix_A.html
  if   [ $1 -eq  1 ] ; then echo "The user put the job on hold with condor_hold." ;
  elif [ $1 -eq  2 ] ; then echo "Globus middleware reported an error." ;
  elif [ $1 -eq  3 ] ; then echo "The PERIODIC_HOLD expression evaluated to True." ;
  elif [ $1 -eq  4 ] ; then echo "The credentials for the job are invalid." ;
  elif [ $1 -eq  5 ] ; then echo "A job policy expression evaluated to Undefined." ;
  elif [ $1 -eq  6 ] ; then echo "The condor_starter failed to start the executable." ;
  elif [ $1 -eq  7 ] ; then echo "The standard output file for the job could not be opened." ;
  elif [ $1 -eq  8 ] ; then echo "The standard input file for the job could not be opened." ;
  elif [ $1 -eq  9 ] ; then echo "The standard output stream for the job could not be opened." ;
  elif [ $1 -eq 10 ] ; then echo "The standard input stream for the job could not be opened." ;
  elif [ $1 -eq 11 ] ; then echo "An internal Condor protocol error was encountered when transferring files." ;
  elif [ $1 -eq 12 ] ; then echo "The condor_starter failed to download input files." ;
  elif [ $1 -eq 13 ] ; then echo "The condor_starter failed to upload output files." ;
  elif [ $1 -eq 14 ] ; then echo "The initial working directory of the job cannot be accessed." ;
  elif [ $1 -eq 15 ] ; then echo "The user requested the job be submitted on hold." ;
  elif [ $1 -eq 16 ] ; then echo "Input files are being spooled." ;
  elif [ $1 -eq 17 ] ; then echo "A standard universe job is not compatible with the condor_shadow version available on the submitting machine." ;
  elif [ $1 -eq 18 ] ; then echo "An internal Condor protocol error was encountered when transferring files." ;
  elif [ $1 -eq 19 ] ; then echo "<Keyword>_HOOK_PREPARE_JOB was defined but could not be executed or returned failure." ;
  elif [ $1 -eq 20 ] ; then echo "The job missed its deferred execution time and therefore failed to run." ;
  elif [ $1 -eq 21 ] ; then echo "The job was put on hold because WANT_HOLD in the machine policy was true." ;
  elif [ $1 -eq 22 ] ; then echo "Unable to initialize user log." ;
  # CMS-specific reasons? glexec
  elif [ $1 -eq 28 ] ; then echo "error changing sandbox ownership to the user. (glexec)" ;
  elif [ $1 -eq 30 ] ; then echo "error changing sandbox ownership to condor. (glexec)";
  else echo "UNKNOWN HoldReasonCode $1" ; fi
  return 0
}
