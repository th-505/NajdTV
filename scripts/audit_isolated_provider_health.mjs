// Owner-run audit: contains no resolved links, searches, cookies or credentials in output.
import {writeFile,mkdir} from 'node:fs/promises';
import {listIndependentProviders as coreProviders,getProvider as coreProvider} from '../server/scrapers/registry.mjs';
import {listIndependentProviders as betaProviders,getProvider as betaProvider} from '../server/browser/registry.mjs';
import {createServiceChecks} from '../server/diagnostics/service-checks.mjs';
const scope=process.argv.find(a=>a.startsWith('--scope='))?.split('=')[1]||'beta';
if(!['beta','najd'].includes(scope))throw Error('SCOPE_REQUIRED');
const folder=process.env.NAJD_AUDIT_DIR||'/tmp/najd-isolated-audit';await mkdir(folder,{recursive:true});
const release=process.argv.includes('--release');
const strictChecklist=release||process.argv.includes('--strict');
const provider=process.argv.find(arg=>arg.startsWith('--provider='))?.slice(11);
if (release) {
 const counts=Object.fromEntries([['najd',coreProviders],['beta',betaProviders]].map(([name,list])=>[
   name,list().filter(entry=>entry.enabled!==false&&entry.capabilities?.catalog).length,
 ]));
 if (provider || counts.najd!==39 || counts.beta!==39) {
  console.log(JSON.stringify({state:'blocked',reason:'EXPECTED_39_AUDITABLE_PROVIDERS_PER_FAMILY',counts}));
  process.exit(2);
 }
}
const select=providers=>()=>providers().filter(entry=>!provider||entry.id===provider);
const checks=createServiceChecks({strictChecklist,
  providers:select(coreProviders),lookup:coreProvider,
  betaProviders:select(betaProviders),betaLookup:betaProvider,
});
const job=checks.start(scope),deadline=Date.now()+(release?900000:180000);
let report;
do{
 report=checks.status(job.id);await writeFile(folder+'/'+scope+'.json',JSON.stringify({...report,observed_at:new Date().toISOString(),basis:'real-source-catalog-search-details-and-container-probe; not device decoding'},null,2));
 if(report.state==='ready')break;
 await new Promise(r=>setTimeout(r,1000));
}while(Date.now()<deadline);
console.log(JSON.stringify({scope,state:report.state,finished:report.finished,total:report.total,checks:report.checks.map(row=>({id:row.id,state:row.state,reason:row.reason,stages:row.stages,duration_ms:row.duration_ms}))}));
// A provider's internally bounded requests may still be settling at the audit deadline.
const complete=report.state==='ready'&&report.total>0&&
  (!strictChecklist||report.checks.every(row=>row.state==='passed'&&row.stages.length===9));
process.exit(complete?0:2);
