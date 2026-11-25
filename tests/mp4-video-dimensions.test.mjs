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

test('a bounded suffix probe supplies fixed quality without marking the file adaptive',async()=>{
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
  assert.deepEqual(ranges,['bytes=0-32767',`bytes=${data.length-65536}-${data.length-1}`]);
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
