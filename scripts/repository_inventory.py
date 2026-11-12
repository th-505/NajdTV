#!/usr/bin/env python3
"""Inventory current runtime/test/CI references. Never delete or infer liveness from hashes."""
import collections
import hashlib
import json
import pathlib
import re
import subprocess

ROOT = pathlib.Path(__file__).resolve().parents[1]
OUTPUTS = {'docs/REPOSITORY_INVENTORY.md', 'docs/repository-inventory.json'}
paths = sorted(set(subprocess.check_output(
    ['git', 'ls-files', '-z', '--cached', '--others', '--exclude-standard'], cwd=ROOT,
    text=True).split('\0')))
paths = [p for p in paths if p and (ROOT / p).is_file() and p not in OUTPUTS
         and not p.startswith('scratch/ui-shell/')]
texts = {}
for p in paths:
    data = (ROOT / p).read_bytes()
    if b'\0' not in data:
        try:
            texts[p] = data.decode('utf-8')
        except UnicodeDecodeError:
            pass
code_extensions = {'.mjs', '.js', '.cjs', '.ts', '.tsx', '.jsx', '.dart', '.py', '.html', '.sh', '.yml', '.yaml', '.json', '.jsonc'}
edges = collections.defaultdict(set)
inbound = collections.defaultdict(set)
for p, text in texts.items():
    if pathlib.Path(p).suffix not in code_extensions:
        continue
    specs = re.findall(r'''(?:from\s*|import\s*(?:\(\s*)?|require\s*\(\s*)?['"]([^'"\n]+)['"]''', text)
    for spec in specs:
        if not spec.startswith('.'):
            continue
        resolved = (ROOT / pathlib.Path(p).parent / spec).resolve()
        for candidate in [resolved, pathlib.Path(str(resolved) + '.js'), pathlib.Path(str(resolved) + '.mjs'), resolved / 'index.mjs']:
            try:
                target = candidate.relative_to(ROOT).as_posix()
            except ValueError:
                continue
            if target in paths:
                edges[p].add(target)
                inbound[target].add(p)
    for target in paths:
        if target != p and target in text:
            edges[p].add(target)
            inbound[target].add(p)
roots = {'server/index-runtime.mjs', 'server/app.mjs', 'edge/src/router.mjs', 'package.json', 'index.html', 'flutter_app/lib/main.dart'}
roots.update(p for p in paths if p.startswith('.github/workflows/') or re.search(r'(?:\.test\.(?:mjs|js)|_test\.(?:mjs|py|dart))$', p))
reachable = set()
pending = list(roots)
while pending:
    p = pending.pop()
    if p not in reachable:
        reachable.add(p)
        pending.extend(edges[p] - reachable)

families = [{'path': p, 'reachable': p in reachable, 'users': sorted(inbound[p]),
             'decision': 'KEEP_RUNTIME_OR_TEST' if p in reachable else 'REVIEW_DYNAMIC_OR_MANUAL_ENTRY'}
            for p in paths if p.startswith(('server/providers/', 'server/scrapers/', 'server/browser/'))
            and pathlib.Path(p).suffix in {'.js', '.mjs', '.json'}]
markdown = [{'path': p, 'users': sorted(inbound[p]), 'decision': 'KEEP_CURRENT_GUIDANCE_OR_LICENSE'}
            for p in paths if p.endswith('.md')]
backups = [{'path': p, 'users': sorted(inbound[p]), 'reachable': p in reachable}
           for p in paths if re.search(r'(?:\.(?:bak|old|tmp|orig)$|copy|backup)', pathlib.Path(p).name, re.I)]
hashes = collections.defaultdict(list)
for p in paths:
    hashes[hashlib.sha256((ROOT / p).read_bytes()).hexdigest()].append(p)
duplicates = [{'sha256': h, 'files': ps} for h, ps in hashes.items() if len(ps) > 1]
report = {'scope': 'Current source, Flutter, Node, Edge, website, tests, CI and approved build inputs',
          'method': 'Static imports plus literal filesystem/command references; dynamic/manual roots require review. A duplicate hash is never deletion proof.',
          'files_scanned': len(paths), 'roots': sorted(roots), 'families': families,
          'markdown': markdown, 'backup_candidates': backups, 'duplicate_groups': duplicates,
          'required_exceptions': {
              'app/source-manifest.json': 'Negative legacy-build fixture read by scripts/platform_parity_test.py',
              'docs/legacy/index.html.source': 'Browser and platform tests read this source',
              'library_backup_*': 'Live Flutter import/export feature, native/web conditional implementations and tests',
              'docs/providers.json': 'Generated current provider inventory checked by continuation CI',
              'docs/najd/RELEASE_4.0.2.md': 'Current release notes read by dynamic release workflows',
              'supabase/migrations/': 'Applied schema history; preserve all migrations',
          }}
(ROOT / 'docs/repository-inventory.json').write_text(json.dumps(report, ensure_ascii=False, indent=2) + '\n')
lines = ['# Current repository inventory', '',
         'Regenerate with `python3 scripts/repository_inventory.py`. This inventories the files that remain; deletion evidence is delivered separately, not retained as an archive.', '',
         '| Required file/group | Actual consumer |', '|---|---|']
for p, reason in report['required_exceptions'].items():
    lines.append(f'| `{p}` | {reason} |')
lines += ['', 'Registered Najd and Beta providers remain independent. Do not delete an implementation solely because it has an identical hash or no ordinary import: inspect registry loading, native conditional imports and tests.', '',
          f'Current scan: {len(paths)} files; {len(families)} provider-family code/config files; {len(markdown)} Markdown files. Full references, duplicate groups and backup-name matches are in `repository-inventory.json`.', '',
          'The only repository skills retained are the Najd branding and guarded scraper maintenance contracts invoked by AGENTS.md. Shared website/internal-web build assets and their licenses remain where current entrypoints need them.']
(ROOT / 'docs/REPOSITORY_INVENTORY.md').write_text('\n'.join(lines) + '\n')
print(json.dumps({'files': len(paths), 'provider_family_files': len(families), 'markdown': len(markdown), 'duplicate_groups': len(duplicates)}))
