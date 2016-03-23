#!/bin/bash

# ANKI search only retrieves 2000 or so entries, so we refine the search until we are sure we've found all entries.


chr() {
	printf \\$(printf '%03o' $1)
}

ord() {
	printf '%d' "'$1"
}

get_sublists() {
	local word=$1
	local o
	for o in $(seq $(ord a) $(ord z)); do
		local c=$(chr $o)
		wget https://ankiweb.net/shared/decks/$word$c
		if [ $(../build-anki-list.pl $word$c | wc -l) -gt 2000 ]; then
			get_sublists $word$c
		fi
	done
}

cd "$(dirname "$0")"/raw
get_sublists ""

