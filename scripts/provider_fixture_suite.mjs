import {spawnSync} from 'node:child_process';
import {readdirSync} from 'node:fs';
const sources=readdirSync('scripts/providers').filter(name=>name.endsWith('.fixture.test.mjs')).map(name=>name.replace('.fixture.test.mjs','')).sort();
for(const source of sources){
  const run=spawnSync(process.execPath,['--import','./scripts/provider-fixture-network-guard.mjs',`scripts/providers/${source}.fixture.test.mjs`],{stdio:'inherit',timeout:30000});
  if(run.status!==0)process.exit(run.status || 1);
}
console.log('Audited provider fixture suites passed without live network');
