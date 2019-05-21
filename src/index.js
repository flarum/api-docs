const path = require('path');
const childProcess = require('child_process');
const cli = require('cli');
const progressbar = require('progressbar');
const progress = progressbar.create();

const argv = require('minimist')(process.argv.slice(2));
const branches = (argv._.length ? argv._ : ['master']);

const ROOT_PATH = process.env.ROOT_PATH || '../../';
const REPO_FOLDER = process.env.REPO_FOLDER || 'docs';

cli.info(`Repository ${REPO_FOLDER} @ ${ROOT_PATH}`);

const exec = (cmd) => {
  return new Promise((resolve, reject) => {
    childProcess.exec(cmd, {
      cwd: path.resolve(__dirname, ROOT_PATH),
    }, (err, stdout, stderr) => {
      if (argv.log) {
        console.log(stdout);
        console.error(stderr);
      }
      if (err) return reject({ stdout, stderr });
      resolve(stdout);
    });
  });
}
const handleError = (error) => {
  const { err, stdout, stderr } = error;
  process.stdout.write('\n\n');
  if (!err && !stdout && !stderr) cli.error(error); else cli.error(`${err ? `${err}\n\n` : ''}${stdout}\n${stderr}`);
  progress.finish();
  process.exit(1);
}

const createJSDoc = async (BRANCH) => {
  try {
    cli.info(`- ${BRANCH}`);
    progress.step(`Documentation JS (${BRANCH})`).setTotal(4);
    await exec(`cd flarum && git checkout ${BRANCH} && git pull origin ${BRANCH}`);
    progress.addTick()
    await exec(`cd ${REPO_FOLDER}/docs/js && mkdir -p ${BRANCH} && cat ../../esdoc.json > ${BRANCH}/esdoc.json && cp ../../src/readme-js.md ${BRANCH}/README.md`);
    progress.addTick();
    await exec(`cd ${REPO_FOLDER}/docs/js/${BRANCH} && npx esdoc -c esdoc.json`);
    progress.addTick();
    await exec(`cd ${REPO_FOLDER}/docs/js/${BRANCH} && rm -rf ast`);
    progress.addTick();
  } catch (err) {
    handleError(err);
  }
}

const createPHPDoc = async (BRANCH) => {
  try {
    cli.info(`- ${BRANCH}`);
    progress.step(`Documentation PHP (${BRANCH})`).setTotal(4);
    await exec(`cd flarum && git checkout ${BRANCH} && git pull origin ${BRANCH}`);
    progress.addTick();
    await exec(`cd ${REPO_FOLDER}/docs/php && mkdir -p ${BRANCH}`);
    progress.addTick();
    await exec(`cd ${REPO_FOLDER} && php sami.phar parse sami-config.php --only-version=${BRANCH} --force -n`).catch(e => {
      if (e.stdout && !e.stdout.includes(`[`)) return;
      handleError(e);
    });
    progress.addTick();
    await exec(`cd ${REPO_FOLDER} && php sami.phar render sami-config.php --only-version=${BRANCH} --force -n -v`);
    progress.addTick();
  } catch (err) {
    handleError(err);
  }
}

const jsDocumentation = async () => {
  for (const branch of branches) {
    await createJSDoc(branch);
  }
};

const phpDocumentation = async () => {
  for (const branch of branches) {
    await createPHPDoc(branch);
  }
};

(async () => {
  if (argv.javascript || argv.js) {
    cli.info('=> Creating Documentation: JavaScript');
    await jsDocumentation();
  }
  if (argv.php) {
    cli.info('=> Creating Documentation: PHP');
    await phpDocumentation();
  }
})();
