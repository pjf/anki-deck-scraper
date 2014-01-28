#!/usr/bin/perl -w
use 5.010;
use strict;
use warnings;
use autodie;
use JSON::Any;
use Data::Dumper;
use utf8::all;

# Indexes from web data structure
use constant ID     => 0;
use constant TITLE  => 1;
use constant RATING => 2;
use constant VOTES  => 3;
use constant CARDS  => 4;
use constant AUDIO  => 5;
use constant IMAGES => 6;

my $URL_BASE = 'https://ankiweb.net/shared/info';

my $j = JSON::Any->new;

my @files = @ARGV;
my %decks;

# Read in the HTML and extract the JSON.
# Loading all decks into a hash de-dupes them. :)

foreach my $file (@files) {
    my $content;

    {
        open(my $fh, '<', $file);
        local $/;
        $content = <$fh>;
    }

    # Extract our JSON chunk 
    my ($json) = ($content =~ /shared.files = (.*)/);

    $json =~ s/;$//;    # Strip trailing semicolon

    my $raw_decks = $j->from_json($json);

    # Index into our hash
    foreach my $deck (@$raw_decks) {
        $decks{$deck->[0]} = $deck;
    }
}

# Now print them out, sorted by rating.

say "---\nlayout: default\ntitle: List of anki decks by score\n---";
say "Deck | Score | Votes";
say "-----|-------|------";

foreach my $deck (sort by_rating values %decks) {
    my $title = $deck->[TITLE];

    # Strip markdown-ish things form title
    # Yes, this is a hack.

    $title =~ s/[*[\]]+//g;

    say "[$title]($URL_BASE/$deck->[ID]) | $deck->[RATING] | $deck->[VOTES]";
}

# Sort by rating, then by number of votes

sub by_rating {
    $b->[RATING] <=> $a->[RATING] ||
    $b->[VOTES]  <=> $a->[VOTES];
}
