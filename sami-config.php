<?php

use Sami\Sami;
use Sami\RemoteRepository\GitHubRemoteRepository;
use Sami\Version\GitVersionCollection;
use Symfony\Component\Finder\Finder;


$iterator = Finder::create()
  ->files()
  ->name('*.php')
  ->in('../flarum/src');

$versions = GitVersionCollection::create('../flarum')
  ->addFromTags('v0.1.*')
  ->add('master', 'master');

return new Sami($iterator, array(
  'theme'                 => 'flarum',
  'versions'              => $versions,
  'title'                 => 'Flarum API',
  'build_dir'             => './docs/php/%version%/',
  'cache_dir'             => './cache/php/%version%/',
  'template_dirs'         => array(__DIR__.'/themes/flarum'),
  'remote_repository'     => new GitHubRemoteRepository('flarum/core', '../flarum'),
  'default_opened_level'  => 1,
  'source_url'            => 'https://github.com/flarum/core/',
  'source_dir'            => 'src'
));
