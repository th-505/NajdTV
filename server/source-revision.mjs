import {execFileSync} from 'node:child_process';
import {fileURLToPath} from 'node:url';
const repositoryRoot=fileURLToPath(new URL('../',import.meta.url));
export function readSourceRevision({env=process.env,git=(...args)=>execFileSync('git',args,{cwd:repositoryRoot,encoding:'utf8',timeout:1000,stdio:['ignore','pipe','ignore']}).trim()}={}){
  const supplied=env.RENDER_GIT_COMMIT || env.MITV_SOURCE_COMMIT || env.GITHUB_SHA;
  if(supplied){
    return {source_commit:/^[a-f0-9]{40}$/i.test(supplied)?supplied.toLowerCase():null,
      source_commit_source:/^[a-f0-9]{40}$/i.test(supplied)?'build_environment':'unavailable'};
  }
  try{
    const sha=git('rev-parse','HEAD');
    return {source_commit:/^[a-f0-9]{40}$/i.test(sha)?sha.toLowerCase():null,
      source_commit_source:'git',source_tree_dirty:Boolean(git('status','--porcelain','--untracked-files=no'))};
  }catch{return {source_commit:null,source_commit_source:'unavailable'}}
}
