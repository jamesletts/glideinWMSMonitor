#!/bin/bash

get_federation_pledges() {
  # This function finds the pledges for certain federated Tier-2 sites
  # from information in REBUS. Unfortunately the list of federations
  # and their membership is not get discoverable.

  url="http://wlcg-rebus.cern.ch/apps/pledges/resources/2014/all/csv"
  curl -ks $url | awk -F\, '
  {
    federation=$3
    cpu=$4
    pledge=$8
    if ( federation == "INFN T2 Federation" && cpu == "CPU" ) {
      printf("T2_IT_Bari,%i,FEDERATION\n",pledge/10./4.)
      printf("T2_IT_Legnaro,%i,FEDERATION\n",pledge/10./4.)
      printf("T2_IT_Pisa,%i,FEDERATION\n",pledge/10./4.)
      printf("T2_IT_Rome,%i,FEDERATION\n",pledge/10./4.)
    }
    if ( federation == "CMS Federation DESY RWTH Aachen" && cpu == "CPU" ) {
      printf("T2_DE_DESY,%i,FEDERATION\n",pledge/10./2.)
      printf("T2_DE_RWTH,%i,FEDERATION\n",pledge/10./2.)
    }
    if ( federation == "Belgian Tier-2 Federation" && cpu == "CPU" ) {
      printf("T2_BE_IIHE,%i,FEDERATION\n",pledge/10./2.)
      printf("T2_BE_UCL,%i,FEDERATION\n",pledge/10./2.)
    }
    if ( federation == "Russian Data-Intensive GRID" && cpu == "CPU" ) {
      printf("T2_RU_IHEP,%i,FEDERATION\n",pledge/10./7.)
      printf("T2_RU_INR,%i,FEDERATION\n",pledge/10./7.)
      printf("T2_RU_ITEP,%i,FEDERATION\n",pledge/10./7.)
      printf("T2_RU_JINR,%i,FEDERATION\n",pledge/10./7.)
      printf("T2_RU_PNPI,%i,FEDERATION\n",pledge/10./7.)
      printf("T2_RU_RRC_KI,%i,FEDERATION\n",pledge/10./7.)
      printf("T2_RU_SINP,%i,FEDERATION\n",pledge/10./7.)
    }
    if ( federation == "London Tier 2" && cpu == "CPU" ) {
      printf("T2_UK_London_IC,%i,FEDERATION\n",pledge/10./2.)
      printf("T2_UK_London_Brunel,%i,FEDERATION\n",pledge/10./2.)
    }
    if ( federation == "SouthGrid" && cpu == "CPU" ) {
      printf("T2_UK_SGrid_RALPP,%i,FEDERATION\n",pledge/10.)
    }
  }'
  return 0
}

translate_site_names_from_sidedb_to_cmssite() {

  # output: name of a sed file to translate SiteDB site names to CMSSite names, in csv format

  # error if X509_USER_PROXY is not defined
  if [ -z $X509_USER_PROXY ] ; then 
    echo "ERROR: X509_USER_PROXY not defined!"
    return 1
  fi

  # this url will provide a mapping between sitesb site names like "ASGC" and 
  # CMSSite names like "T1_TW_ASCG"

  SEDFILE=`mktemp -t SITELIST.sed.XXXXXXXXXX`
  url="https://cmsweb.cern.ch/sitedb/data/prod/site-names"
  curl -ks --cert $X509_USER_PROXY --key $X509_USER_PROXY $url \
    | grep \"cms\" | awk -F\" '{print "s/^" $4 ",/" $6 ",/"}' | sed 's/ //g' > $SEDFILE

  echo "$SEDFILE"
  return 0
}

get_pledges_from_sitedb() {
  # output: comma separated list of CMSSite and latest CPU pledges
  # in kHS06 divided by 10 to normalize roughly to cores.
  # Federated pledges come at the end, so you need to take the 
  # last entry per site. Earlier (zero) entries may be from SitDB.

  # error if X509_USER_PROXY is not defined

  if [ -z $X509_USER_PROXY ] ; then 
    echo "ERROR: X509_USER_PROXY not defined!"
    return 1
  fi

  # this url gives pledges by sitedb name like "ASGC"

  url="https://cmsweb.cern.ch/sitedb/data/prod/resource-pledges"
  thisyear=`/bin/date +%Y`
  TMPFILE=`mktemp -t TMPPLEDGES.txt.XXXXXXXXXX` || return 1

  # get pledges from sitedb only for this year and translate 
  # to CMSSite name not the generic site name

  SEDFILE=`translate_site_names_from_sidedb_to_cmssite`
  curl -ks --cert $X509_USER_PROXY --key $X509_USER_PROXY  $url \
    | awk -F\, -v ty=$thisyear '($4==ty){print $2 "," $3 "," $5}' \
    | tr \[ \  | tr \" \  | sed 's/ //g' | sort | sed -f $SEDFILE | sort > $TMPFILE

  # Remove multiple pledges for the same site ($1) for this year 
  # by taking the most recently entered ($2). Approximate kHS06 
  # to physical cpu by dividing by 10.

  PLEDGES=`mktemp -t PLEDGES.txt.XXXXXXXXXX` || return 2
  sites=`cat $TMPFILE | awk -F\, '{print $1}' | sort | uniq | grep ^T`
  for site in $sites ; do
    grep ^$site\, $TMPFILE | tail -1 | awk -F\, '{print $1 "," int($3*1000./10.) "," strftime("%F",$2)}' >> $PLEDGES
  done

  # corrections for federation pledges. Always take the last one
  get_federation_pledges >> $PLEDGES

  rm $TMPFILE $SEDFILE
  echo "$PLEDGES"
  return 0
}

translate_se_names_in_sitedb_to_cmssite() {
  # output: name of sed file to translate SE names to CMSSite name

  SELIST=`mktemp -t SELIST.sed.XXXXXXXXXX` || exit 1
  SEDFILE=`translate_site_names_from_sidedb_to_cmssite`

  # from SiteDB get the list of SE, sitedb site name
  # and translate sitedb site name to CMSSite name with $SEDFILE
  # output as a sed file

  url="https://cmsweb.cern.ch/sitedb/data/prod/site-resources"
  curl -ks --cert $X509_USER_PROXY --key $X509_USER_PROXY $url \
    | grep \"SE\"  | awk -F\" '{print $2 "," $6}' | sed 's/ //g' \
    | sed -f $SEDFILE | sort | awk -F\, '{print "s/" $2 "/" $1 "/"}' > $SELIST

  rm $SEDFILE
  echo "$SELIST"
  return 0
}
