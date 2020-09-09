#!/bin/bash -l

cp "$REPO_PATH/src/index-template.html" "$REPO_PATH/docs/$1/index.html"

echo "${style}Filling index.html $reset"

BRANCHES=()
HTML=""

for dir in $(echo "$REPO_PATH/docs/$1/*/"); do
    BRANCHES+=($(basename $dir))
done

for branch in $(printf '%s\n' "${BRANCHES[@]}" | sort -V); do
    HTML+="<li><a href=\"${branch}/index.html\">${branch}</a></li>\n"
done

sed -i -e "s#%LINKS%#$HTML#" "$REPO_PATH/docs/$1/index.html"
sed -i -e "s#%LANG%#$(echo $1 | tr '[:lower:]' '[:upper:]')#" "$REPO_PATH/docs/$1/index.html"