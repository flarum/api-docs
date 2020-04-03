#!/bin/bash -l

set -e

# log commands run, useful when debugging
trap 'log "$BASH_COMMAND"' DEBUG

log() {
    # ignore echo commands
    if [[ $1 != echo* ]]; then
        echo "##[command]$1"
    fi
}

getSHA() {
  echo $(cd $FLARUM_FOLDER && git rev-parse --verify HEAD --short)
}

echo -e "\e[36m\e[1mTriggered new API documentation build"

# -> BUILD

echo -e "\e[36m\e[1mChecking out 'master'"
git checkout -qf master

export ROOT_PATH=$(cd $GITHUB_WORKSPACE/.. && pwd)
export REPO_FOLDER=${PWD}
FLARUM_FOLDER="$ROOT_PATH/flarum"

echo -e "\e[36m\e[1mCloning flarum/core > $FLARUM_FOLDER"

git clone https://github.com/flarum/core $FLARUM_FOLDER &> /dev/null

echo -e "\e[36m\e[1m-> Using latest commit"

SHA=$(getSHA)

echo -e "\e[36m\e[1mBuilding for commit $SHA"

# Build node src --php --js
node src --php --js

# rewrite js
echo -e "\e[36m\e[1mBuilding ds/frontend-framework-rewrite-mithril"

cd $FLARUM_FOLDER
git fetch origin
git checkout ds/frontend-framework-rewrite-mithril
SHA_REWRITE=$(getSHA)

cd js
npm i --prefer-offline --no-audit
npm i -g typedoc typescript typedoc-plugin-external-module-map
typedoc src --includeDeclarations --ignoreCompilerErrors --jsx true --out "$REPO_FOLDER/docs/js/ds~frontend-framework-rewrite-mithril" --excludeExternals --name 'Flarum API' --plugin typedoc-plugin-external-module-map --external-modulemap ".*js\/src\/([\\w\\-_]+(\/[\\w\\-_]+)?)\/"  --listInvalidSymbolLinks --hideGenerator

# -> DEPLOY

cd $REPO_FOLDER

# Commit + Push
echo -e "\n\n\e[36m\e[1mSetting up git"

git config user.name "github-bot"
git config user.email "github-bot@users.noreply.github.com"

echo -e "\e[36m\e[1mCommitting changes"

message="update master (flarum/core@$SHA)"
messageRewrite="update ds/frontend-framework-rewrite-mithril (flarum/core@$SHA_REWRITE)"

if [[ "$(git diff --name-only docs/js/master | wc -l | bc)" -gt "1" ]]; then
  echo -e "\e[36m\e[1m- JS"
  git add docs/js/master
  git commit -m "js: $message"
fi

if [[ ! -z "$(git diff-index --name-only HEAD docs/php/master)" ]]; then
  echo -e "\e[36m\e[1m- PHP"
  git add docs/php
  git commit -m "php: $message"
fi

if [[ "$(git diff --name-only docs/js/ds~frontend-framework-rewrite-mithril | wc -l | bc)" -gt "1" ]]; then
  echo -e "\e[36m\e[1m- JS [ds/frontend-framework-rewrite-mithril]"
  git add docs/js/ds~frontend-framework-rewrite-mithril
  git commit -m "js: $messageRewrite"
fi

echo -e "\e[36m\e[1mPushing changes"

git remote set-url origin https://datitisev:${GH_TOKEN}@github.com/${GITHUB_REPOSITORY}.git
git push

echo -e "\e[36m\e[1mDone! Visit https://api.flarum.dev for the latest API documentation"
