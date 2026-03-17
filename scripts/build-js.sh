#!/bin/bash -l

source $(dirname $0)/_vars.sh

echo -e "${style}Generating $reset"

generate () {
    trap 'log "$BASH_COMMAND"' DEBUG

    ref=$1
    path="$REPO_PATH/docs/js/$ref"

    if [ "$2" == "true" ] && [ -d "$path" ]; then
        echo -e "$style - $ref -> tag already exists, skipping $reset"
        return
    fi

    # Check if we need to generate at all comparing the ref
    sha=$(cd "$FLARUM_CORE_PATH" && git rev-parse --verify --short "$ref^{commit}" 2>/dev/null || echo "unknown")
    ref_sha=$(cd "$FLARUM_CORE_PATH" && git rev-parse --verify "$ref^{commit}" 2>/dev/null || echo "")
    stamp_file="$path/.source-ref-sha"

    if [[ -n "$ref_sha" && -f "$stamp_file" ]] && [[ "$(cat "$stamp_file")" == "$ref_sha" ]]; then
        echo -e "$style - $ref ($sha) cached $reset"
        return
    fi


    echo -e "$style - $ref ($sha) $reset"

    rm -rf $path
    mkdir $path

    cd $path
    (cd $FLARUM_PATH && git checkout -q -- . && git clean -f -d && git checkout -q $ref)
    (cd $FLARUM_PATH && yarn install --immutable)

    # Rename to 'flarum' so that the JS docs are separate from the extensions.
    if [[ -f "$FLARUM_CORE_PATH/js/package.json" ]]; then
        sed -i 's/"name": "@flarum\/core"/"name": "flarum"/' "$FLARUM_CORE_PATH/js/package.json"
    fi

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

    printf '%s\n' "$ref_sha" > "$stamp_file"

    cd $REPO_PATH
}

generate "2.x"
generate "1.x"

declare -A latest_tags=()

while IFS= read -r tag; do
    # Only consider tags that match the pattern vX.Y.Z, where X, Y, and Z are numbers.
    # This ensures we ignore any tags that don't represent version numbers, such as pre-releases or other annotations.
    if [[ ! "$tag" =~ ^v([0-9]+)\.([0-9]+)\.([0-9]+)$ ]]; then
        continue
    fi

    # Keep the first entry from descending version sort for each major.minor key.
    key="${BASH_REMATCH[1]}.${BASH_REMATCH[2]}"

    # Ignore versions 1.0, 1.1, and 1.2 as they are not compatible with the current TypeScript setup.
    # They are from before the monorepo.
    case "$key" in
        1.0|1.1|1.2)
            continue
            ;;
    esac

    if [[ -z "${latest_tags[$key]}" ]]; then
        latest_tags[$key]="$tag"
    fi
done < <(cd "$FLARUM_CORE_PATH" && git tag --sort=-v:refname)

for key in $(printf '%s\n' "${!latest_tags[@]}" | sort -V); do
    generate "${latest_tags[$key]}" true
done

bash $SCRIPTS_PATH/set-redirects.sh php
bash $SCRIPTS_PATH/set-index-file.sh js