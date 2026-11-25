import test from 'node:test';
import assert from 'node:assert/strict';
import {observedMp4Dimensions} from '../shared/mp4-video-dimensions.mjs';
import {probeHarvestMedia} from '../server/harvest/media-probe.mjs';

function box(type, ...body) {
  const payload=Buffer.concat(body), head=Buffer.alloc(8);
  head.writeUInt32BE(head.length+payload.length);
  head.write(type,4);
  return Buffer.concat([head,payload]);
}

function track(type,width,height) {
  const header=Buffer.alloc(84), handler=Buffer.alloc(12);
  handler.write(type,8);
  header.writeUInt32BE(width*65536,76);
  header.writeUInt32BE(height*65536,80);
  return box('trak',box('tkhd',header),box('mdia',box('hdlr',handler)));
}

const ftyp=box('ftyp',Buffer.from('isom', 'ascii'));
const moov=box('moov',track('soun',1920,1080),track('vide',1280,720));
const expected=[{width:1280,height:720,label:'720p'}];

test('MP4 dimensions come from declared video tracks and not audio or media payload',()=>{
  assert.deepEqual(observedMp4Dimensions(Buffer.concat([ftyp,moov])),expected);
  assert.deepEqual(observedMp4Dimensions(Buffer.concat([ftyp,box('mdat',moov)])),[]);
  assert.deepEqual(observedMp4Dimensions(Buffer.concat([ftyp,moov.subarray(0,-12)])),[]);
});

test('a bounded probe skips the video payload and reads the metadata offset',async()=>{
  const data=Buffer.concat([ftyp,box('mdat',Buffer.alloc(70000)),moov]);
  const ranges=[];
  const result=await probeHarvestMedia({url:'https://cdn.example/video.mp4',headers:{}},{
    headProbe:async()=>({statusCode:200}),
    fetchImpl:async(_url,options)=>{
      ranges.push(options.headers.Range);
      const [,start,end]=/^bytes=(\d+)-(\d+)$/.exec(options.headers.Range);
      return {status:206,bytes:data.subarray(Number(start),Number(end)+1),
        headers:new Headers({'content-range':`bytes ${start}-${end}/${data.length}`})};
    },
  });
  assert.equal(result.playable,true);
  assert.equal(result.adaptive,false);
  assert.deepEqual(result.quality_levels,expected);
  assert.deepEqual(ranges,['bytes=0-32767',`bytes=${data.length-moov.length}-${data.length-1}`]);
});

test('coded video size takes precedence over a different display size',()=>{
  const header=Buffer.alloc(84),handler=Buffer.alloc(12),visual=Buffer.alloc(78);
  handler.write('vide',8);
  header.writeUInt32BE(1280*65536,76);
  header.writeUInt32BE(720*65536,80);
  visual.writeUInt16BE(1920,24);
  visual.writeUInt16BE(1080,26);
  const sample=box('stsd',Buffer.from([0,0,0,0,0,0,0,1]),box('avc1',visual));
  const movie=box('moov',box('trak',box('tkhd',header),box('mdia',box('hdlr',handler),
    box('minf',box('stbl',sample)))));
  assert.deepEqual(observedMp4Dimensions(Buffer.concat([ftyp,movie])),[
    {width:1920,height:1080,label:'1080p'},
  ]);
});

test('large movie metadata can be verified from its opening boxes without reading the full metadata box',()=>{
  const movie=box('moov',track('vide',1280,720),box('free',Buffer.alloc(100000)));
  assert.deepEqual(observedMp4Dimensions(movie.subarray(0,65536)),expected);
});

test('a single HLS rendition exposes its initialization track resolution without offering auto',async()=>{
  const data=Buffer.concat([ftyp,moov]);
  const calls=[];
  const result=await probeHarvestMedia({url:'https://cdn.example/media/index.m3u8',headers:{}},{
    headProbe:async()=>({statusCode:200}),
    fetchImpl:async(url,options)=>{
      calls.push([url,options.headers.Range]);
      if(calls.length===1)return {status:200,headers:new Headers(),bytes:Buffer.from(
        `#EXTM3U\n#EXT-X-MAP:URI="fragment.mp4",BYTERANGE="${data.length}@64"\n#EXTINF:2\nnext.mp4\n`),
      };
      return {status:206,headers:new Headers({'content-range':`bytes 64-${63+data.length}/10000`}),bytes:data};
    },
  });
  assert.equal(result.playable,true);
  assert.equal(result.adaptive,false);
  assert.deepEqual(result.quality_levels,expected);
  assert.deepEqual(calls[1],['https://cdn.example/media/fragment.mp4',`bytes=64-${63+data.length}`]);
});

test('master quality can use verified dimensions for a bitrate-only variant without exposing its URL',async()=>{
  const base='https://cdn.example/master.m3u8';
  const data=Buffer.concat([ftyp,moov]);
  const requested=[];
  const result=await probeHarvestMedia({url:base,headers:{}},{
    headProbe:async()=>({statusCode:200}),
    fetchImpl:async(url)=>{
      requested.push(url);
      const content=url===base
        ? '#EXTM3U\n#EXT-X-STREAM-INF:BANDWIDTH=500000\nmedia/index.m3u8\n#EXT-X-STREAM-INF:BANDWIDTH=1000000\nhttps://elsewhere.example/index.m3u8\n'
        : url.endsWith('index.m3u8') ? '#EXTM3U\n#EXT-X-MAP:URI="init.mp4"\n' : data;
      return {status:200,headers:new Headers(),bytes:Buffer.from(content),url};
    },
  });
  assert.equal(result.adaptive,true);
  assert.deepEqual(result.quality_levels.map(({label})=>label),['720p','1000 kbps']);
  assert.ok(result.quality_levels.every(item=>!Object.hasOwn(item,'url')));
  assert.deepEqual(requested,[base,'https://cdn.example/media/index.m3u8','https://cdn.example/media/init.mp4']);
});
