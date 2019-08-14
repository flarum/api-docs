set -e

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
