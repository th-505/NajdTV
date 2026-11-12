import {spawnSync} from 'node:child_process';
const sources=['3isk','arabseed','cimanow','laroza','qfilm','mycima'];
for(const source of sources){
  const run=spawnSync(process.execPath,['--import','./scripts/provider-fixture-network-guard.mjs',`scripts/providers/${source}.fixture.test.mjs`],{stdio:'inherit',timeout:30000});
  if(run.status!==0)process.exit(run.status || 1);
}
console.log('Six audited provider fixture suites passed without live network');
