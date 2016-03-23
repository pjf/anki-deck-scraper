#!/bin/bash
if [ "$1" == "" ]; then
	echo "Usage: $0 <filename.md>"
	echo "Uses infos.db to aspiringy rationally split <filename.md> into smaller parts and provides an index.html to navigate them. The links in index.html will point to .html files, so you need to convert all those .md files to .html somehow."
	exit 1
fi
file=$1
cd "$(dirname "$file")"

common_begin=$(cat "$file" | grep ankiweb -m1 -B 99999 | head -n -1)
common_end=$(tac "$file" | grep ankiweb -m1 -B 99999 | head -n -1 | tac)

declare -A target_file_cache
target_file() {
	local languages=$1
	if [ "${target_file_cache[$languages]}" == "" ]; then
		target_file_cache[$languages]="inc/$(echo "$languages" | shasum | cut -d ' ' -f 1).md"
	fi
	echo "${target_file_cache[$languages]}"
}


echo "Spliting the md into smaller files first..."

rm inc/*.md
declare -A all_languages
declare -A file_sizes
declare -A language_sizes
total=$(cat "$file" | grep ankiweb | wc -l)
i=0
while read line; do
	if [ "$((++i % 100))" == 0 ]; then
		echo "$i / $total"
	fi
	url=${line##*](}
	url=${url%%)*}
	row=$(sqlite3 infos.db "select languages,(contents = 'invalid id') from infos where url = '$url'")
	languages=${row%%|*}
	invalid=${row#*|}
	if [ "$invalid" == 1 ]; then
		continue
	fi
	if [ "$languages" == "" ]; then
		languages="unknown"
	fi
	all_languages[$languages]=1
	target_file "$languages" > /dev/null # populate its cache
	file=$(target_file "$languages")
	if [ ! -f "$file" ]; then
		echo "$common_begin" > "$file"
	fi
	echo "$line" >> "$file"
	((file_sizes[$file]++))
	((language_sizes[$languages]++))
done < <(cat "$file" | grep ankiweb)

for file in $all_files; do
	echo "$common_end" >> "$file"
done


echo "Translating the language IANA codes to something sane..."

if [ ! -s language-subtag-registry ]; then
	wget http://www.iana.org/assignments/language-subtag-registry/language-subtag-registry
fi
declare -A iana_to_name
while read line; do
	if [[ $line =~ ^Subtag: ]]; then
		iana=${line#* }
		iana=${iana%% *}
	fi
	if [[ $line =~ ^Description: ]]; then
		name=${line#* }
		name=${name%% *}
		iana_to_name[$iana]=$name
	fi
done < language-subtag-registry

declare -A language_translations
for languages in ${!all_languages[@]}; do
	language_translations[$languages]=$(
		for language in $(echo "$languages" | sed 's/,/ , /g'); do
			if [ "$language" != "," ]; then
				echo "${iana_to_name[$language]:-$language}"
			else
				echo " - "
			fi
		done | tr '\n' ' ' | sed 's/ *$//'
	)
done
language_translations[unknown]="Unrecognized language"


echo "Creating an index.html ..."

echo "<head><meta http-equiv=\"Content-Type\" content=\"text/html; charset=UTF-8\"></head>" > index.html
while read languages; do
	echo "<h2><a href=\"$(target_file "$languages" | sed 's/.md$/.html/')\">${language_translations[$languages]} (${language_sizes[$languages]} decks)</a></h2>" >> index.html
	sed -i "1i<h2>${language_translations[$languages]}</h2>" $(target_file "$languages") # Show the path to the file, for sanity.
done < <(for languages in ${!language_sizes[@]}; do
	echo -e "$languages\t${language_sizes[$languages]}"
done | sort -nr -k2 | cut -f 1) # Largest groups at top

