#!/usr/bin/env python3
"""Conservative repository inventory; never deletes files or equates zero imports to dead code."""
import collections, hashlib, json, pathlib, re, subprocess
ROOT = pathlib.Path(__file__).resolve().parents[1]
paths = sorted(set(subprocess.check_output(['git','-c','core.quotepath=false','ls-files','-z','--cached','--others','--exclude-standard'], cwd=ROOT,text=True).split('\0')))
paths = [p for p in paths if p]
paths = [p for p in paths if not p.startswith('scratch/ui-shell/') and p not in ['docs/REPOSITORY_INVENTORY.md','docs/repository-inventory.json']]
texts = {}
for p in paths:
    data = (ROOT/p).read_bytes()
    if b'\0' not in data:
        try: texts[p] = data.decode('utf-8')
        except UnicodeDecodeError: pass
code_ext = {'.mjs','.js','.cjs','.ts','.tsx','.jsx','.dart','.py','.html','.sh','.yml','.yaml','.json','.jsonc'}
code = [p for p in paths if pathlib.Path(p).suffix in code_ext]
edges = collections.defaultdict(set); inbound = collections.defaultdict(set); dynamic = []
for p in code:
    text = texts.get(p,'')
    for spec in re.findall(r'''(?:from\s*|import\s*(?:\(\s*)?|require\s*\(\s*)['"]([^'"\n]+)['"]''', text):
        if not spec.startswith('.'): continue
        resolved = (ROOT/pathlib.Path(p).parent/spec).resolve()
        for candidate in [resolved, pathlib.Path(str(resolved)+'.js'),pathlib.Path(str(resolved)+'.mjs'),resolved/'index.mjs']:
            try: rel = candidate.relative_to(ROOT).as_posix()
            except ValueError: continue
            if rel in paths: edges[p].add(rel); inbound[rel].add(p)
    if re.search(r'\b(?:import|require)\s*\(\s*[^\s\'"]', text): dynamic.append(p)
    # Literal filesystem, command, workflow and native bridge references count too.
    for target in paths:
        if target != p and target in text:
            edges[p].add(target); inbound[target].add(p)
roots = {'server/index-runtime.mjs','server/app.mjs','package.json','index.html','flutter_app/lib/main.dart'}
roots.update(p for p in paths if p.startswith('.github/workflows/') or re.search(r'(?:\.test\.(?:mjs|js)|_test\.(?:mjs|py|dart))$',p))
reachable=set();pending=list(roots)
while pending:
    p=pending.pop()
    if p in reachable: continue
    reachable.add(p);pending.extend(edges[p]-reachable)
text_lines={p:text.splitlines() for p,text in texts.items()}
def references(path):
    needles={path,pathlib.Path(path).name};result=[]
    for source,text in texts.items():
        if source==path or not any(n in text for n in needles):continue
        for number,line in enumerate(text_lines[source],1):
            if any(n in line for n in needles):
                result.append(source+':'+str(number));break
    return result
families=[p for p in paths if p.startswith(('server/providers/','server/scrapers/','server/browser/')) and pathlib.Path(p).suffix in {'.js','.mjs','.json'}]
records=[]
for p in families:
    refs=references(p);live=p in reachable
    records.append({'path':p,'reachable':live,'import_or_literal_users':sorted(inbound[p]),'text_references':refs,'decision':'KEEP' if live or refs else 'REVIEW_ONLY','reason':'reachable from runtime/tests/CI' if live else 'references remain; no deletion proof' if refs else 'no static/literal evidence; dynamic/native/manual usage unresolved; not approved for deletion'})
md=[]
for p in paths:
    if not p.endswith('.md'):continue
    refs=references(p)
    essential = pathlib.Path(p).name in {'NOTICE.md','LICENSE.md'} or p == 'docs/najd/SOURCE_POLICY_1.1.7.md' or p in {'README.md','AGENTS.md','PROJECT_STATE.md','FEATURE_QUEUE.md','FEATURE_REGISTRY.md','FEEDBACK.md','REVIEW_REPORT.md'} or p.startswith('.agents/') or p in {'docs/PROVIDER_CONTRACT.md','docs/DOMAIN_REVIEW_2026-11-12.md','docs/PROVIDER_FIXTURE_REVIEW.md'}
    archive=bool(re.search(r'LOG|HISTORY|REPORT|AUDIT|DELIVERY|STATE|REVIEW|IMPLEMENTATION|SECURITY|RELEASE|GATE|WORK_|PHASE|BATCH|NATIVE_UI_BUILD|INCIDENT|HANDOFF',p,re.I))
    classification='KEEP_REFERENCE' if essential or refs else 'KEEP_HISTORY' if archive else 'MERGE_REVIEW'
    md.append({'path':p,'classification':classification,'references':refs,'reason':'convention-loaded instruction/current reference or referenced document' if essential or refs else 'retained historical evidence; age does not prove obsolescence' if archive else 'unreferenced standalone documentation; review and consolidate, do not delete without content comparison'})
instructions=[p for p in paths if p.startswith('.agents/') or pathlib.Path(p).name in {'AGENTS.md','CLAUDE.md','.cursorrules'} or re.search(r'(?:instructions|agent.rules)',p,re.I)]
backups=[p for p in paths if re.search(r'(?:\.(?:bak|old|tmp|orig)$|copy|backup)',pathlib.Path(p).name,re.I)]
hashes=collections.defaultdict(list)
for p in paths:
    data=(ROOT/p).read_bytes()
    if data:hashes[hashlib.sha256(data).hexdigest()].append(p)
