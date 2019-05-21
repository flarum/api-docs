set -e

echo -e "\e[36m\e[1mTriggered new API documentation build"

echo -e "\e[36m\e[1mChecking out 'master'"
git checkout -qf master

export ROOT_PATH=$(cd $TRAVIS_BUILD_DIR/.. && pwd)

echo -e "\e[36m\e[1mCloning flarum/core"

git clone https://github.com/flarum/core $ROOT_PATH/flarum > /dev/null

if [[ -z "$SHA" ]]; then
  echo -e "\e[36m\e[1m-> Using latest commit"

  SHA=$(cd $ROOT_PATH/flarum && git rev-parse --verify HEAD --short)
else
  echo -e "\e[36m\e[1m-> Checking out $SHA"

  BRANCH=$(cd $ROOT_PATH/flarum && git checkout $SHA > /dev/null && git rev-parse --abbrev-ref HEAD)

  if [[ "$BRANCH" != "master" ]]; then
    echo -e "\e[31m\e[1m-> !! Branch is not master ($BRANCH)"
    exit 1
  fi
fi

MESSAGE="update master ($SHA)"

echo -e "\e[36m\e[1mBuilding for commit $SHA\n"

# Build node src --php --js
REPO_FOLDER=$(basename `pwd`) node src --php --js

# Commit + Push
echo -e "\e[36m\e[1mSetting up git"

git config user.name "Travis CI"
git config user.name "travis@travis-ci.org"

echo -e "\e[36m\e[1mCommitting changes"

if [[ ! -z "$(git diff-index --name-only HEAD docs/js)" ]]; then
  echo -e "\e[36m\e[1m- JS"
  git add docs/js
  git commit -m "js: $MESSAGE"
fi

if [[ ! -z "$(git diff-index --name-only HEAD docs/php)" ]]; then
  echo -e "\e[36m\e[1m- PHP"
  git add docs/php
  git commit -m "php: $MESSAGE"
fi

echo -e "\e[36m\e[1mPushing changes"

git remote set-url origin https://datitisev:${GH_TOKEN}@github.com/$TRAVIS_REPO_SLUG.git > /dev/null 2>&1
git push --quiet

echo -e "\e[36m\e[1mDone! Visit https://api.flarum.dev for the latest API documentation"
