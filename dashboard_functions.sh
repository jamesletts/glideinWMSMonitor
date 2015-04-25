#!/bin/bash

site_downtimes_from_ssb() {
  # this function is broken April 2015

  # get the downtimes from SSB, remove any quotes so the output
  # is just csv list of [site,downtime string]
  #
  # Usage:
  #   site_downtimes_from_ssb
  # Output:
  #   File name of temporary file containing the csv list.
  
  OUTPUTFILE=`mktemp -t DOWNTIMES.csv.XXXXXXXXXX` || return 1
  url="http://dashb-ssb.cern.ch/dashboard/request.py/getallshort?view=maint"
  curl -ks -H 'Accept:text/csv' $url | awk -F\, '{print $1 "," $3}' \
    | tr -d \" | tr -d \' | grep OUTAGE > $OUTPUTFILE || return 1
  echo $OUTPUTFILE
  return 0
}

dashboard_users() {
  date1=$1
  date2=$2
  tier=$3
  url="http://dashb-cms-job.cern.ch/dashboard/request.py/jobsummary-plot-or-table2?user=&site=&submissiontool=&application=&activity=&status=&check=submitted&tier=${tier}&sortby=user&ce=&rb=&grid=&jobtype=&submissionui=&dataset=&submissiontype=&task=&subtoolver=&genactivity=&outputse=&appexitcode=&accesstype=&date1=${date1}&date2=${date2}&prettyprint"
  users=`curl -sk $url | grep \"name\": | grep -v "unknown/cmsdataops" | grep -v "unknown/unknown" | wc -l`
  #curl -sk $url | grep \"name\": | sort
  echo $users
  return 0
}

dashboard_usage_by_site() {
  # function to print out a csv list of sites and avg and
  # max job slots used daily during the past TIMEFRAME of
  # a certain activity, which can be "all", "analysis",
  # "analysistest", "production", etc.
  #
  # Usage:
  #    dashboard_usage_by_site analysis "3 months ago"
  #    dashboard_usage_by_site all "2 weeks ago"
  #
  # Output:
  #    File name of a temporary file containing the csv list.
  #
  # N.B. Data before April 3, 2014 for T2_US_Wisconsin is over-inflated!

  OUTPUTFILE=`mktemp -t USAGE.csv.XXXXXXXXXX` || return 1
  
  # argument is the activity to list e.g. analysis, production, all
  ACTIVITY=$1
  TIMEFRAME=$2

  # look at the last 3 months:
  date1=`date -d "$TIMEFRAME" +%F`
  date2=`date +%F`

  # url for dashboard historical usage by site:
  url="http://dashb-cms-jobsmry.cern.ch/dashboard/request.py/jobnumberscsv?sites=All%20T3210&datatiers=All%20DataTiers&applications=All%20Application%20Versions&submissions=All%20Submission%20Types&accesses=All%20Access%20Types&activities=${ACTIVITY}&sitesSort=7&start=${date1}&end=${date2}&timeRange=daily&granularity=daily&generic=0&sortBy=0&series=All&type=r"
  curl -ks $url | dos2unix | sort -t \, -k 3 | awk -F\, '
  BEGIN{
    lastsite="None"
    totaljobslots=0
    totaldays=0
    maxjobslots=0
  }
  {
    site=$3
    if ( site != lastsite && lastsite != "None" ){
      slotsperday=int(totaljobslots/totaldays)
      printf("%s,%i,%i\n",lastsite,slotsperday,maxjobslots)
      totaljobslots=0
      totaldays=0
      maxjobslots=0
    }
    lastsite=site
    totaljobslots+=$1
    totaldays+=1
    if ( $1 > maxjobslots ) { maxjobslots=$1 }
  }
  END{
    slotsperday=int(totaljobslots/totaldays)
    printf("%s,%i,%i\n",site,slotsperday,maxjobslots)
  }' > $OUTPUTFILE
  echo "$OUTPUTFILE"
  return 0
}

