#!/bin/sh

# get the downtimes from SSB, remove any quotes so the output is just csv list of site,downtime string
site_downtimes_from_ssb() {
  OUTPUTFILE=`mktemp -t DOWNTIMES.csv.XXXXXXXXXX` || return 1
  url="http://dashb-ssb.cern.ch/dashboard/request.py/getallshort?view=maint"
  curl -ks -H 'Accept:text/csv' $url | awk -F\, '{print $1 "," $3}' \
    | tr -d \" | tr -d \' | grep OUTAGE > $OUTPUTFILE || return 1
  echo $OUTPUTFILE
  return 0
}


# function to print out a csv list of sites and avg and max job slots used daily during the past
# 3 months a certain activity, which can be "all", "analysis", "analysistest", "production", etc.

dashboard_usage_by_site() {
  OUTPUTFILE=`mktemp -t USAGE.csv.XXXXXXXXXX` || return 1
  
  # argument is the activity to list e.g. analysis, production, all
  activity=$1

  # look at the last 3 months:
  date1=`date -d "3 month ago" +%F`
  date2=`date +%F`

  # Data before April 3, 2014 for Wisconsin is garbage.

  # url for dashboard historical usage by site:
  url="http://dashb-cms-jobsmry.cern.ch/dashboard/request.py/jobnumberscsv?sites=All%20T3210&datatiers=All%20DataTiers&applications=All%20Application%20Versions&submissions=All%20Submission%20Types&accesses=All%20Access%20Types&activities=${activity}&sitesSort=7&start=${date1}&end=${date2}&timeRange=daily&granularity=daily&generic=0&sortBy=0&series=All&type=r"
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


dashboard_usage_at_wisconsin() {
  OUTPUTFILE=`mktemp -t USAGE.csv.XXXXXXXXXX` || return 1
  
  # argument is the activity to list e.g. analysis, production, all
  activity=$1

  # look at the last 3 months:
  date1=`date -d "2 weeks ago" +%F`
  date2=`date +%F`

  # Data before April 3, 2014 for Wisconsin is garbage.

  # url for dashboard historical usage by site:
  url="http://dashb-cms-jobsmry.cern.ch/dashboard/request.py/jobnumberscsv?sites=All%20T3210&datatiers=All%20DataTiers&applications=All%20Application%20Versions&submissions=All%20Submission%20Types&accesses=All%20Access%20Types&activities=${activity}&sitesSort=7&start=${date1}&end=${date2}&timeRange=daily&granularity=daily&generic=0&sortBy=0&series=All&type=r"
  curl -ks $url | dos2unix | sort -t \, -k 3 | awk -F\, '
  BEGIN{
    lastsite="None"
    totaljobslots=0
    totaldays=0
    maxjobslots=0
  }
  {
    site=$3
    if ( site != lastsite && lastsite == "T2_US_Wisconsin" ){
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
