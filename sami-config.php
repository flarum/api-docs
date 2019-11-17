<?php

use Sami\Sami;
use Sami\RemoteRepository\GitHubRemoteRepository;
use Sami\Version\GitVersionCollection;
use Symfony\Component\Finder\Finder;

$flarumFolder = getenv('ROOT_PATH').DIRECTORY_SEPARATOR.'flarum';

$iterator = Finder::create()
  ->files()
  ->name('*.php')
  ->in(getenv('ROOT_PATH').'/flarum/src');

$versions = GitVersionCollection::create($flarumFolder)
  ->addFromTags('v0.1.*')
  ->add('master', 'master');

return new Sami($iterator, array(
  'theme'                 => 'flarum',
  'versions'              => $versions,
  'title'                 => 'Flarum API',
  'build_dir'             => __DIR__ . '/docs/php/%version%/',
  'cache_dir'             => __DIR__ . '/cache/php/%version%/',
  'template_dirs'         => array(__DIR__.'/themes/flarum'),
  'remote_repository'     => new GitHubRemoteRepository('flarum/core', $flarumFolder),
  'default_opened_level'  => 1,
  'source_url'            => 'https://github.com/flarum/core/',
  'source_dir'            => 'src'
));
