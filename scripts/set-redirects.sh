#!/bin/bash -l

echo -e "${style}Updating redirect $reset"

sed -i "s/^\\/$1.*$/\\/$1\\/latest\t\t\t\\/$1\/$(cd docs/$1; ls -d */ | cut -f1 -d'/' | sort -V | tail -1)\\/index.html/" "$REPO_PATH/docs/_redirects"