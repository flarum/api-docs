echo "${style}Updating redirect $reset"

sed -i "s/^\\/$1.*$/\\/$1\\/latest\t\t\t\\/$1\/$(cd $FLARUM_PATH; git tag | sort -V | tail -1)\\/index.html/" "$REPO_PATH/docs/_redirects"