<?php

use Doctum\Doctum;
use Doctum\RemoteRepository\GitHubRemoteRepository;
use Doctum\Version\GitVersionCollection;
use Symfony\Component\Finder\Finder;

$flarum = getenv('FLARUM_PATH');
$iterator = Finder::create()
  ->files()
  ->name('*.php')
  ->in("$flarum/src");

$versions = GitVersionCollection::create($flarum)
  ->addFromTags(function ($version) {
    return preg_match('/^v?([0-9]+)\.([0-9]+)\.0$/', $version) && (preg_match('/^v1\.[0-2]/i', $version) === 0);
  })
  ->add('main', 'main')
  ->add('2.x', '2.x');

return new Doctum($iterator, array(
  'theme'                 => 'flarum',
  'versions'              => $versions,
  'title'                 => 'Flarum API',
  'build_dir'             => __DIR__ . '/docs/php/%version%/',
  'cache_dir'             => __DIR__ . '/cache/php/%version%/',
  'template_dirs'         => array(__DIR__.'/themes/flarum'),
  'remote_repository'     => new GitHubRemoteRepository('flarum/main', $flarum),
  'default_opened_level'  => 1,
  'source_url'            => 'https://github.com/flarum/main/',
  'source_dir'            => 'src'
));
