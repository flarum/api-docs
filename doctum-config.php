<?php

use Doctum\Doctum;
use Doctum\RemoteRepository\GitHubRemoteRepository;
use Doctum\Version\GitVersionCollection;
use Symfony\Component\Finder\Finder;
use Symfony\Component\Finder\Iterator\RecursiveDirectoryIterator;
use Symfony\Component\Finder\RecursiveFinder;

require_once __DIR__ . '/src/FrameworkVersionResolver.php';

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

// Read composer.json for each tagged version to get Laravel/Symfony versions
// Use git show to get composer.json at each specific tag (different Flarum versions have different deps)
$libraryVersions = [];

$versionRe = '/\\^(\\d+)\\.\\d+/m';
$versionSubst = '$1.x';

$allRefs = [
  ...$latestMinors,
  '1.x' => '1.x',
  '2.x' => '2.x',
];

foreach ($allRefs as $minorKey => $tag) {
  // $tag = $latestMinors[$minorKey];
  $versions = [];

  // Use git show to get composer.json at this specific tag
  $composerOutput = @shell_exec("git -C \"$flarum\" show $tag:composer.json");
  if ($composerOutput && strlen(trim($composerOutput)) > 0) {
    $composerJson = json_decode($composerOutput, true);

    if ($composerJson && isset($composerJson['require'])) {
      // Get Laravel version (check for illuminate packages)
      $hasIlluminate = false;
      foreach (array_keys($composerJson['require']) as $pkg) {
        if (str_starts_with($pkg, 'illuminate/')) {
          $illuminateVersion = $composerJson['require'][$pkg];
          $versions['laravel'] = preg_replace($versionRe, $versionSubst, $illuminateVersion);

          break;
        }
      }

      // Get Symfony version
      if (isset($composerJson['require']['symfony/config'])) {
        // Extract version constraint (e.g., ^5.2.2 -> 5.4)
        $symfonyConstraint = $composerJson['require']['symfony/config'];
        if (preg_match('/^[\^~]?(\d+)\.(\d+)/', $symfonyConstraint, $m)) {
          $versions['symfony'] = $m[1] . '.' . $m[2];
        }
      }
    }
  }

  $libraryVersions[$minorKey] = $versions;
}

$versions = GitVersionCollection::create($flarum)
  ->add('1.x', '1.x')
  ->add('2.x', '2.x');

foreach ($latestMinors as $key => $tag) {
  $versions->add($tag, $tag);
}

// Allow resolving dependency versions for API documentation links
$frameworkVersions = new FrameworkVersionResolver($flarum);
$frameworkVersions->preload([
    ...$latestMinors,
    '1.x' => '1.x',
    '2.x' => '2.x',
]);
$GLOBALS['frameworkVersions'] = $frameworkVersions;

function package_version(string $combined): ?string
{
    [$ref, $library] = explode(':', $combined, 2);

    return $GLOBALS['frameworkVersions']->get($ref, $library);
}


return new Doctum($iterator, array(
  'theme'                 => 'flarum',
  'versions'              => $versions,
  'title'                 => 'Flarum API',
  'build_dir'             => __DIR__ . '/docs/php/%version%/',
  'cache_dir'             => __DIR__ . '/cache/php/%version%/',
  'template_dirs'         => array(__DIR__ . '/themes/flarum'),
  'remote_repository'     => new GitHubRemoteRepository('flarum/framework', $flarum),
  'default_opened_level'  => 1,
  'source_url'            => 'https://github.com/flarum/framework/',
  'source_dir'            => 'src',
));
