set -e

echo -e "\e[36m\e[1mTriggered new API documentation build"

echo -e "\e[36m\e[1mChecking out 'master'"
git checkout -qf master

export ROOT_PATH=~
export REPO_FOLDER=docs
FLARUM_FOLDER="$ROOT_PATH/flarum"

echo -e "\e[36m\e[1mCloning flarum/core"

git clone https://github.com/flarum/core $FLARUM_FOLDER &> /dev/null

if [[ -z "$SHA" ]]; then
  echo -e "\e[36m\e[1m-> Using latest commit"

  SHA=$(cd $FLARUM_FOLDER && git rev-parse --verify HEAD --short)
else
  SHA="${SHA:0:8}"

  echo -e "\e[36m\e[1m-> Checking out $SHA"

  (cd $FLARUM_FOLDER && git checkout $SHA &> /dev/null)

  echo -e "\e[36m\e[1m-> Checking branch"

  BRANCH=$(cd $FLARUM_FOLDER && git branch --contains HEAD)

  (echo $BRANCH | grep -q 'master') || {
    echo -e "\e[31m\e[1m-> !! Branch is not master ($BRANCH)"
    exit 1
  }
fi

echo -e "\e[36m\e[1mBuilding for commit $SHA\n\n"

# Build node src --php --js
node src --php --js

# Commit + Push
echo -e "\n\n\e[36m\e[1mSetting up git"

git config user.name "Circle CI"
git config user.email "circleci@483ce7e429cf"

echo -e "\e[36m\e[1mCommitting changes"

message="update master (flarum/core@$SHA)"

if [[ "$(git diff --name-only docs/js | wc -l | bc)" -gt "1" ]]; then
  echo -e "\e[36m\e[1m- JS"
  git add docs/js
  git commit -m "[skip ci] js: $message" &> /dev/null
fi

if [[ ! -z "$(git diff-index --name-only HEAD docs/php)" ]]; then
  echo -e "\e[36m\e[1m- PHP"
  git add docs/php
  git commit -m "[skip ci] php: $message" &> /dev/null
fi

echo -e "\e[36m\e[1mPushing changes"

git remote set-url origin https://datitisev:${GH_TOKEN}@github.com/${CIRCLE_PROJECT_USERNAME}/${CIRCLE_PROJECT_REPONAME}.git > /dev/null 2>&1
git push -q &> /dev/null

echo -e "\e[36m\e[1mDone! Visit https://api.flarum.dev for the latest API documentation"
