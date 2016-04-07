#!/usr/bin/python2
# vim: set fileencoding=UTF-8 :
import sqlite3
import subprocess
import urllib2
import sys
import time
import atexit

class Unbuffered(object):
   def __init__(self, stream):
       self.stream = stream
   def write(self, data):
       self.stream.write(data)
       self.stream.flush()
   def __getattr__(self, attr):
       return getattr(self.stream, attr)
sys.stdout = Unbuffered(sys.stdout)

if len(sys.argv) != 3 or sys.argv[2] not in ['restart','resume']:
	print "Usage: get_info_for_all.py <filename.md> <restart|resume>"
	exit()
inputfile = sys.argv[1]
mode = sys.argv[2]

db = sqlite3.connect('infos.db')
db.text_factory = lambda x: unicode(x, 'utf-8', 'ignore')
cur = db.cursor()
if mode == 'restart':
	cur.execute('DROP TABLE IF EXISTS infos')
cur.execute('CREATE TABLE IF NOT EXISTS infos (url VARCHAR UNIQUE, contents TEXT, languages VARCHAR)')

print 'Reading the ',inputfile,' file...'
process = subprocess.Popen(["bash","-c","cat " + inputfile + " | grep '^\[' | sed 's/.*\(https:\/\/anki.*\)).*/\\1/'"], stdout=subprocess.PIPE)
output = process.communicate()[0]

def commit():
	try:
		print 'Commiting into infos.db...'
	finally:
		db.commit()
		db.close()

urls = output.split()
print 'Downloading urls and storing them in the infos.db...'
atexit.register(commit)
i = 0
for url in urls:
	i += 1
	if mode == 'resume' and cur.execute('SELECT 1 FROM infos WHERE url = ?', [url]).fetchone() != None:
		continue
	print i,'/',len(urls)
	contents = urllib2.urlopen(url).read()
	cur.execute('INSERT OR IGNORE INTO infos (url,contents) VALUES (?,?)', [url, contents])
	time.sleep(1) # 1 second to avoid anki panicking about abuse


