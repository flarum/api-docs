const path = require('path');
const childProcess = require('child_process');
const cli = require('cli');
const progressbar = require('progressbar');
const progress = progressbar.create();

const exec = (cmd) => {
  return new Promise((resolve, reject) => {
    childProcess.exec(cmd, {
      cwd: path.resolve(__dirname, '../../'),
    }, (err, stdout, stderr) => {
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
    await exec(`cd docs/docs/js && mkdir -p ${BRANCH} && cat ../../esdoc.json > ${BRANCH}/esdoc.json && cp ../../src/readme-js.md ${BRANCH}/README.md`);
    progress.addTick();
    await exec(`cd docs/docs/js/${BRANCH} && npx esdoc -c esdoc.json`);
    progress.addTick();
    await exec(`cd docs/docs/js/${BRANCH} && rm -rf ast`);
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
    await exec(`cd docs/docs/php && mkdir -p ${BRANCH}`);
    progress.addTick();
    await exec(`cd docs && php sami.phar parse sami-config.php --only-version=${BRANCH} --force -n`).catch(e => {
      if (e.stdout && !e.stdout.includes(`[`)) return;
      handleError(e);
    });
    progress.addTick();
    await exec(`cd docs && php sami.phar render sami-config.php --only-version=${BRANCH} --force -n -v`);
    progress.addTick();
  } catch (err) {
    handleError(err);
  }
}

const jsDocumentation = async () => {
  await createJSDoc(`master`);
  await createJSDoc(`v0.1.0-beta`);
  await createJSDoc(`v0.1.0-beta.2`);
  await createJSDoc(`v0.1.0-beta.3`);
  await createJSDoc(`v0.1.0-beta.4`);
  await createJSDoc(`v0.1.0-beta.5`);
  await createJSDoc(`v0.1.0-beta.6`);
  await createJSDoc(`v0.1.0-beta.7`);
  await exec(`cd flarum && git checkout master`);
}

const phpDocumentation = async () => {
  await createPHPDoc(`master`);
  await createPHPDoc(`v0.1.0-beta`);
  await createPHPDoc(`v0.1.0-beta.2`);
  await createPHPDoc(`v0.1.0-beta.3`);
  await createPHPDoc(`v0.1.0-beta.4`);
  await createPHPDoc(`v0.1.0-beta.5`);
  await createPHPDoc(`v0.1.0-beta.6`);
  await createPHPDoc(`v0.1.0-beta.7`);
  await exec(`cd flarum && git checkout master`);
}

const main = async () => {
  cli.info(`=> Creating Documentation: JavaScript`);
  await jsDocumentation();
  cli.info(`=> Creating Documentation: PHP`);
  await phpDocumentation();
}

main();
