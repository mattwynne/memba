"""Real read-only source / writable private build-artifact boundary."""
import json
from pathlib import Path
import subprocess
import tempfile
import unittest

from memba_runtime import argv


class BuildArtifactRuntimeTest(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory(); self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name); self.work = self.root / 'work'; self.work.mkdir()
        self.home = self.root / 'home'; self.home.mkdir(); (self.root / 'etc').mkdir()
        self.source_priv = self.work / 'web/priv'; self.source_priv.mkdir(parents=True)
        (self.source_priv / 'sentinel').write_text('immutable-source')
        self.build_priv = self.work / 'web/_build/test/lib/memba/priv'
        self.build_priv.parent.mkdir(parents=True)
        self.build_priv.symlink_to('../../../../priv')
        self.bwrap = '/nix/store/dk9qhjgg469lv6mriys7v4c59igarmvx-bubblewrap-0.11.1/bin/bwrap'
        (self.root / 'runtime.json').write_text(json.dumps({'bwrap':self.bwrap,'env':{'PATH':'/usr/bin:/bin'}}))

    def test_warm_build_priv_is_private_copy_not_readonly_source_link(self):
        argv(self.root,self.work,self.home,'true')
        self.assertFalse(self.build_priv.is_symlink())
        self.assertEqual((self.build_priv / 'sentinel').read_text(),'immutable-source')
        (self.build_priv / 'git_sha').write_text('private-build-artifact')
        self.assertFalse((self.source_priv / 'git_sha').exists())

    def test_real_build_artifact_write_succeeds_but_source_write_still_denied(self):
        args = argv(self.root,self.work,self.home,'true')
        args[-1] = '''set -eu
printf private-build-artifact > /work/web/_build/test/lib/memba/priv/git_sha
test "$(cat /work/web/_build/test/lib/memba/priv/git_sha)" = private-build-artifact
if printf changed > /work/web/priv/sentinel; then exit 11; fi
if printf changed > /work/web/priv/git_sha; then exit 12; fi
'''
        result = subprocess.run(args,capture_output=True,text=True,timeout=20)
        self.assertEqual(result.returncode,0,result.stdout+result.stderr)
        self.assertEqual((self.source_priv / 'sentinel').read_text(),'immutable-source')
        self.assertFalse((self.source_priv / 'git_sha').exists())


if __name__ == '__main__':
    unittest.main()
