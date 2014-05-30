#!/bin/bash

if [ -z $glideinWMSMonitor_RELEASE_DIR ] ; then
  echo "ERROR: glideinWMSMonitor source code missing."
  exit 1
else
  source $glideinWMSMonitor_RELEASE_DIR/bashrc
fi

export TMPDIR=$glideinWMSMonitor_OUTPUT_DIR/tmp_$$
mkdir $TMPDIR

echo "{"

pool_table() {
  # Collector1 has the negotiator, Collector2 is the HA backup. 
  COLLECTOR1=$1
  COLLECTOR2=$2
  shift; shift
  NAME=$@
  NOW=`/bin/date -u`
  negotime=`condor_status -pool $COLLECTOR1 -nego -l | grep LastNegotiationCycleDuration0 | awk '{print int($3)}'`
  total1=`condor_status -schedd -total -pool $COLLECTOR1 | tail -1 | awk '{print int($2)}'`
  total2=`condor_status -schedd -total -pool $COLLECTOR2 | tail -1 | awk '{print int($2)}'`
  colldiff=`echo $total1 $total2 | awk '{print int($1-$2)}'`
  cat <<EOF
  "glideinWMS ${NAME} Pool": {
    "Collector1": "${COLLECTOR1}",
    "Collector2": "${COLLECTOR2}",
    "Time": "${NOW}",
    "Negotiation Cycle (s)": ${negotime},
    "Running Jobs Collector1": ${total1},
    "Running Jobs Collector2": ${total2},
    "Running Jobs Difference": ${colldiff},
    "Summary Table": {
      "header": ["Name","Machine","Total Running Jobs","Total Idle Jobs","Total Held Jobs"],
      "data" : [
EOF
  condor_status -schedd -pool ${COLLECTOR1} \
                -format '        ["%s",' Name \
                -format '"%s",' Machine \
                -format '%i,'   TotalRunningJobs \
                -format '%i,'   TotalIdleJobs \
                -format '%i],\n' TotalHeldJobs | sed '$s/,$//'
  echo "    }"
  echo "  },"
  return
}

pool_table glidein-collector.t2.ucsd.edu glidein-collector-2.t2.ucsd.edu "Analysis Operations"
pool_table vocms097.cern.ch vocms099.cern.ch "Global"
pool_table vocms97.cern.ch cmssrv119.fnal.gov "Production"

cat <<EOF
  "Site Table": {
    "header": [
      "Site","Maintenance",
      "Pledge Info","Total Pledge","Pledged Analysis",
      "Average Analysis Usage","Maximum Analysis Usage",
      "Average Analysis Test Usage","Maximum Analysis Test Usage",
      "Average Production Usage","Maximum Production Usage",
      "Average Total Usage","Maximum Total Usage",
      "Claimed Analysis","Unclaimed Analysis","Analysis Pressure","Exclusive Analysis Pressure",
      "Claimed Global","Unclaimed Global","Global Pressure","Exclusive Global Pressure",
      "Claimed Production","Unclaimed Production","Production Pressure","Exclusive Production Pressure",
    ],
    "data": [
EOF

# get information from sitedb about pledges and se names by CMSSite name
DOWNTIME=`site_downtimes_from_ssb`
PLEDGES=`get_pledges_from_sitedb`
SEDFILE=`translate_se_names_in_sitedb_to_cmssite`

# job slot usage from dashboard - $2 is avg and $3 is max job slots used in a day in the time period
USAGEANA=`dashboard_usage_by_site analysis     "1 month ago"`
USAGETST=`dashboard_usage_by_site analysistest "1 month ago"`
USAGEPRO=`dashboard_usage_by_site production   "1 month ago"`
USAGEALL=`dashboard_usage_by_site all          "1 month ago"`

# get claimed and running pilots, DESIRED_Sites for each pool:
CLAIMEDANA=`get_pilots_by_site glidein-collector.t2.ucsd.edu -claimed`
RUNNINGANA=`get_pilots_by_site glidein-collector.t2.ucsd.edu`
DESIREDANA=`get_DESIRED_Sites  glidein-collector.t2.ucsd.edu`

CLAIMEDGLO=`get_pilots_by_site vocms097.cern.ch -claimed`
RUNNINGGLO=`get_pilots_by_site vocms097.cern.ch`
DESIREDGLO=`get_DESIRED_Sites  vocms097.cern.ch`

CLAIMEDPRO=`get_pilots_by_site vocms97.cern.ch -claimed`
RUNNINGPRO=`get_pilots_by_site vocms97.cern.ch`
DESIREDPRO=`get_DESIRED_Sites  vocms97.cern.ch`


# Loop over sites for the table:
sites=`cat $SEDFILE | awk -F\/ '{print $3}' | sort | uniq`
for site in $sites ; do
  downtime=`   grep ^$site\,  $DOWNTIME   | awk -F\, '{print $2}'`

  # pledge is 50% unless site is >=T1, then it is 5% of total pledge
  validityofpledge=`grep ^$site\, $PLEDGES | tail -1 | awk -F\, '{print $3}'`
  totalpledge=`grep ^$site\, $PLEDGES | tail -1 | awk -F\, '{print int($2)}'`
  echo $site | egrep '^T0|^T1' >> /dev/null
  if [ $? -eq 0 ] ; then
    analysispledge=`echo $totalpledge 0 | awk '{print int($1/10.)}'`
  else
    analysispledge=`echo $totalpledge 0 | awk '{print int($1/2.0)}'`
  fi

  avgusageana=`grep ^$site\,  $USAGEANA   | awk -F\, '{print int($2)}'`
  maxusageana=`grep ^$site\,  $USAGEANA   | awk -F\, '{print int($3)}'`

  avgusagetst=`grep ^$site\,  $USAGETST   | awk -F\, '{print int($2)}'`
  maxusagetst=`grep ^$site\,  $USAGETST   | awk -F\, '{print int($3)}'`

  avgusagepro=`grep ^$site\,  $USAGEPRO   | awk -F\, '{print int($2)}'`
  maxusagepro=`grep ^$site\,  $USAGEPRO   | awk -F\, '{print int($3)}'`

  avgusageall=`grep ^$site\,  $USAGEALL   | awk -F\, '{print int($2)}'`
  maxusageall=`grep ^$site\,  $USAGEALL   | awk -F\, '{print int($3)}'`

  claimedana=` grep \{$site\} $CLAIMEDANA | awk '{print int($1)}'`
  runningana=` grep \{$site\} $RUNNINGANA | awk '{print int($1)}'`
  pressureana=`grep   $site   $DESIREDANA | wc -l`
  exclusivepressureana=`grep $site $DESIREDANA | awk -v site=$site '$1==site{print $0}' | wc -l`

  claimedglo=` grep \{$site\} $CLAIMEDGLO | awk '{print int($1)}'`
  runningglo=` grep \{$site\} $RUNNINGGLO | awk '{print int($1)}'`
  pressureglo=`grep   $site   $DESIREDGLO | wc -l`
  exclusivepressureglo=`grep $site $DESIREDGLO | awk -v site=$site '$1==site{print $0}' | wc -l`

  claimedpro=` grep \{$site\} $CLAIMEDPRO | awk '{print int($1)}'`
  runningpro=` grep \{$site\} $RUNNINGPRO | awk '{print int($1)}'`
  pressurepro=`grep   $site   $DESIREDPRO | wc -l`
  exclusivepressurepro=`grep $site $DESIREDPRO | awk -v site=$site '$1==site{print $0}' | wc -l`

  unclaimed=`echo $claimed $running 0 | awk '{print int($2-$1)}'`

  # still need to remove the comma on the last one
  printf '      [ "%s","%s","%s",%i,%i,' $site "$downtime" "$validityofpledge" $totalpledge $analysispledge
  printf '%s,%s,' $avgusageana  $maxusageana
  printf '%s,%s,' $avgusagetst  $maxusagetst
  printf '%s,%s,' $avgusagepro  $maxusagepro
  printf '%s,%s,' $avgusageall  $maxusageall
  printf '%s,%s,%s,%s,'    $claimedana $runningana $pressureana $exclusivepressureana
  printf '%s,%s,%s,%s,'    $claimedglo $runningglo $pressureglo $exclusivepressureglo
  printf '%s,%s,%s,%s],\n' $claimedpro $runningpro $pressurepro $exclusivepressurepro
done

# close the json file
cat <<EOF
    ]
  }
}
EOF

# clean up temp files
rm $DOWNTIME   $PLEDGES    $SEDFILE    $USAGEANA   $USAGETST   $USAGEPRO $USAGEALL \
   $CLAIMEDANA $RUNNINGANA $DESIREDANA $CLAIMEDGLO $RUNNINGGLO $DESIREDGLO \
   $CLAIMEDPRO $RUNNINGPRO $DESIREDPRO
rmdir $TMPDIR

exit 0
