import json
import io
import urllib.request
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

from publish_release import ApiError, Platform, PublicRedirect, main, publish, validate_bundle
from release_manifest import digest, generate


class FakePlatform:
    name = 'gitee'
    base = 'https://test.invalid/repos/a/b'
    target = 'master'

    def __init__(self):
        self.files = {}
        self.created = False
        self.uploads = []
        self.fail_name = None

    def get_release(self, tag):
        if not self.created:
            raise ApiError(404)
        return {'id': 1, 'body': 'notes'}

    find_release = get_release

    def refresh(self, release, tag):
        return self.get_release(tag)

    def remote_commit(self, tag):
        return self.head

    head = 'abc123'

    def request(self, method, url, payload):
        self.created = True
        return self.get_release('v3.0.0')

    def attachments(self, release):
        return [{'name': name} for name in self.files]

    def remote_digest(self, asset):
        return self.files[asset['name']]

    asset_digest = remote_digest

    def upload(self, release, path):
        if path.name == self.fail_name:
            raise ApiError(503)
        self.uploads.append(path.name)
        self.files[path.name] = (path.stat().st_size, digest(path))


class PublishTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.directory = Path(self.tmp.name)
        for suffix in ('', '-arm64-v8a', '-armeabi-v7a', '-x86_64'):
            (self.directory / f'FitnessPlan-3.0.0-android{suffix}.apk').write_bytes(('apk' + suffix).encode())
        generate(self.directory, '3.0.0')
        self.paths = validate_bundle(self.directory, 'v3.0.0')

    def test_both_platforms_receive_identical_files_manifest_last(self):
        a, b = FakePlatform(), FakePlatform()
        publish(a, 'v3.0.0', 'notes', self.paths)
        publish(b, 'v3.0.0', 'notes', self.paths)
        self.assertEqual(a.files, b.files)
        self.assertEqual(a.uploads[-1], 'update-manifest.json')

    def test_partial_failure_can_retry_without_reupload(self):
        platform = FakePlatform()
        platform.fail_name = self.paths[2].name
        with self.assertRaises(ApiError):
            publish(platform, 'v3.0.0', 'notes', self.paths)
        self.assertNotIn('update-manifest.json', platform.files)
        platform.fail_name = None
        publish(platform, 'v3.0.0', 'notes', self.paths)
        self.assertEqual(len(platform.uploads), len(self.paths))
        publish(platform, 'v3.0.0', 'notes', self.paths)
        self.assertEqual(len(platform.uploads), len(self.paths))

    def test_conflict_rejected_before_any_upload(self):
        platform = FakePlatform()
        platform.created = True
        platform.files[self.paths[-1].name] = (10, 'bad')
        with self.assertRaisesRegex(ValueError, 'Conflicting'):
            publish(platform, 'v3.0.0', 'notes', self.paths)
        self.assertEqual(platform.uploads, [])

    def test_local_tampering_and_wrong_tag_are_rejected(self):
        with self.assertRaises(ValueError):
            validate_bundle(self.directory, 'v2.0.0')
        self.paths[0].write_bytes(b'tampered')
        with self.assertRaises(ValueError):
            validate_bundle(self.directory, 'v3.0.0')

    def test_manifest_deterministic(self):
        before = self.paths[-1].read_bytes()
        generate(self.directory, '3.0.0')
        self.assertEqual(before, self.paths[-1].read_bytes())

    def test_existing_notes_conflict(self):
        platform = FakePlatform()
        platform.created = True
        with self.assertRaisesRegex(ValueError, 'notes conflict'):
            publish(platform, 'v3.0.0', 'different notes', self.paths)
        self.assertEqual(platform.uploads, [])

    def test_platform_failure_does_not_stop_other_platform(self):
        github, gitee = FakePlatform(), FakePlatform()
        github.fail_name = self.paths[0].name
        notes = self.directory / 'notes.md'
        notes.write_text('notes')
        with patch('sys.argv', ['publish_release.py', '--tag', 'v3.0.0', '--notes-file', str(notes), '--dist', str(self.directory)]), patch.dict('os.environ', {'GITHUB_TOKEN': 'secret-a', 'GITEE_TOKEN': 'secret-b'}), patch('publish_release.Platform', side_effect=[github, gitee]), patch('publish_release.local_commit', return_value='abc123'), patch('sys.stdout', new_callable=io.StringIO) as stdout, patch('sys.stderr', new_callable=io.StringIO) as stderr:
            self.assertEqual(main(), 1)
            self.assertIn('gitee: published', stdout.getvalue())
            self.assertIn('github: FAILED', stderr.getvalue())
            self.assertNotIn('secret-', stdout.getvalue() + stderr.getvalue())
        self.assertEqual(len(gitee.files), 6)

    def test_gitee_transport_uses_api_token_and_multipart_file(self):
        platform = Platform('gitee', 'Gryvaen/FitnessPlan', 'secret', 'master')
        requests = []
        class Opener:
            def open(self, request, timeout):
                requests.append(request)
                return io.BytesIO(b'{}')
        platform.opener = Opener()
        platform.get_release('v3.0.0')
        self.assertIn('/releases/tags/v3.0.0?access_token=secret', requests[-1].full_url)
        platform.upload({'id': 12}, self.paths[0])
        self.assertTrue(requests[-1].full_url.endswith('/releases/12/attach_files'))
        self.assertIn(b'name="file"', requests[-1].data)
        self.assertIn(b'name="access_token"', requests[-1].data)
        self.assertIn(self.paths[0].read_bytes(), requests[-1].data)

    def test_target_not_at_release_commit_is_rejected_before_creating(self):
        platform = FakePlatform()
        platform.head = 'old-release'
        with self.assertRaisesRegex(ValueError, 'not at the release commit'):
            publish(platform, 'v3.0.0', 'notes', self.paths, 'abc123')
        self.assertFalse(platform.created)
        platform.head = 'abc123'
        publish(platform, 'v3.0.0', 'notes', self.paths, 'abc123')
        self.assertEqual(len(platform.files), 6)

    def test_github_draft_is_found_verified_by_api_digest_then_published(self):
        expected = {p.name: (p.stat().st_size, digest(p)) for p in self.paths}
        state = {'draft': True, 'created': 0, 'public_checks': 0}
        assets = [{'name': name, 'size': size, 'digest': 'sha256:' + sha,
                   'browser_download_url': 'https://example.invalid/' + name}
                  for name, (size, sha) in expected.items()]
        platform = Platform('github', 'owner/repo', 'secret', 'main')

        def request(method, url, payload=None, content_type='application/json'):
            if '/releases/tags/' in url:
                raise ApiError(404)  # GitHub hides drafts from the by-tag endpoint.
            if method == 'GET' and '/releases?per_page' in url:
                return [{'id': 7, 'tag_name': 'v3.0.0', 'body': 'notes', 'draft': state['draft']}]
            if method == 'GET' and url.endswith('/releases/7'):
                return {'id': 7, 'body': 'notes', 'draft': state['draft']}
            if method == 'GET' and '/assets' in url:
                return assets
            if method == 'PATCH':
                state['draft'] = payload['draft']
                return {}
            if method == 'POST':
                state['created'] += 1
            raise AssertionError((method, url))

        def public(asset):
            self.assertFalse(state['draft'], 'draft assets have no public URL')
            state['public_checks'] += 1
            return expected[asset['name']]

        with patch.object(platform, 'request', side_effect=request), patch.object(platform, 'remote_digest', side_effect=public):
            publish(platform, 'v3.0.0', 'notes', self.paths, 'abc123')
        self.assertEqual(state['created'], 0)
        self.assertFalse(state['draft'])
        self.assertEqual(state['public_checks'], len(self.paths))

    def test_gitee_null_release_means_missing(self):
        platform = Platform('gitee', 'Gryvaen/FitnessPlan', 'secret', 'main')
        class Opener:
            def open(self, request, timeout):
                return io.BytesIO(b'null')
        platform.opener = Opener()
        with self.assertRaises(ApiError) as caught:
            platform.find_release('v3.0.0')
        self.assertEqual(caught.exception.status, 404)

    def test_oversized_files_are_skipped_on_limited_platform(self):
        big = self.directory / 'FitnessPlan-3.0.0-android.apk'
        big.write_bytes(b'x' * 50_000)  # The universal APK is the large one.
        generate(self.directory, '3.0.0')
        paths = validate_bundle(self.directory, 'v3.0.0')
        platform = FakePlatform()
        platform.max_asset_size = 10_000
        skipped = publish(platform, 'v3.0.0', 'notes', paths)
        self.assertEqual(skipped, [big.name])
        self.assertNotIn(big.name, platform.files)
        self.assertEqual(platform.uploads[-1], 'update-manifest.json')
        # Re-running is still a no-op.
        self.assertEqual(publish(platform, 'v3.0.0', 'notes', paths), skipped)
        self.assertEqual(len(platform.uploads), len(paths) - 1)

    def test_redirect_drops_authorization(self):
        request = urllib.request.Request('https://api.github.com/example', headers={'Authorization': 'Bearer secret'})
        redirected = PublicRedirect().redirect_request(request, None, 302, 'Found', {}, 'https://cdn.example.com/file')
        self.assertIsNone(redirected.get_header('Authorization'))


if __name__ == '__main__':
    unittest.main()
