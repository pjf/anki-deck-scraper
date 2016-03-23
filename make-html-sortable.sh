#!/bin/bash
if [ "$1" == "" ]; then
	echo "Usage: $0 <filename.html>"
	echo "Modifies a html to make the table sortable."
	exit 1
fi
file=$1
cd "$(dirname "$file")"
function include_script() {
	mkdir -p inc/
	local script_origin=$1
	local script="inc/$(basename "$script_origin")"
	if [ ! -s "$script" ]; then
		wget -O "$script" "$script_origin"
	fi
	echo '<script src="'"$script"'"></script>' >> "$file"
}
include_script 'https://github.com/tristen/tablesort/raw/gh-pages/tablesort.min.js'
include_script 'https://github.com/tristen/tablesort/raw/gh-pages/src/sorts/tablesort.number.js'
sed -i 's/<table>/<table id="table-id">/' "$file"
echo "<script>
  new Tablesort(document.getElementById('table-id'));
  </script>">> "$file"
