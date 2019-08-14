set -e

echo -e "\e[36m\e[1mTriggered new API documentation build"

echo -e "\e[36m\e[1mChecking out 'master'"
git checkout -qf master

export ROOT_PATH=$(cd $GITHUB_WORKSPACE/.. && pwd)
export REPO_FOLDER=${PWD##*/}
FLARUM_FOLDER="$ROOT_PATH/flarum"

echo -e "\e[36m\e[1mCloning flarum/core > $FLARUM_FOLDER"

git clone https://github.com/flarum/core $FLARUM_FOLDER &> /dev/null

echo -e "\e[36m\e[1m-> Using latest commit"

export SHA=$(cd $FLARUM_FOLDER && git rev-parse --verify HEAD --short)

echo -e "\e[36m\e[1mBuilding for commit $SHA\n\n"

# Build node src --php --js
node src --php --js