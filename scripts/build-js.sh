#!/bin/bash -l

source $(dirname $0)/_vars.sh

branches=()
eval "$(git for-each-ref --shell --format='branches+=(%(refname))' refs/heads/)"

echo -e "${style}Generating $reset"

generate () {
    trap 'log "$BASH_COMMAND"' DEBUG

    ref=$1
    path="$REPO_PATH/docs/js/$ref"

    if [ "$2" == "true" ] && [ -d "$path" ]; then
        return
    fi

    echo -e "$style - $ref (`git rev-parse --short HEAD`) $reset"

    rm -rf $path
    mkdir $path

    cd $path
    (cd $FLARUM_PATH && git checkout -q -- . && git clean -f -d && git checkout -q $ref)
    (cd $FLARUM_PATH && yarn install --immutable)

    cp -v "$REPO_PATH/typedoc.package.json" "$FLARUM_CORE_PATH/js/typedoc.json"
    sed -i '11d' "$FLARUM_CORE_PATH/js/typedoc.json"
    for i in $(echo "$FLARUM_PATH/extensions/*/js"); do        
        cp -v "$REPO_PATH/typedoc.package.json" "$i/typedoc.json"
        
        if ! [[ -f "$i/tsconfig.json" ]]; then
            cp "$FLARUM_PATH/extensions/flags/js/tsconfig.json" "$i/tsconfig.json"
        fi

        # sed -i "s+framework/core/js/dist-typings+framework/core/js/src+g" "$i/tsconfig.json"
    done

    cd $REPO_PATH
    export NODE_OPTIONS="--max-old-space-size=16384"
    npx typedoc --gitRevision $ref --out "$REPO_PATH/docs/js/$ref" --name "Flarum ($ref)" --readme "$REPO_PATH/src/readme-js.md"

    cd $REPO_PATH
}

generate main
generate "2.x"

tags=$(cd $FLARUM_CORE_PATH && git tag)

for tag in $tags; do
    if [[ "$tag" =~ v[0-9]{1,}\.[0-9]{1,}\.[1-9]{1,}$  || "$tag" =~ 0.1.0-beta ]]; then
        continue
    fi

    generate $tag true
done

bash $SCRIPTS_PATH/set-redirects.sh js
bash $SCRIPTS_PATH/set-index-file.sh js