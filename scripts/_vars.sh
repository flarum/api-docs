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

export style="\e[47;1;31m"
export reset="\e[0m"

export SCRIPTS_PATH=$(dirname $0)
export REPO_PATH=$(cd $SCRIPTS_PATH; cd ..; pwd)
export FLARUM_PATH="${REPO_PATH}/flarum";

echo -e "${style}Using flarum/core @ $FLARUM_PATH$reset"

#echo "FLARUM_SHA=$(cd $FLARUM_PATH && git rev-parse --verify HEAD --short)" >> $GITHUB_ENV