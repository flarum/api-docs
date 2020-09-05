source `dirname $0`/_vars.sh

# php "$REPO_PATH/doctum.phar" update doctum-config.php -v

branches=()
eval "$(git for-each-ref --shell --format='branches+=(%(refname))' refs/heads/)"

generate () {
    echo "$style - $1$reset"

    ref=$1
    path="$REPO_PATH/docs/js/$ref"

    rm -rf $path
    mkdir $path

    cp "$REPO_PATH/esdoc.json" $path
    cp "$REPO_PATH/src/readme-js.md" "$path/README.md"

    cd $path
    (cd $FLARUM_PATH && git checkout -q $ref)
    npx esdoc -c esdoc.json 2>&1 >/dev/null

    cd $REPO_PATH
}

generate master
generate mithril-2-update

tags=$(cd $FLARUM_PATH && git tag | sort -V)

for tag in $tags; do
    generate $tag
done

bash $SCRIPTS_PATH/set-redirects.sh php