dashboard_exit_status() {
  # print the exit status of jobs from the dashboard by site
  #
  # Usage:
  #   dashboard_exit_status begin_date end_date activity sitefilter="T1|T2|T3"
  #      where dates are in the form YYYY-mm-dd and activity=[analysis|production|all|analysistest]
  #
  # Output:
  #   #csv list by site: app-unknown,app-successful,app-failed,site-failed,cancelled,aborted,completed,site
  #   csv list : nsites,completed,appsuccessful,successrate

  date1=$1
  date2=$2
  activity=$3
  url="http://dashb-cms-jobsmry.cern.ch/dashboard/request.py/jobnumbers_terminatedcsv?sites=All%20T3210&datatiers=All%20DataTiers&applications=All%20Application%20Versions&submissions=All%20Submission%20Types&accesses=All%20Access%20Types&activities=${activity}&sitesSort=7&start=${date1}&end=${date2}&timeRange=daily&granularity=daily&generic=0&sortBy=0&series=All&type=gstb"
  curl -ks $url | dos2unix | awk -v sitefilter=$4 -F\, ' 
  BEGIN{
    completed=0
    appsuccessful=0
    nsites=0
  }
  {
    if ( sitefilter=="T1" ) { if ( $8!~/^T1/ ) { next } }
    if ( sitefilter=="T2" ) { if ( $8!~/^T2/ ) { next } }
    if ( sitefilter=="T3" ) { if ( $8!~/^T3/ ) { next } }
    completed+=$7
    appsuccessful+=$2
    nsites+=1
  }
  END{
    if ( completed > 0 ) { 
      successrate=appsuccessful/completed*100.0
    } else {
      successrate="N/A"
    }
    printf("%i,%i,%i,%s\n",nsites,completed,appsuccessful,successrate)
  }'
  return 0
}

dashboard_job_slots_used() {
  # print the jobs slots used per day from the dashboard by site
  #
  # Usage:
  #   dashboard_job_slots_used begin_date end_date activity
  #      where dates are in the form YYYY-mm-dd and activity=[analysis|production|all|analysistest]
  #
  # Output:
  #   csv list by site: app-unknown,app-successful,app-failed,site-failed,cancelled,aborted,completed,site
  date1=$1
  date2=$2
  activity=$3

  url="http://dashb-cms-jobsmry.cern.ch/dashboard/request.py/jobnumberscsv?sites=All%20T3210&datatiers=All%20DataTiers&applications=All%20Application%20Versions&submissions=All%20Submission%20Types&accesses=All%20Access%20Types&activities=${activity}&sitesSort=7&start=${date1}&end=${date2}&timeRange=daily&granularity=daily&generic=0&sortBy=0&series=All&type=r"

  curl -ks $url | dos2unix | sort -t \, -k 3 | awk -F\, '
  BEGIN{
    lastsite="None"
    totaljobslots=0
    totaldays=0
  }
  {
    site=$3
    if ( site != lastsite && lastsite != "None" ){
      if ( totaldays > 0 ) {
        slotsperday=int(totaljobslots/totaldays)
      } else {
        slotsperday=0
      }
      printf("%s,%i\n",lastsite,slotsperday)
      totaljobslots=0
      totaldays=0
    }
    lastsite=site
    totaljobslots+=$1
    totaldays+=1
  }
  END{
    if ( totaldays > 0 ) {
      slotsperday=int(totaljobslots/totaldays)
    } else {
      slotsperday=0
    }
    printf("%s,%i\n",site,slotsperday)
  }'
  return 0
}

dashboard_user_report() {
  GRANULARITY=$1
  NUMBER_OF_PERIODS=$2
  DATE1=$3
  printf "%10s,%10s,%10s,%10s\n" date1 date2 nusers nuserst2
  if [ -x $DATE1 ]; then
    date1=`date -dlast-monday +%F`
  else
    date1=$DATE1
  fi
  for (( i=1; i<=$NUMBER_OF_PERIODS; i++ )) ; do
    date2=$date1
    date1=`date -d "$date2 -$GRANULARITY days" +%F`
    nusers=`  dashboard_users $date1 $date2     | awk '{print $1}'`
    nuserst2=`dashboard_users $date1 $date2 2.0 | awk '{print $1}'`
    printf "%10s,%10s,%10s,%10s\n" $date1 $date2 $nusers $nuserst2
  done
  return
}

