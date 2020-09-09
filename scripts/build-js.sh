source $(dirname $0)/_vars.sh

branches=()
eval "$(git for-each-ref --shell --format='branches+=(%(refname))' refs/heads/)"

echo "${style}Generating $reset"

generate () {
    ref=$1
    path="$REPO_PATH/docs/js/$ref"

    if [ "$2" == "true" ] && [ -d "$path" ]; then
        return
    fi

    echo "$style - $ref$reset"

    rm -rf $path
    mkdir $path

    cp "$REPO_PATH/esdoc.json" $path
    cp "$REPO_PATH/src/readme-js.md" "$path/README.md"

    cd $path
    (cd $FLARUM_PATH && git checkout -q -- . && git checkout -q $ref)
    npx esdoc -c esdoc.json 2>&1 >/dev/null

    cd $REPO_PATH
}

generate master
generate mithril-2-update

tags=$(cd $FLARUM_PATH && git tag)

for tag in $tags; do
    if [[ "$tag" =~ -beta.[0-9]{1,}.[0-9]{1,}$ ]]; then
        continue
    fi

    generate $tag true
done

bash $SCRIPTS_PATH/set-redirects.sh js
bash $SCRIPTS_PATH/set-index-file.sh js