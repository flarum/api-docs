<?php

use Doctum\Doctum;
use Doctum\RemoteRepository\GitHubRemoteRepository;
use Doctum\Version\GitVersionCollection;
use Symfony\Component\Finder\Finder;

$flarum = getenv('FLARUM_CORE_PATH');
$iterator = Finder::create()
  ->files()
  ->name('*.php')
  ->in("$flarum/src");

// Get all tags and find latest minor of each major version
$tags = explode("\n", trim(shell_exec("git -C $flarum tag")));
$latestMinors = [];

foreach ($tags as $tag) {
  if (preg_match('/^v?([0-9]+)\.([0-9]+)\.[0-9]+$/', $tag, $matches)) {
    $major = $matches[1];
    $minor = $matches[2];
    $key = "$major.$minor";
    
    // Store or update if this tag is newer
    if (!isset($latestMinors[$key]) || version_compare($tag, $latestMinors[$key], '>')) {
      $latestMinors[$key] = $tag;
    }
  }
}

unset($latestMinors['1.0']);
unset($latestMinors['1.1']);
unset($latestMinors['1.2']);

$versions = GitVersionCollection::create($flarum)
  ->add('1.x', '1.x')
  ->add('2.x', '2.x');

foreach ($latestMinors as $key => $tag) {
  $versions->add($tag, $tag);
}

return new Doctum($iterator, array(
  'theme'                 => 'flarum',
  'versions'              => $versions,
  'title'                 => 'Flarum API',
  'build_dir'             => __DIR__ . '/docs/php/%version%/',
  'cache_dir'             => __DIR__ . '/cache/php/%version%/',
  'template_dirs'         => array(__DIR__.'/themes/flarum'),
  'remote_repository'     => new GitHubRemoteRepository('flarum/framework', $flarum),
  'default_opened_level'  => 1,
  'source_url'            => 'https://github.com/flarum/framework/',
  'source_dir'            => 'src'
));
