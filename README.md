glideinWMSMonitor
=================

JAMES LETTS, April 27, 2014.

Monitoring scripts for glideinWMS pools in CMS.

Setup file:

   * bashrc                      Customise the location of the condor source file and grid proxy.

Include files are:

   * condor_functions.sh:        General queries for schedds and the collector.
   * dashboard_functions.sh:     Queries the Dashboard for site usage and the SSB for site downtimes.
   * sitedb_functions.sh         Queries the CMS site database for CPU pledges.

Scripts:

   * condor_check:               Assembles a page of interesting data about glideinWMS pool jobs.
   * condor_check.sh:            Driver for condor_check.
   * condor_history_dump.sh:     Dumps schedd ClassAds for recently run jobs and the current queue.
   * condor_history_analyze.sh:  Analyzes the dump of the schedd ClassAds.
