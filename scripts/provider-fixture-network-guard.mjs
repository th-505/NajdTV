// Preload for the audited offline suites. Test-owned mocks may replace fetch;
// any accidental live request fails the child, even if a scraper swallows it.
let attempts=0;
globalThis.fetch=async()=>{attempts++;throw Error('FIXTURE_UNEXPECTED_NETWORK');};
process.on('exit',()=>{if(attempts){process.stderr.write(`Offline suite attempted ${attempts} live requests\n`);process.exitCode=1;}});
