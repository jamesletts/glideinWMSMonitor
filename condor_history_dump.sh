#!/bin/bash

if [ -z $glideinWMSMonitor_RELEASE_DIR ] ; then
  echo "ERROR: glideinWMSMonitor source code missing."
  exit 1
else
  source $glideinWMSMonitor_RELEASE_DIR/bashrc
fi

DATE=`/bin/date +%F-Z%R -u`

POOLNAME="glidein-collector-2.t2.ucsd.edu"
OUTFILE=$glideinWMSMonitor_OUTPUT_DIR/monitor-anaops-history-${DATE}.txt
condor_history_dump $POOLNAME > ${OUTFILE}.tmp
mv ${OUTFILE}.tmp $OUTFILE

POOLNAME="vocms097.cern.ch"
OUTFILE=$glideinWMSMonitor_OUTPUT_DIR/monitor-global-history-${DATE}.txt
condor_history_dump $POOLNAME > ${OUTFILE}.tmp
mv ${OUTFILE}.tmp $OUTFILE
GLOBAL_POOL_INFILE=$OUTFILE


POOLNAME="glidein-collector-2.t2.ucsd.edu"
OUTFILE=$glideinWMSMonitor_OUTPUT_DIR/latest-history.txt
$glideinWMSMonitor_RELEASE_DIR/condor_history_analyze.sh $POOLNAME > ${OUTFILE}.tmp
mv ${OUTFILE}.tmp $OUTFILE


#POOLNAME="glidein-collector-2.t2.ucsd.edu"
#OUTFILE=$glideinWMSMonitor_OUTPUT_DIR/latest-overflow.txt
#$glideinWMSMonitor_RELEASE_DIR/condor_history_analyze_overflow.sh $POOLNAME > ${OUTFILE}.tmp
#mv ${OUTFILE}.tmp $OUTFILE

POOLNAME="vocms097.cern.ch"
OUTFILE=$glideinWMSMonitor_OUTPUT_DIR/latest-global-history.txt
$glideinWMSMonitor_RELEASE_DIR/condor_history_analyze.sh $POOLNAME > ${OUTFILE}.tmp
mv ${OUTFILE}.tmp $OUTFILE

# AccountingGroup=production are production jobs
# then GlobalJobId=crab3 are CRAB3 jobs
# rest are CRAB2 

POOLNAME="vocms097.cern.ch"
INFILE=$glideinWMSMonitor_OUTPUT_DIR/monitor-global-crab3-history-${DATE}.txt
grep 'GlobalJobId=crab3' $GLOBAL_POOL_INFILE > $INFILE
OUTFILE=$glideinWMSMonitor_OUTPUT_DIR/latest-global-crab3-history.txt
$glideinWMSMonitor_RELEASE_DIR/condor_history_analyze.sh $POOLNAME $INFILE > ${OUTFILE}.tmp
mv ${OUTFILE}.tmp $OUTFILE

exit
