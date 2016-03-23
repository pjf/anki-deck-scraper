if [ "$1" == "" ]; then
	echo "Usage: $0 <filename.md>"
	echo "Outputs the html of the given md. Needs python markdown. (pip install markdown)"
	exit 1
fi
echo "<head><meta http-equiv=\"Content-Type\" content=\"text/html; charset=UTF-8\"></head>"
python -m markdown -x markdown.extensions.tables "$1"
