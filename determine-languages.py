#!/usr/bin/python2
# vim: set fileencoding=UTF-8 :
import sqlite3
import atexit
import sys
import re
import operator

class Unbuffered(object):
   def __init__(self, stream):
       self.stream = stream
   def write(self, data):
       self.stream.write(data)
       self.stream.flush()
   def __getattr__(self, attr):
       return getattr(self.stream, attr)
sys.stdout = Unbuffered(sys.stdout)

print 'Determening languages for each entry in infos.db...'
db = sqlite3.connect('infos.db')
db.text_factory = lambda x: unicode(x, 'utf-8', 'ignore')
cur = db.cursor()

def commit():
	try:
		print 'Commiting into infos.db...'
	finally:
		db.commit()
		db.close()
atexit.register(commit)

def remove_tags(s):
	return re.sub(r'<[^>]+>', '', s)


# This language detector is crap but I can't find free alternatives. It would probably help to download full anki decks
# but they have download limits which make this nasty or unusuably slow (100? a day makes 20k a year)
# The guess_language library is easily upgradable from trigrams to quadgrams but I can only find small multilingual
# corpora, not statistically cute.
from guess_language import guess_language
def determine_language(s):
	return guess_language(s)

'''
# Web service language detectors are slow and marginally better.
import urllib
import urllib2
def determine_language(s):
	#print s
	if s == '':
		return 'UNKNOWN'
	
	# xerox service thinks "Yes. I'm really hungry." is German.
	#url = 'http://services.open.xerox.com/bus/op/LanguageIdentifier/GetLanguageForString?document=' + urllib.quote_plus(s.encode('utf8'))
	#return urllib2.urlopen(url).read().strip('"')

	# Translated labs are better, still usually totally off.
	if re.match(r"^[0-9.,_~!@#$%^&*()\[\]{}:';,.<>/?\|=+` A-Z-]*$", s):
		return 'UNKNOWN' # because numbers, hyphenated numbers, etc. are detected as what appears to be random languages
	url = 'http://labs.translated.net/language-identifier/?text=' + urllib.quote_plus(s.encode('utf8'))
	tmp = urllib2.urlopen(url).read()
	start = tmp.find( '(', tmp.find('This text seems to be') ) + 1
	#print tmp
	lang = tmp[ start : tmp.find(' ', start) ].lower()
	return lang
'''

def debug(x):
	#print x
	0

rows = cur.execute('SELECT url, contents FROM infos').fetchall()
#rows = cur.execute('SELECT url, contents FROM infos WHERE url = \'https://ankiweb.net/shared/info/477508551\'').fetchall()
i = 0
for row in rows:
	i += 1
	if i % 1000 == 0:
		print i,'/',len(rows)
	url = row[0]
	contents = row[1]
	texts = []
	# Title
	texts.append( remove_tags(contents[ contents.find('Back')+4 : contents.find('<small', contents.find('Back')) ]).strip() )
	# Description
	texts.append( remove_tags(contents[ contents.find('Description</h2>')+11 : contents.find('<h2>Sample') ]).strip() )
	# Example rows
	for td in re.findall(r'<td .*?</td>', contents):
		texts.append( remove_tags(td).strip() )
	# Find a language for all
	languages = {}
	for text in texts:
		lang = determine_language(text)
		debug(lang + " " + text)
		if lang != 'UNKNOWN':
			languages[lang] = languages.setdefault(lang,0) + 1
	languages = sorted(languages.items(), key=operator.itemgetter(1))[::-1]
	debug(languages)
	#if len(languages) > 0:
	#	debug(languages[-1])
	believable_languages = []
	for item in languages:
		if item[1] >= 2: # Filter off rare false guesses. Note that only 3 example cards are given on the info page :(
			believable_languages.append(item[0])
			if len(believable_languages) >= 2: # Translation decks use 2 languages but noone uses more.
				break
	if len(believable_languages) == 0:
		# Try joining all text together, language guessing not being very smart.
		lang = determine_language(' '.join(texts))
		if lang != 'UNKNOWN':
			believable_languages = [lang]
	believable_languages = sorted(believable_languages)
	debug(believable_languages)
	cur.execute('UPDATE infos SET languages = ? WHERE url = ?', [','.join(believable_languages), url])

