// Explicit source replacements. Stored references retain their original parser;
// an unavailable old provider must never silently resolve a different work.
export const PROVIDER_REPLACEMENTS = Object.freeze({
  cimanow: 'egybest', fivetv: 'movizland', witanime: 'animezid',
});
export const activeProvider = id => !Object.hasOwn(PROVIDER_REPLACEMENTS, id);
