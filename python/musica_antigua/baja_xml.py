#!/bin/python
import feedparser
d = feedparser.parse("http://www.rtve.es/podcast/radio-clasica/musica-antigua/SMUANTI.xml")
print d.channel.title 
for e in d.entries:
	print e.link