duplicates=[{'sha256':h,'files':names,'decision':'KEEP_PENDING_USAGE_REVIEW'} for h,names in hashes.items() if len(names)>1]
report={'requested_base':'7317d9c86e85770cf4fff6f9da5b69fd3352f9c6','integrated_main':'6ebb30ec36db12ef5fd427a00d2faa262d8e5047','snapshot_includes_working_tree':True,'base_sha':subprocess.check_output(['git','rev-parse','HEAD'],cwd=ROOT,text=True).strip(),'method':'conservative static imports + literal filesystem/command/native references + runtime/test/CI reachability; no deletion is authorized by this report','files_scanned':len(paths),'roots':sorted(roots),'dynamic_import_files':dynamic,'families':records,'markdown':md,'instructions':[{'path':p,'references':references(p),'decision':'KEEP_OR_UPDATE','reason':'AGENTS and skills load by convention; zero imports cannot prove disuse'} for p in instructions],'backup_candidates':[{'path':p,'references':references(p),'decision':'REVIEW_ONLY'} for p in backups],'duplicate_groups':duplicates,'approved_deletions':[]}
(ROOT/'docs/repository-inventory.json').write_text(json.dumps(report,ensure_ascii=False,indent=2)+'\n')
lines=['Repository cleanup inventory — no deletions','',f'Base: `{report["base_sha"]}`. Files scanned: {len(paths)}. Scope includes both registered families, legacy providers, source seed config, tests, CI, package scripts and literal filesystem/native references.','', 'This is a conservative static inventory, not a proof that unreferenced code is unused. Dynamic expressions, convention-loaded skills, native entry points and manually invoked tools remain blockers. All approved-deletion lists are empty. No cleanup commit is permitted before owner approval.','', 'Code and configuration inventory','', '| File | Reachability | Evidence / decision |','|---|---|---|']
for r in records:lines.append('|`'+r['path']+'`|'+str(r['reachable'])+'|'+r['decision']+': '+r['reason']+'; users: '+', '.join(r['import_or_literal_users'][:5])+'|')
lines+=['','Markdown inventory — every file','', '| File | Classification | Evidence / reason |','|---|---|---|']
for r in md:lines.append('|`'+r['path']+'`|'+r['classification']+'|'+r['reason']+'; '+', '.join(r['references'][:3])+'|')
lines+=['','Instructions and skills','']
for r in report['instructions']:lines.append('- `'+r['path']+'`: keep/update; '+r['reason']+'.')
lines+=['','Instruction findings: AGENTS.md correctly routes provider work to scraper maintenance and UI work to brand guidance. The scraper skill explicitly covers both legacy and current safety/identity invariants; no contradictory deletion instruction was found. Its knowledge-index links can be updated to include PROVIDER_CONTRACT.md and this review. Brand skills concern a separate UI scope and are not dead because this task did not invoke them. `matv-master-blueprint/SKILL.md` still says 21 scrapers, while the registry check proves 25 entries per family (23 non-mirror + 2 mirrors): propose updating counts and linking the live registry. Generic graphify and Hermes tool skills assume optional tools not declared by package.json; scope them to their own tools instead of deleting them. `test-driven-development`/`hermes-test-driven-development` and generic/Hermes debugging/review skills overlap: propose a single routing index, not unproven deletion.','', 'Backup-name candidates','']
for r in report['backup_candidates']:lines.append('- `'+r['path']+'`: name match only; references '+', '.join(r['references'][:5])+'; not approved for deletion.')
if not backups:lines.append('No tracked/unignored filename matches the requested backup patterns.')
lines+=['','Exact byte duplicates — not deletion proof','']
for r in duplicates:lines.append('- '+', '.join('`'+p+'`' for p in r['files'])+'; retain pending path/runtime/asset compatibility review.')
lines+=['','Concrete documentation consolidation: docs/IDENTITY_V1_0_13.md describes the superseded black/gold Qaf identity; docs/IDENTITY_V1_0_17.md explicitly supersedes it with a Q mark. Both are historical relative to current Najd branding: propose archival labels plus a link to current brand rules, not removal of history. docs/CONTENT_RUNTIME_1.0.1.md explicitly records an intended old Basri migration: archive its status and link PROVIDER_CONTRACT.md. Retain SOURCE_POLICY_1.1.7.md as current source-identity authority and font NOTICE.md as licensing evidence.', '', 'Deletion proposal: NONE APPROVED. MERGE_REVIEW documents and REVIEW_ONLY code are review candidates, not proven dead files. The JSON inventory contains full line-reference evidence. Existing generated platform artifacts and duplicated Najd/Beta source implementations must not be removed merely for hash/import similarity.','', 'Validation: rerun the six requested suites after inventory generation. No application behavior is changed by this inventory.']
(ROOT/'docs/REPOSITORY_INVENTORY.md').write_text('\n'.join(lines)+'\n')
print(json.dumps({'files':len(paths),'family_files':len(records),'markdown':len(md),'review_only_code':[r['path'] for r in records if r['decision']=='REVIEW_ONLY'],'merge_review_docs':[r['path'] for r in md if r['classification']=='MERGE_REVIEW'],'backup_candidates':backups,'duplicate_groups':len(duplicates),'approved_deletions':[]},ensure_ascii=False))
