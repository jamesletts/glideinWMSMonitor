#!/bin/bash

monitor_pool_json_summary_table() {
  # Usage: monitor_pool_json_summary_table collector1 collector2 title
  # Callout: condor_status

  COLLECTOR1=$1
  COLLECTOR2=$2
  shift; shift
  NAME=$@
  NOW=$[1000*`/bin/date +%s`]

  running1=`condor_status -schedd -total -pool $COLLECTOR1 | tail -1 | awk '{print int($2)}'`
  running2=`condor_status -schedd -total -pool $COLLECTOR2 | tail -1 | awk '{print int($2)}'`
  colldiff=`echo $running1 $running2 | awk '{print int($1-$2)}'`
  queued1=`condor_status -schedd -total -pool $COLLECTOR1 | tail -1 | awk '{print int($3)}'`
  queued2=`condor_status -schedd -total -pool $COLLECTOR2 | tail -1 | awk '{print int($3)}'`
  negotime=`condor_status -pool $COLLECTOR1 -nego -l | grep LastNegotiationCycleDuration0 | awk '{print int($3)}'`
  if [ -z $negotime ] ; then 
    negotime=`condor_status -pool $COLLECTOR2 -nego -l | grep LastNegotiationCycleDuration0 | awk '{print int($3)}'`
  fi

  if [ -z $running1 ] ; then running1=null ; fi
  if [ -z $running2 ] ; then running2=null ; fi
  if [ -z $colldiff ] ; then colldiff=null ; fi
  if [ -z $queued1  ] ; then queued1=null  ; fi
  if [ -z $queued2  ] ; then queued2=null  ; fi
  if [ -z $negotime ] ; then negotime=null ; fi

  cat <<EOF
{
  "glideinWMS Pool Summary": {
    "Pool Name": "${NAME}",
    "Collector1": "${COLLECTOR1}",
    "Collector2": "${COLLECTOR2}",
    "Time": ${NOW},
    "Negotiation Cycle (s)": ${negotime},
    "Running Jobs Collector1": ${running1},
    "Running Jobs Collector2": ${running2},
    "Running Jobs Difference": ${colldiff},
    "Queued Jobs Collector1": ${queued1},
    "Queued Jobs Collector2": ${queued2},
    "Schedd Table": {
      "header": ["Name","Machine","Total Running Jobs","Total Idle Jobs","Total Held Jobs"],
      "data" : [
EOF
  { condor_status -schedd -pool ${COLLECTOR1} \
                  -format '        ["%s",' Name \
                  -format '"%s",'  Machine \
                  -format '%i,'    TotalRunningJobs \
                  -format '%i,'    TotalIdleJobs \
                  -format '%i],\n' TotalHeldJobs 
    if [ $? -ne 0 ] ; then
      echo "        [null,null,null,null,null],"
    fi
  } | grep -v ^$ | sed '$s/,$//'

  cat <<EOF
      ]
    }
  }
}
EOF
  return 0
}


monitor_pool_json_site_table() {
  # Usage: monitor_pool_json_site_table collector1 collector2 title
  # Callout: condor_q and condor_status

  COLLECTOR1=$1
  COLLECTOR2=$2
  shift; shift
  NAME=$@
  NOW=$[1000*`/bin/date +%s`]

  cat <<EOF
{
  "glideinWMS Pool Site": {
    "Pool Name": "${NAME}",
    "Collector1": "${COLLECTOR1}",
    "Collector2": "${COLLECTOR2}",
    "Time": ${NOW},
    "Site Table": {
      "header": ["Site Name","Claimed Pilots","Total Pilots","Pressure","Exclusive Pressure"],
      "data" : [
EOF
  CLAIMED=`get_pilots_by_site $COLLECTOR1 -claimed`
  RUNNING=`get_pilots_by_site $COLLECTOR1`
  DESIRED=`get_DESIRED_Sites  $COLLECTOR1`

  # Loop over sites for the table:
  SEDFILE=`translate_se_names_in_sitedb_to_cmssite`
  sites=`cat $SEDFILE | awk -F\/ '{print $3}' | sort | uniq`
  {
  for site in $sites ; do
    claimed=`grep \{$site\} $CLAIMED | awk '{print int($1)}'`
    running=`grep \{$site\} $RUNNING | awk '{print int($1)}'`
    pressur=`grep   $site   $DESIRED | wc -l`
    exclusi=`grep   $site   $DESIRED | awk -v site=$site '($1==site){print $0}' | wc -l`
    if [ -z $claimed ] ; then claimed=0 ; fi
    if [ -z $running ] ; then running=0 ; fi
    if [ -z $pressur ] ; then pressur=0 ; fi
    if [ -z $exclusi ] ; then exclusi=0 ; fi
    printf '        ["%s",%s,%s,%s,%s],\n' $site $claimed $running $pressur $exclusi
  done
  }   | sed '$s/,$//' | sed 's/\"null\"/null/g'
  cat <<EOF
      ]
    }
  }
}
EOF
  rm $CLAIMED $RUNNING $DESIRED $SEDFILE
  return 0
}
