#!/bin/sh
source /home/letts/Monitor/glideinWMSMonitor/bashrc
OUTFILE=$glideinWMSMonitor_OUTPUT_DIR/monitor-glideinWMS-`/bin/date +%F-Z%R -u`.json
TMPFILE=${OUTFILE}.tmp
alarm() { perl -e 'alarm shift; exec @ARGV' "$@"; }
alarm 600 $glideinWMSMonitor_RELEASE_DIR/condor_pool_statistics.sh $TMPFILE
#check for errors?

# copy output to final location and link it to latest.json
mv $TMPFILE $OUTFILE
LINK=$glideinWMSMonitor_OUTPUT_DIR/latest.json
if [ -L $LINK ] ; then 
  rm $LINK
fi
ln -s $OUTFILE $LINK
exit
