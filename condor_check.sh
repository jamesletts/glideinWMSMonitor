#!/bin/bash

# put a time limit on a command
alarm() { perl -e 'alarm shift; exec @ARGV' "$@"; }

# location of the output file
OUTLOCATION=/crabprod/CSstoragePath/Monitor
OUTFILE=$OUTLOCATION/monitor-anaops-`/bin/date +%F-Z%R -u`.txt


cat >> $OUTFILE <<EOF
======================================================= ANAOPS POOL =======================================================

EOF
# run analysis of analysis ops pool, with a time limit of 300s.
alarm 300 /home/letts/scripts/condor_check glidein-collector-2.t2.ucsd.edu >> $OUTFILE
rc=$?



cat >> $OUTFILE <<EOF


======================================================= GLOBAL POOL =======================================================

EOF
# run analysis of global pool, with a time limit of 300s.
alarm 300 /home/letts/scripts/condor_check vocms097.cern.ch short >> $OUTFILE

cat >> $OUTFILE <<EOF


===================================================== PRODUCTION POOL =====================================================

EOF
alarm 300 /home/letts/scripts/condor_check vocms97.cern.ch short >> $OUTFILE


# if everything ran correctly, then update the latest file:
if [ $rc -eq 0 ] ; then
  LINKNAME=$OUTLOCATION/latest.txt
  rm $LINKNAME
  ln -s $OUTFILE $LINKNAME
fi

exit 0
