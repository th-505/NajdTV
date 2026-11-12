// Host-failure fixtures must be deterministic too. Unknown requests fail the
// process even when a production parser catches the exception as a fallback.
export function installOfflineUpstreams(urls){
 const allowed=new Set(urls);let unexpected=0;
 globalThis.fetch=async input=>{
  const url=String(input?.url||input);
  if(!allowed.has(url)){unexpected++;process.stderr.write(`Unexpected fixture URL: ${url}\n`);throw Error('FIXTURE_UNEXPECTED_UPSTREAM');}
  return new Response('<html><title>Fixture host has no direct media</title></html>',
   {headers:{'content-type':'text/html'}});
 };
 process.on('exit',()=>{if(unexpected){process.stderr.write(`Unexpected fixture upstreams: ${unexpected}\n`);process.exitCode=1;}});
}
