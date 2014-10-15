#!/bin/sh
#
# Select overflow jobs from a history file based on an element of DESIRED_Sites matching MATCH_GLIDEIN_CMSSite
# or an elemebt of DESIRED_SEs matching an element of MATCH_GLIDEIN_SEs.

INPUTFILE=$1
grep MATCH_GLIDEIN $INPUTFILE | awk ' \
{

  # get the relevant classads from a history file
  for (i=1; i<=NF; i++) {
    split($i,subfields,"=")
    if (subfields[1]=="MATCH_GLIDEIN_CMSSite") { split(subfields[2],MATCH_GLIDEIN_CMSSite,",") }
    if (subfields[1]=="MATCH_GLIDEIN_SEs")     { split(subfields[2],MATCH_GLIDEIN_SEs,",") }
    if (subfields[1]=="DESIRED_Sites")         { split(subfields[2],DESIRED_Sites,",") }
    if (subfields[1]=="DESRIED_SEs")           { split(subfields[2],DESIRED_SEs,",") }
  } 

  overflow="unknown"
  if ( 1 in MATCH_GLIDEIN_SEs && 1 in DESIRED_SEs ) {
    overflow="yes"
    for ( i in MATCH_GLIDEIN_SEs ) {
      for ( j in DESIRED_SEs ) { 
        if ( MATCH_GLIDEIN_SEs[i]==DESIRED_SEs[j] ) {
          overflow="no"
          break
        }
      }
    }     
  }
  if ( 1 in MATCH_GLIDEIN_CMSSite && 1 in DESIRED_Sites && overflow!="yes") {
    overflow="yes"
    for ( i in MATCH_GLIDEIN_CMSSite ) {
      for ( j in DESIRED_Sites ) { 
        if ( MATCH_GLIDEIN_CMSSite[i]==DESIRED_Sites[j] ) {
          overflow="no"
          break
        }
      }
    }
  }

  # print out a new history file with only overflow jobs
  if ( overflow=="yes" ) { print $0 }
}'

exit
