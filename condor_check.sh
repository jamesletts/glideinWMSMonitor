#!/bin/bash

if [ -z $glideinWMSMonitor_RELEASE_DIR ] ; then
  echo "ERROR: glideinWMSMonitor source code missing."
  exit 1
else
  source $glideinWMSMonitor_RELEASE_DIR/bashrc
fi


# put a time limit on a command
alarm() { perl -e 'alarm shift; exec @ARGV' "$@"; }

# location of the output file
OUTFILE=$glideinWMSMonitor_OUTPUT_DIR/monitor-anaops-`/bin/date +%F-Z%R -u`.txt

cat >> $OUTFILE <<EOF

======================================================= ANAOPS POOL =======================================================

EOF
# run analysis of analysis ops pool, with a time limit of 300s.
alarm 300 $glideinWMSMonitor_RELEASE_DIR/condor_check glidein-collector-2.t2.ucsd.edu >> $OUTFILE
rc=$?

cat >> $OUTFILE <<EOF


======================================================= GLOBAL POOL =======================================================

EOF
# run analysis of global pool, with a time limit of 300s.
alarm 300 $glideinWMSMonitor_RELEASE_DIR/condor_check vocms097.cern.ch short >> $OUTFILE

cat >> $OUTFILE <<EOF


===================================================== PRODUCTION POOL =====================================================

EOF
alarm 300 $glideinWMSMonitor_RELEASE_DIR/condor_check vocms97.cern.ch short >> $OUTFILE

# if everything ran correctly, then update the latest file:
if [ $rc -eq 0 ] ; then
  LINKNAME=$glideinWMSMonitor_OUTPUT_DIR/latest.txt
  rm $LINKNAME
  ln -s $OUTFILE $LINKNAME
fi

exit 0
