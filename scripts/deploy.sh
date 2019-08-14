set -e

echo -e "\e[36m\e[1mTriggered new API documentation build"

# -> BUILD

echo -e "\e[36m\e[1mChecking out 'master'"
git checkout -qf master

export ROOT_PATH=$(cd $GITHUB_WORKSPACE/.. && pwd)
export REPO_FOLDER=${PWD##*/}
FLARUM_FOLDER="$ROOT_PATH/flarum"

echo -e "\e[36m\e[1mCloning flarum/core > $FLARUM_FOLDER"

git clone https://github.com/flarum/core $FLARUM_FOLDER &> /dev/null

echo -e "\e[36m\e[1m-> Using latest commit"

SHA=$(cd $FLARUM_FOLDER && git rev-parse --verify HEAD --short)

echo -e "\e[36m\e[1mBuilding for commit $SHA\n\n"

# Build node src --php --js
node src --php --js

# -> DEPLOY

# Commit + Push
echo -e "\n\n\e[36m\e[1mSetting up git"

git config user.name "github-bot"
git config user.email "github-bot@users.noreply.github.com"

echo -e "\e[36m\e[1mCommitting changes"

message="update master (flarum/core@$SHA)"

if [[ "$(git diff --name-only docs/js | wc -l | bc)" -gt "1" ]]; then
  echo -e "\e[36m\e[1m- JS"
  git add docs/js
  git commit -m "js: $message"
fi

if [[ ! -z "$(git diff-index --name-only HEAD docs/php)" ]]; then
  echo -e "\e[36m\e[1m- PHP"
  git add docs/php
  git commit -m "php: $message"
fi

echo -e "\e[36m\e[1mPushing changes"

git remote set-url origin https://datitisev:${GH_TOKEN}@github.com/${GITHUB_REPOSITORY}.git
git push

echo -e "\e[36m\e[1mDone! Visit https://api.flarum.dev for the latest API documentation"
