#!/usr/bin/python26
import sys
import datetime
import json
from pprint import pprint


print " Pool Name,       Date,     Time,",
firstline=0

import glob
FILES=glob.glob("/crabprod/CSstoragePath/Monitor-json/monitor-multicore-*.json")
for FILE in FILES :

  with open(FILE) as json_data:
    d = json.load(json_data)
    json_data.close()
    #pprint(d)

  TABLES=d['Multi-core pilot monitoring']
  if firstline==0 :
    firstline=1
    for TABLE in sorted(TABLES) :
      if 'Cpus' in TABLE :
        print TABLE+" Total,"+TABLE+" Wasted,",
    print

  POOL=FILE.split('-')
  print (POOL[3]+",").ljust(11),
  
  now=int(d['Multi-core pilot monitoring']['Time'])
  readable_date=datetime.datetime.utcfromtimestamp(now).strftime('%Y-%m-%d, %H:%M:%S,')

  print readable_date,

  for TABLE in sorted(TABLES) :
    if 'Cpus' in TABLE :
      busy=0
      total=0
      for data in d['Multi-core pilot monitoring'][TABLE]['data']:
        if data[1]=="Busy" : busy+=data[2]
        total+=data[2]
      wasted=total-busy
      print str(total).rjust(6)+", "+str(wasted).rjust(6)+",",
  print
