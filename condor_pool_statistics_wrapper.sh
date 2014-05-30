#!/bin/sh
source /home/letts/Monitor/glideinWMSMonitor/bashrc
OUTFILE=$glideinWMSMonitor_OUTPUT_DIR/monitor-glideinWMS-`/bin/date +%F-Z%R -u`.json
alarm() { perl -e 'alarm shift; exec @ARGV' "$@"; }
alarm 600 $glideinWMSMonitor_RELEASE_DIR/condor_pool_statistics.sh > $OUTFILE
exit
