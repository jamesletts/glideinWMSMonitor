#!/bin/sh

site_downtimes_from_ssb() {
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
