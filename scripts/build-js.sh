#!/bin/bash -l

source $(dirname $0)/_vars.sh

branches=()
eval "$(git for-each-ref --shell --format='branches+=(%(refname))' refs/heads/)"

echo -e "${style}Generating $reset"

generate () {
    trap 'log "$BASH_COMMAND"' DEBUG

    ref=$1
    path="$REPO_PATH/docs/js/$ref"
    js_path="$FLARUM_PATH/js"

    if [ "$2" == "true" ] && [ -d "$path" ]; then
        return
    fi

    echo -e "$style - $ref$reset"

    rm -rf $path
    mkdir $path

    cp "$REPO_PATH/typedoc.json" $js_path

    cd $path
    (cd $FLARUM_PATH && git checkout -q -- . && git checkout -q $ref)
    (cd $js_path && yarn install --frozen-lockfile)

    cd $js_path
    npx typedoc --gitRevision $ref --out ../../docs/js/$ref --customTitle "Flarum ($ref)"

    cd $REPO_PATH
}

generate master

tags=$(cd $FLARUM_PATH && git tag)

for tag in $tags; do
    if [[ "$tag" =~ v[0-9]{1,}\.[0-9]{1,}\.[1-9]{1,}$  || "$tag" =~ 0.1.0-beta ]]; then
        continue
    fi

    generate $tag true
done

bash $SCRIPTS_PATH/set-redirects.sh js
bash $SCRIPTS_PATH/set-index-file.sh js