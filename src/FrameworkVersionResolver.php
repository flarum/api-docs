<?php

/**
 * Resolves Laravel framework versions per Flarum git ref, read
 * directly from git history (git show <ref>:composer.json) rather than
 * the working tree — correct regardless of what Doctum currently has
 * checked out, and computed once up front per ref.
 */
final class FrameworkVersionResolver
{
    /** @var array<string, array{laravel: ?string}> */
    private array $cache = [];

    public function __construct(private readonly string $repoDir)
    {
    }

    /** @param array<string, string> $refs label => git ref (tag or branch) */
    public function preload(array $refs): void
    {
        foreach ($refs as $label => $ref) {
            $this->cache[$label] = $this->resolveForRef($ref);
        }
    }

    public function get(string $label, string $library): ?string
    {
        return $this->cache[$label][$library] ?? null;
    }

    /** @return array{laravel: ?string, symfony: ?string} */
    private function resolveForRef(string $ref): array
    {
        $require = $this->readComposerRequire($ref);

        return [
            'laravel' => $this->resolveLaravelVersion($require),
        ];
    }

    /** @return array<string, string> */
    private function readComposerRequire(string $ref): array
    {
        $cmd = sprintf(
            'git -C %s show %s',
            escapeshellarg($this->repoDir),
            escapeshellarg("$ref:composer.json")
        );

        $output = @shell_exec($cmd);

        if (!$output || trim($output) === '') {
            return [];
        }

        $decoded = json_decode($output, true);

        return is_array($decoded['require'] ?? null) ? $decoded['require'] : [];
    }

    private function resolveLaravelVersion(array $require): ?string
    {
        foreach ($require as $package => $constraint) {
            if (str_starts_with($package, 'illuminate/')) {
                return preg_replace('/\^(\d+)\.\d+/', '$1.x', $constraint);
            }
        }
        return null;
    }
}