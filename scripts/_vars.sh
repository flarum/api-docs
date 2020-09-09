#!/bin/bash -l

set -e

export style="\e[47;1;31m"
export reset="\e[0;10m"

export SCRIPTS_PATH=$(dirname $0)
export REPO_PATH=$(cd $SCRIPTS_PATH; cd ..; pwd)
export FLARUM_PATH="${REPO_PATH}/flarum";

echo -e "${style}Using flarum/core @ $FLARUM_PATH$reset"

echo "::set-env name=FLARUM_SHA::$(cd $FLARUM_PATH && git rev-parse --verify HEAD --short)"