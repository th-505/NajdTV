import test from 'node:test';
import assert from 'node:assert/strict';
import {mkdtemp,mkdir,copyFile,writeFile,rm} from 'node:fs/promises';
import {tmpdir} from 'node:os';
import {join,resolve} from 'node:path';
import {spawnSync} from 'node:child_process';

test('repository font guard permits exact approved Web output but rejects modified and native font inputs',async()=>{
 const root=await mkdtemp(join(tmpdir(),'najd-font-guard-'));
 const guard=resolve('.github/scripts/check_repo_health.py');
 try{
  spawnSync('git',['init','-q'],{cwd:root});
  await mkdir(join(root,'shared'),{recursive:true});
  await copyFile('shared/thmanyah-font-faces.json',join(root,'shared/thmanyah-font-faces.json'));
  const directory=join(root,'internal_web/assets/assets/najd/fonts');await mkdir(directory,{recursive:true});
  const name='thmanyahsans-Regular.woff2',file=join(directory,name);
  await copyFile('assets/assets/najd/fonts/'+name,file);
  const check=()=>spawnSync('python3',[guard],{cwd:root,encoding:'utf8'});
  assert.equal(check().status,0,'approved hash and build path must be accepted');
  await writeFile(file,'modified font');assert.equal(check().status,1,'same filename with different bytes must fail');
  await rm(file);await writeFile(join(directory,'thmanyahsans-Regular.otf'),'private native input');
  assert.equal(check().status,1,'native font input must remain forbidden');
 }finally{await rm(root,{recursive:true,force:true});}
});
