#!/bin/bash
cd "$(dirname "$0")"
for f in inc/*.md; do ./md-to-html.sh $f > ${f/.md/.html}; done
