#!/usr/bin/python26
import datetime
import glob
import json
import sys

print "0UNIX time,Date,Time,Pool Name,",

print "All,",
print "Static,",
print "Static Retiring,",
print "Dynamic+Partitionable,",
print "Dynamic+Partitionable Retiring,",

print "All Idle,",
print "Static Idle,",
print "Static Retiring Idle,",
print "Dynamic+Partitionable Idle,",
print "Dynamic+Partitionable Retiring Idle,",

print "All Idle %,",
print "Static Idle %,",
print "Static Retiring Idle %",
print "Dynamic+Partitionable Idle %,",
print "Dynamic+Partitionable Retiring Idle%"

FILES=glob.glob("/crabprod/CSstoragePath/Monitor/json/monitor-T1_ES_PIC-*.json")
for FILE in FILES :

  try :
    with open(FILE) as json_data:
      d = json.load(json_data)
      json_data.close()
  except ValueError :
    continue

  TABLES=d['Multi-core pilot monitoring']

  now=int(d['Multi-core pilot monitoring']['Time'])
  readable_date=datetime.datetime.utcfromtimestamp(now).strftime('%Y-%m-%d, %H:%M:%S,')
  print str(now)+",",readable_date,

  totals={}
  wasted={}
  for TABLE in sorted(TABLES) :
    if 'Cpus' in TABLE :
      busy=0
      total=0
      for data in d['Multi-core pilot monitoring'][TABLE]['data']:
        if data[1]=="Busy" : busy+=data[2]
        total+=data[2]
      totals[TABLE]=float(total)
      wasted[TABLE]=float(total-busy)

  total_totals=float(totals['Total glidein Cpus'])
  static_totals=float(totals['Static multi-core glidein Cpus'])
  static_retiring_totals=float(totals['Static multi-core retiring glidein Cpus'])
  partitionable_totals=float(totals['Dynamic glidein Cpus']+totals['Partitionable glidein Cpus'])
  partitionable_retiring_totals=float(totals['Dynamic retiring glidein Cpus']+totals['Partitionable retiring glidein Cpus'])

  print '{0:6.0f},'.format(total_totals),
  print '{0:6.0f},'.format(static_totals),
  print '{0:6.0f},'.format(static_retiring_totals),
  print '{0:6.0f},'.format(partitionable_totals),
  print '{0:6.0f},'.format(partitionable_retiring_totals),

  total_wasted=float(wasted['Total glidein Cpus'])
  static_wasted=float(wasted['Static multi-core glidein Cpus'])
  static_retiring_wasted=float(wasted['Static multi-core retiring glidein Cpus'])
  partitionable_wasted=float(wasted['Dynamic glidein Cpus']+wasted['Partitionable glidein Cpus'])
  partitionable_retiring_wasted=float(wasted['Dynamic retiring glidein Cpus']+wasted['Partitionable retiring glidein Cpus'])

  print '{0:6.0f},'.format(total_wasted),
  print '{0:6.0f},'.format(static_wasted),
  print '{0:6.0f},'.format(static_retiring_wasted),
  print '{0:6.0f},'.format(partitionable_wasted),
  print '{0:6.0f},'.format(partitionable_retiring_wasted),

  try :
    total_wasted/=totals['Total glidein Cpus']
  except ZeroDivisionError :
    total_wasted=0.

  try :
    static_wasted/=totals['Static multi-core glidein Cpus']
  except ZeroDivisionError :
    static_wasted=0.
  
  try :
    static_retiring_wasted/=totals['Static multi-core glidein Cpus']
  except ZeroDivisionError :
    static_retiring_wasted=0.

  try :
    partitionable_wasted/=(totals['Dynamic glidein Cpus']+totals['Partitionable glidein Cpus'])
  except ZeroDivisionError :
    partitionable_wasted=0.

  try :
    partitionable_retiring_wasted/=(totals['Dynamic glidein Cpus']+totals['Partitionable glidein Cpus'])
  except ZeroDivisionError :
    partitionable_retiring_wasted=0.

  print '{0:5.1f}%,'.format(100.0*total_wasted),
  print '{0:5.1f}%,'.format(100.0*static_wasted),
  print '{0:5.1f}%,'.format(100.0*static_retiring_wasted),
  print '{0:5.1f}%,'.format(100.0*partitionable_wasted),
  print '{0:5.1f}%'.format(100.0*partitionable_retiring_wasted)

sys.exit()
