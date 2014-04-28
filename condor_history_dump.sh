#!/bin/sh
source /home/letts/scripts/condor_functions.sh
POOLNAME="glidein-collector-2.t2.ucsd.edu"

OUTFILE=/crabprod/CSstoragePath/Monitor/monitor-anaops-history-`/bin/date +%F-Z%R -u`.txt
condor_history_dump $POOLNAME > ${OUTFILE}.tmp
mv ${OUTFILE}.tmp $OUTFILE

OUTFILE=/crabprod/CSstoragePath/Monitor/latest-history.txt
/home/letts/scripts/condor_history_analyze.sh $POOLNAME > ${OUTFILE}.tmp
mv ${OUTFILE}.tmp $OUTFILE
exit
