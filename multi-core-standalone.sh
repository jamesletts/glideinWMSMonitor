#!/bin/bash

# source HTCondor commands
source /etc/profile.d/condor.sh

# glideinWMS Pool Central Manager:
export glideinWMS_COLLECTOR="vocms097.cern.ch"

# Location of the source code and output files for this monitor
export glideinWMSMonitor_OUTPUT_DIR="/crabprod/CSstoragePath/Monitor/json"
export glideinWMSMonitor_RELEASE_DIR="/home/letts/Monitor/glideinWMSMonitor"

################## MAKE CONFIGURATION CHANGES ABOVE THIS LINE ##################

# Create temporary file to dump HTCondor information
TMPFILE=`mktemp -p $glideinWMSMonitor_OUTPUT_DIR -t HTCMon.tmp.XXXXXXXXXX`

# Function to dump HTCondor information to the temporary file
GetCondorInfo() {
  condor_status -pool $glideinWMS_COLLECTOR \
    -format '%s,'  GLIDEIN_CMSSite     \
    -format '%s,'  SlotType            \
    -format '%s,'  GLIDEIN_ToRetire    \
    -format '%s,'  CPUs                \
    -format '%s,'  State               \
    -format '%s\n' Activity            \
  >$TMPFILE
  /bin/date +%s
}

NOW=`GetCondorInfo`
#ALSONOW=`echo $NOW | awk '{print strftime("%F %R",$1)}'`
#echo $TMPFILE has `cat $TMPFILE | wc -l` lines created at $ALSONOW.

# Function to extract from the temporary condor information file, for a
# particular site and slottype, the number of CPU cores devoted to each
# State and Activity.
ExtractCondorInfo() {
  SITE=$1
  SLOTTYPE=$2
  SEARCHSTRING=`echo $SITE,$SLOTTYPE | sed 's/All//' | sed 's/Total//'`

  # check if retiring, then do the query of the condor information
  RETIRING=$3
  if [ -z $RETIRING ] ; then
    grep $SEARCHSTRING $TMPFILE | awk -F\, '{print $4 " " $5 " " $6}' 
  else
    grep $SEARCHSTRING $TMPFILE | awk -F\, -v NOW=$NOW '($3<NOW){print $4 " " $5 " " $6}' 
  fi | \
    awk ' { for (i=$1; i>0; i--) { print $2 " " $3 } }' | sort | uniq -c | \
    awk '{printf("        [\"%s\",\"%s\",%i],\n",$2,$3,$1)}' | \
    sed -e "\$s/,$//"  | grep .
  RC=$?

  # empty table is bad json
  if [ $RC -ne 0 ] ; then
    echo "        [null,null,0]"
  fi
  return
}


WriteOutTable() {
  SITE=$1
  TITLE=$2
  echo "    \"$TITLE\": {"
  echo "      \"header\": [\"State\",\"Activity\",\"Cpus\"],"
  echo "      \"data\": ["
  ExtractCondorInfo $SITE $TITLE
  echo "      ]"
  echo "    },"
}


# function to write out a json file with the multi-core monitoring information
# one file per site
WriteOutJsonFile() {

  # Outfile json file for this site
  SITE=$1
  JSONFILE=${glideinWMSMonitor_OUTPUT_DIR}/monitor-${SITE}-${NOW}.json

  # Header of the json file
  {
    echo "{"
    echo "  \"Multi-core pilot monitoring\": {"
    echo "    \"Collector\": \"$glideinWMS_COLLECTOR\","
    echo "    \"CMSSite\": \"$SITE\","
    echo "    \"Time\": $NOW,"

    # Write out the individual tables for the different types of glideins
    WriteOutTable $SITE "Partitionable"
    WriteOutTable $SITE "Partitionable Retiring"
    WriteOutTable $SITE "Dynamic"
    WriteOutTable $SITE "Dynamic Retiring"
    WriteOutTable $SITE "Static"
    WriteOutTable $SITE "Static Retiring"
    WriteOutTable $SITE "Total"
    WriteOutTable $SITE "Total Retiring" | sed -e "\$s/,//"

    # close the json file
    echo "  }"
    echo "}"
  } > $JSONFILE
}


WriteOutJsonFile "T1_ES_PIC"
WriteOutJsonFile "T1_US_FNAL"
WriteOutJsonFile "T2_US_Purdue"

# Clean up
rm $TMPFILE

exit
