#!/bin/bash -l

echo -e "${style}Updating redirect $reset"

tag=$(cd docs/$1; ls -d */ | cut -f1 -d'/' | sort -V | tail -1)

sed -i "s/^\\/$1\/latest.*$/\\/$1\\/latest\t\t\t\\/$1\/$tag\\/index.html/" "$REPO_PATH/docs/_redirects"
