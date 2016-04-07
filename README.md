This is the hackiest set of hacks to get a complete list of anki
decks that has ever been written.

---

How to use the results already included in this project:  
1. git clone this repo  
2a. open decks.html  (Shows a long list of all anki decks.)  
2b. open index.html  (Shows anki decks grouped by languages (but note that language guessing is louzy!))  

How to scrape anew:  
1. Grab all pages from anki web with deck listings:  
`./download-raw-lists.sh`  
2. Create a markup file from them, listing all anki decks:  
`./build-anki-list.pl raw/* > decks.md`  
3a. Create a single long html from that markup file:  
`./md-to-html.sh decks.md > decks.html` (You can also use Jekyll or other means to create an html)  
3b. Create multiple htmls, grouping the results by language (but note that language guessing is louzy!):  
`./get-info-for-all.py decks.md restart`  
`./determine-languages.py`  
`./split-decks-to-groups.sh decks.md`  
`./all-md-to-html.sh`  

Rant:  
The biggest problem in this project is a lack of good language guessing tools, capable to guess from a single word or just a few words. The methods used by python guess_language are great but character trigrams are too short for good matching. 4-grams or 5-grams would be much better. Full word dictionaries better still. But that's dreaming.
