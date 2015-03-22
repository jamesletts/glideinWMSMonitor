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


======================================================= GLOBAL POOL =======================================================

EOF
# run analysis of global pool, with a time limit of 300s.
COLLECTOR1=vocms097.cern.ch
COLLECTOR2=vocms099.cern.ch
alarm 600 $glideinWMSMonitor_RELEASE_DIR/condor_check $COLLECTOR1 $COLLECTOR2 >> $OUTFILE

cat >> $OUTFILE <<EOF


======================================================= GLOBAL POOL ITB ==================================================

EOF
COLLECTOR1=vocms0115.cern.ch
COLLECTOR2=unknown
alarm 600 $glideinWMSMonitor_RELEASE_DIR/condor_check $COLLECTOR1 $COLLECTOR2 >> $OUTFILE
cat >> $OUTFILE <<EOF


======================================================= TIER-0 POOL =======================================================

EOF
COLLECTOR1=vocms007.cern.ch
COLLECTOR2=cmssrv239.fnal.gov
alarm 600 $glideinWMSMonitor_RELEASE_DIR/condor_check $COLLECTOR1 $COLLECTOR2 >> $OUTFILE
cat >> $OUTFILE <<EOF


======================================================= UCSD POOL =======================================================

EOF
COLLECTOR1=glidein-collector.t2.ucsd.edu
COLLECTOR2=glidein-collector-2.t2.ucsd.edu
alarm 600 $glideinWMSMonitor_RELEASE_DIR/condor_check $COLLECTOR1 $COLLECTOR2 >> $OUTFILE




#if [ $rc -eq 0 ] ; then
  LINKNAME=$glideinWMSMonitor_OUTPUT_DIR/latest.txt
  rm $LINKNAME
  ln -s $OUTFILE $LINKNAME
#fi

# be nice and clean up from failed runs

rm /tmp/DESIRED.txt.*
rm /tmp/DOWNTIMES.csv.*
rm /tmp/PILOTS.txt.*
rm /tmp/PLEDGES.txt.*
rm /tmp/SELIST.sed.*
rm /tmp/SITELIST.sed.*
rm /tmp/USAGE.csv.*

# make a nice html page as a test:
#$glideinWMSMonitor_RELEASE_DIR/make_html_page.sh

exit 0
