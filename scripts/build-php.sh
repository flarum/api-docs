source `dirname $0`/_vars.sh

php "$REPO_PATH/doctum.phar" update doctum-config.php -v

bash $SCRIPTS_PATH/set-redirects.sh php