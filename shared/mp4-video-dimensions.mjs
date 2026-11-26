// ISO base media file boxes are length-prefixed. Inspect track metadata only.
function* boxes(bytes, start, end, allowTruncated = false) {
  for (let offset = start; offset + 8 <= end;) {
    let size = bytes.readUInt32BE(offset);
    let headerLength = 8;
    if (size === 1) {
      if (offset + 16 > end) return;
      const wide = bytes.readBigUInt64BE(offset + 8);
      if (wide > BigInt(Number.MAX_SAFE_INTEGER)) return;
      size = Number(wide);
      headerLength = 16;
    }
    const extendsToEnd = size === 0;
    if (extendsToEnd) size = end - offset;
    if (size < headerLength) return;
    const boxEnd = offset + size;
    if (boxEnd > end && !allowTruncated) return;
    yield {type:bytes.toString('ascii',offset+4,offset+8),start:offset+headerLength,
      end:Math.min(boxEnd,end),declaredEnd:extendsToEnd?null:boxEnd};
    if (boxEnd > end) return;
    offset = boxEnd;
  }
}

const visualEntries = new Set(['avc1','avc3','hvc1','hev1','av01','vp08','vp09','mp4v']);

function videoSampleDimensions(bytes, mediaBoxes) {
  const mediaInfo = mediaBoxes.find(box=>box.type==='minf');
  if (!mediaInfo) return [];
  const table = [...boxes(bytes,mediaInfo.start,mediaInfo.end,true)].find(box=>box.type==='stbl');
  if (!table) return [];
  const descriptions = [...boxes(bytes,table.start,table.end,true)].find(box=>box.type==='stsd');
  if (!descriptions || descriptions.end-descriptions.start<8) return [];
  const found = [];
  for (const sample of boxes(bytes,descriptions.start+8,descriptions.end)) {
    if (!visualEntries.has(sample.type) || sample.end-sample.start<28) continue;
    found.push([bytes.readUInt16BE(sample.start+24),bytes.readUInt16BE(sample.start+26)]);
  }
  return found;
}

function dimensionsInMovie(bytes, movie) {
  const dimensions = new Map();
  for (const track of boxes(bytes,movie.start,movie.end,true)) {
    if (track.type !== 'trak') continue;
    const children = [...boxes(bytes,track.start,track.end,true)];
    const header = children.find(box=>box.type==='tkhd');
    const media = children.find(box=>box.type==='mdia');
    if (!header || header.declaredEnd!==header.end || !media) continue;
    const mediaBoxes=[...boxes(bytes,media.start,media.end,true)];
    const handler = mediaBoxes.find(box=>box.type==='hdlr');
    if (!handler || handler.declaredEnd!==handler.end || handler.end-handler.start<12 ||
      bytes.toString('ascii',handler.start+8,handler.start+12)!=='vide') continue;
    const sampleDimensions=videoSampleDimensions(bytes,mediaBoxes);
    if (sampleDimensions.length) {
      for (const [width,height] of sampleDimensions) {
        if (width>0&&height>0&&width<=16384&&height<=16384) {
          dimensions.set(width+'x'+height,{width,height,label:height+'p'});
        }
      }
      continue;
    }
    const version = bytes[header.start];
    const minimumLength = version === 0 ? 84 : version === 1 ? 96 : Infinity;
    if (header.end-header.start<minimumLength) continue;
    const width = bytes.readUInt32BE(header.end-8) / 65536;
    const height = bytes.readUInt32BE(header.end-4) / 65536;
    if (Number.isInteger(width)&&Number.isInteger(height)&&width>0&&height>0&&width<=16384&&height<=16384) {
      dimensions.set(width+'x'+height,{width,height,label:height+'p'});
    }
  }
  return [...dimensions.values()];
}

export function mp4MetadataOffset(prefix, length) {
  const bytes=Buffer.from(prefix||[]);
  for (const entry of boxes(bytes,0,bytes.length,true)) {
    if (entry.type==='mdat' && Number.isSafeInteger(entry.declaredEnd) &&
      entry.declaredEnd>=bytes.length && entry.declaredEnd+8<=length) return entry.declaredEnd;
  }
  return null;
}

export function observedMp4Dimensions(prefix, tail = null) {
  const bytes = Buffer.from(prefix || []);
  for (const movie of boxes(bytes,0,bytes.length,true)) {
    if (movie.type==='moov') return dimensionsInMovie(bytes,movie);
  }
  if (!tail) return [];
  const suffix = Buffer.from(tail);
  // A suffix can start inside media data. Recognize a full moov box ending at EOF.
  for (let position = suffix.indexOf('moov',4,'ascii'); position >= 0;
    position = suffix.indexOf('moov',position+4,'ascii')) {
    const offset = position - 4;
    const movie = boxes(suffix,offset,suffix.length).next().value;
    if (movie?.type==='moov' && movie.end===suffix.length) {
      const dimensions = dimensionsInMovie(suffix,movie);
      if (dimensions.length) return dimensions;
    }
  }
  return [];
}
