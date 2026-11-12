// Offset resumes the same source page. Upstream page pagination stays separate.
export function validOffset(value = 0) {
  if (!/^(0|[1-9]\d{0,5})$/.test(String(value)) || Number(value) > 100000) throw Error('BAD_CATALOG_OFFSET');
  return Number(value);
}
export function boundedPage(items, offset = 0, limit = 60, field = 'data') {
  offset = validOffset(offset);
  const data = items.slice(offset, offset + limit);
  const partial = data.length === limit;
  const next = partial ? offset + data.length : null;
  return { [field]: data, partial, next_offset: next, next_cursor: next === null ? null : String(next) };
}