dashboard_job_report() {
#
#
# ARGS: Granularity in days of the time period for the table
# ARGS: Number of time periods to display
GRANULARITY=$1
NUMBER_OF_PERIODS=$2
DATE1=$3
printf "%10s,%10s,%10s,%10s,%10s,%10s,%10s,%10s,%10s,%10s,%10s,%10s,%10s,%10s,%10s,%10s,%10s,%10s,%10s,%10s\n" \
  date1 date2 \
  ncrab2T1 ncrab3T1 nallT1 jscrab2T1 jscrab3T1 jsallT1 \
  ncrab2T2 ncrab3T2 nallT2 jscrab2T2 jscrab3T2 jsallT2 \
  ncrab2T3 ncrab3T3 nallT3 jscrab2T3 jscrab3T3 jsallT3 

  if [ -x $DATE1 ]; then
    date1=`date -dlast-monday +%F`
  else
    date1=$DATE1
  fi

for (( i=1; i<=$NUMBER_OF_PERIODS; i++ )) ; do
  date2=$date1
  date1=`date -d "$date2 -$GRANULARITY days" +%F`

  jscrab2T1=`dashboard_job_slots_used $date1 $date2 analysis     | awk -F, 'BEGIN{x=0}{if($1~/^T1/){x+=$2}}END{print x}'`
  jscrab3T1=`dashboard_job_slots_used $date1 $date2 analysistest | awk -F, 'BEGIN{x=0}{if($1~/^T1/){x+=$2}}END{print x}'`
  jsallT1=`  dashboard_job_slots_used $date1 $date2 all          | awk -F, 'BEGIN{x=0}{if($1~/^T1/){x+=$2}}END{print x}'`

  jscrab2T2=`dashboard_job_slots_used $date1 $date2 analysis     | awk -F, 'BEGIN{x=0}{if($1~/^T2/){x+=$2}}END{print x}'`
  jscrab3T2=`dashboard_job_slots_used $date1 $date2 analysistest | awk -F, 'BEGIN{x=0}{if($1~/^T2/){x+=$2}}END{print x}'`
  jsallT2=`  dashboard_job_slots_used $date1 $date2 all          | awk -F, 'BEGIN{x=0}{if($1~/^T2/){x+=$2}}END{print x}'`

  jscrab2T3=`dashboard_job_slots_used $date1 $date2 analysis     | awk -F, 'BEGIN{x=0}{if($1~/^T3/){x+=$2}}END{print x}'`
  jscrab3T3=`dashboard_job_slots_used $date1 $date2 analysistest | awk -F, 'BEGIN{x=0}{if($1~/^T3/){x+=$2}}END{print x}'`
  jsallT3=`  dashboard_job_slots_used $date1 $date2 all          | awk -F, 'BEGIN{x=0}{if($1~/^T3/){x+=$2}}END{print x}'`

  ncrab2T1=`dashboard_exit_status $date1 $date2 analysis T1     | awk -F, '{print $2}'`
  ncrab3T1=`dashboard_exit_status $date1 $date2 analysistest T1 | awk -F, '{print $2}'`
  nallT1=`  dashboard_exit_status $date1 $date2 all T1          | awk -F, '{print $2}'`

  ncrab2T2=`dashboard_exit_status $date1 $date2 analysis T2     | awk -F, '{print $2}'`
  ncrab3T2=`dashboard_exit_status $date1 $date2 analysistest T2 | awk -F, '{print $2}'`
  nallT2=`  dashboard_exit_status $date1 $date2 all T2          | awk -F, '{print $2}'`

  ncrab2T3=`dashboard_exit_status $date1 $date2 analysis T3     | awk -F, '{print $2}'`
  ncrab3T3=`dashboard_exit_status $date1 $date2 analysistest T3 | awk -F, '{print $2}'`
  nallT3=`  dashboard_exit_status $date1 $date2 all T3          | awk -F, '{print $2}'`

  printf "%10s,%10s,%10s,%10s,%10s,%10s,%10s,%10s,%10s,%10s,%10s,%10s,%10s,%10s,%10s,%10s,%10s,%10s,%10s,%10s\n" \
    $date1 $date2 \
    $ncrab2T1 $ncrab3T1 $nallT1 $jscrab2T1 $jscrab3T1 $jsallT1 \
    $ncrab2T2 $ncrab3T2 $nallT2 $jscrab2T2 $jscrab3T2 $jsallT2 \
    $ncrab2T3 $ncrab3T3 $nallT3 $jscrab2T3 $jscrab3T3 $jsallT3 

done
return
}
