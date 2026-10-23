import unittest

from cleanup_gitee_releases import cleanup


class FakePlatform:
    base = 'https://test.invalid/repos/a/b'

    def __init__(self, tags):
        self.releases = [{'id': i, 'tag_name': tag} for i, tag in enumerate(tags)]
        self.assets = {r['id']: [
            {'id': 10, 'name': 'FitnessPlan-1.0.0-android.apk'},
            {'id': 11, 'name': 'update-manifest.json'},
            {'id': 12, 'name': 'other.apk'},
        ] for r in self.releases}
        self.deleted = []

    def request(self, method, url, payload=None):
        if '/attach_files' not in url:
            return self.releases if 'page=1' in url else []
        release_id = int(url.split('/releases/')[1].split('/')[0])
        if method == 'GET':
            return list(self.assets[release_id])
        asset_id = int(url.rsplit('/', 1)[1])
        self.deleted.append((release_id, asset_id))
        self.assets[release_id] = [a for a in self.assets[release_id] if a['id'] != asset_id]


class CleanupTests(unittest.TestCase):
    def test_keeps_latest_three_and_non_apk_attachments(self):
        p = FakePlatform(['v2.6.1', 'v2.6.2', 'v2.6.3', 'v2.6.4', 'v2.6.5'])
        cleanup(p, 'v2.6.5')
        self.assertEqual(p.deleted, [(0, 10), (1, 10)])
        cleanup(p, 'v2.6.5')
        self.assertEqual(p.deleted, [(0, 10), (1, 10)])

    def test_counts_new_release_and_protects_newer_and_unknown_tags(self):
        p = FakePlatform(['v2.6.1', 'v2.6.2', 'v2.6.3', 'v2.6.4', 'v2.6.6', 'nightly'])
        cleanup(p, 'v2.6.5')
        self.assertEqual(p.deleted, [(0, 10), (1, 10)])

    def test_protects_drafts_and_prereleases(self):
        p = FakePlatform(['v2.6.1', 'v2.6.2'])
        p.releases[0]['draft'] = True
        p.releases[1]['prerelease'] = True
        cleanup(p, 'v2.6.5')
        self.assertEqual(p.deleted, [])

    def test_rejects_unsafe_parameters_before_requests(self):
        for tag, keep in [('nightly', 3), ('v2.6.5', 1)]:
            with self.assertRaises(ValueError):
                cleanup(FakePlatform([]), tag, keep)


if __name__ == '__main__':
    unittest.main()
