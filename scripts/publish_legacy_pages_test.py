"""Publication boundary: callback files are public, arbitrary inputs are not."""
import json
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
class PublishBoundary(unittest.TestCase):
    def fixture(self, root):
        repo = root/'repo'; repo.mkdir()
        subprocess.run(['git','init','-q',str(repo)],check=True)
        (repo/'scripts').mkdir(); (repo/'shared').mkdir()
        for name in ['publish_legacy_pages.py','verify_public_web.py']:
            shutil.copy2(ROOT/'scripts'/name, repo/'scripts'/name)
        shutil.copy2(ROOT/'shared/thmanyah-font-faces.json',repo/'shared/thmanyah-font-faces.json')
        (repo/'_config.yml').write_text('exclude: [internal_web]\n')
        site=root/'site';site.mkdir();(site/'assets').mkdir()
        (site/'index.html').write_text('<base href="/NajdTV/">')
        (site/'main.dart.js').write_text('// fixture')
        (site/'flutter_bootstrap.js').write_text('// fixture')
        (site/'assets/AssetManifest.bin').write_bytes(b'fixture')
        (site/'source-manifest.json').write_text(json.dumps({'source_commit':'a'*40}))
        for name in ['auth-callback.html','auth-callback.css','auth-callback.js']:
            (site/name).write_text('// public callback fixture')
        return repo, site
    def run_publish(self, repo, site):
        return subprocess.run(['python3',str(repo/'scripts/publish_legacy_pages.py'),str(site)],cwd=repo,capture_output=True,text=True)
    def test_exact_callback_assets_are_staged(self):
        with tempfile.TemporaryDirectory() as directory:
            repo,site=self.fixture(Path(directory)); result=self.run_publish(repo,site)
            self.assertEqual(result.returncode,0,result.stderr)
            staged=subprocess.check_output(['git','diff','--cached','--name-only'],cwd=repo,text=True).splitlines()
            for name in ['auth-callback.html','auth-callback.css','auth-callback.js']:
                self.assertIn(name,staged)
            self.assertFalse((repo/'.nojekyll').exists())
    def test_unexpected_input_fails_before_any_staging(self):
        with tempfile.TemporaryDirectory() as directory:
            repo,site=self.fixture(Path(directory));(site/'private-key.json').write_text('{}')
            result=self.run_publish(repo,site);self.assertNotEqual(result.returncode,0)
            self.assertIn('Unexpected public path',result.stderr)
            self.assertEqual(subprocess.check_output(['git','diff','--cached','--name-only'],cwd=repo),b'')
    def test_symlink_cannot_enter_public_output(self):
        with tempfile.TemporaryDirectory() as directory:
            repo,site=self.fixture(Path(directory));(site/'auth-callback.js').unlink()
            (site/'auth-callback.js').symlink_to(repo/'_config.yml')
            result=self.run_publish(repo,site);self.assertNotEqual(result.returncode,0)
            self.assertIn('Symlinks cannot enter public output',result.stderr)

if __name__=='__main__':unittest.main()
