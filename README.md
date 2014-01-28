This is the hackiest set of hacks to get a complete list of anki
decks that has ever been written.

---

Usage: Grab some pages from anki web with deck listings. I do this:

    $ wget https://ankiweb.net/shared/decks/a
    $ wget https://ankiweb.net/shared/decks/e
    $ wget https://ankiweb.net/shared/decks/i
    $ wget https://ankiweb.net/shared/decks/o
    $ wget https://ankiweb.net/shared/decks/u

(You can already find these in the `raw/` directory.)

Then run `build-anki-list.pl` over them:

    $ ./build-anki-list-list.pl raw/* > decks.md

It produces markdown as output, with YAML top-matter suitable for Jekyll.

You can see the output at http://pjf.id.au/anki/decks.html
