#!/usr/bin/env python3
"""Publish already-built identical artifacts to GitHub and Gitee (no rebuild).

Requires GITHUB_TOKEN / GITEE_TOKEN. Tokens are never printed or saved.
"""
import argparse
import hashlib
import json
import os
import re
import subprocess
import sys
import urllib.error
import urllib.parse
import urllib.request
import uuid
from pathlib import Path

from release_manifest import digest


class ApiError(RuntimeError):
    def __init__(self, status):
        self.status = status
        super().__init__(f'API HTTP {status}')


class PublicRedirect(urllib.request.HTTPRedirectHandler):
    def redirect_request(self, req, fp, code, msg, headers, newurl):
        redirected = super().redirect_request(req, fp, code, msg, headers, newurl)
        if redirected:
            redirected.remove_header('Authorization')
        return redirected


# Gitee rejects release attachments over 100 MB ("文件大小已超出限制：100 MB").
GITEE_MAX_ASSET_BYTES = 100_000_000


class Platform:
    def __init__(self, name, repo, token, target):
        if not re.fullmatch(r'[\w.-]+/[\w.-]+', repo):
            raise ValueError('Invalid repository')
        self.name, self.token, self.target = name, token, target
        self.base = f'https://{"api.github.com" if name == "github" else "gitee.com/api/v5"}/repos/{repo}'
        self.git_url = f'https://{"github.com" if name == "github" else "gitee.com"}/{repo}.git'
        self.max_asset_size = GITEE_MAX_ASSET_BYTES if name == 'gitee' else None
        self.opener = urllib.request.build_opener(PublicRedirect())

    def request(self, method, url, payload=None, content_type='application/json'):
        headers = {'Accept': 'application/json', 'User-Agent': 'FitnessPlan-release'}
        if self.name == 'github':
            headers['Authorization'] = f'Bearer {self.token}'
        elif method == 'GET':
            url += ('&' if '?' in url else '?') + urllib.parse.urlencode({'access_token': self.token})
        elif isinstance(payload, dict):
            payload = dict(payload, access_token=self.token)
        data = json.dumps(payload).encode() if isinstance(payload, dict) else payload
        if data is not None:
            headers['Content-Type'] = content_type
        try:
            with self.opener.open(urllib.request.Request(url, data=data, headers=headers, method=method), timeout=120) as response:
                body = response.read()
                return json.loads(body) if body else None
        except urllib.error.HTTPError as error:
            raise ApiError(error.code) from None

    def get_release(self, tag):
        release = self.request('GET', self.base + '/releases/tags/' + urllib.parse.quote(tag, safe=''))
        # Gitee answers a missing release with HTTP 200 and a JSON null.
        if not isinstance(release, dict):
            raise ApiError(404)
        return release

    def find_release(self, tag):
        """Like get_release, but also finds a GitHub draft left by an earlier run."""
        try:
            return self.get_release(tag)
        except ApiError as error:
            # GitHub's /releases/tags/{tag} never returns drafts.
            if error.status != 404 or self.name != 'github':
                raise
        page = 1
        while True:
            batch = self.request('GET', f'{self.base}/releases?per_page=100&page={page}')
            for release in batch:
                if release.get('tag_name') == tag:
                    return release
            if len(batch) < 100:
                raise ApiError(404)
            page += 1

    def refresh(self, release, tag):
        if self.name == 'github':
            # By id: drafts are invisible to the by-tag endpoint.
            return self.request('GET', f"{self.base}/releases/{release['id']}")
        return self.get_release(tag)

    def remote_commit(self, tag):
        """Commit the new release's tag would point at: the existing remote tag,
        else the head of the target branch (where the platform creates it)."""
        refs = {}
        output = subprocess.run(
            ['git', 'ls-remote', self.git_url, f'refs/tags/{tag}', f'refs/tags/{tag}^{{}}', f'refs/heads/{self.target}'],
            check=True, capture_output=True, text=True, timeout=120,
        ).stdout
        for line in output.splitlines():
            sha, ref = line.split('\t', 1)
            refs[ref] = sha
        return (refs.get(f'refs/tags/{tag}^{{}}') or refs.get(f'refs/tags/{tag}')
                or refs.get(f'refs/heads/{self.target}'))

    def attachments(self, release):
        if self.name == 'github':
            # Asset listing is paginated; do not silently ignore later attachments.
            result = []
            page = 1
            while True:
                batch = self.request('GET', f"{self.base}/releases/{release['id']}/assets?per_page=100&page={page}")
                result.extend(batch)
                if len(batch) < 100:
                    return result
                page += 1
        assets = release.get('assets', [])
        return assets.get('links', []) if isinstance(assets, dict) else assets

    def upload(self, release, path):
        content = path.read_bytes()
        if self.name == 'github':
            url = release['upload_url'].split('{', 1)[0] + '?' + urllib.parse.urlencode({'name': path.name})
            self.request('POST', url, content, 'application/octet-stream')
        else:
            boundary = uuid.uuid4().hex
            prefix = (f'--{boundary}\r\nContent-Disposition: form-data; name="access_token"\r\n\r\n'
                      f'{self.token}\r\n--{boundary}\r\nContent-Disposition: form-data; name="file"; filename="{path.name}"\r\n'
                      'Content-Type: application/octet-stream\r\n\r\n').encode()
            data = prefix + content + f'\r\n--{boundary}--\r\n'.encode()
            self.request('POST', f"{self.base}/releases/{release['id']}/attach_files", data,
                         f'multipart/form-data; boundary={boundary}')

    def asset_digest(self, asset):
        # GitHub reports a SHA-256 per asset; draft assets have no public URL yet.
        reported = asset.get('digest') if self.name == 'github' else None
        if reported and reported.startswith('sha256:'):
            return asset['size'], reported[len('sha256:'):]
        return self.remote_digest(asset)

    def remote_digest(self, asset):
        # Always verify anonymously using the same public URL clients consume.
        url = asset.get('browser_download_url') or asset.get('direct_asset_url') or asset.get('url')
        if not url or urllib.parse.urlparse(url).scheme != 'https':
            raise ValueError('Missing public HTTPS attachment URL')
        h, size = hashlib.sha256(), 0
        with self.opener.open(urllib.request.Request(url, headers={'User-Agent': 'FitnessPlan-release'}), timeout=120) as response:
            for chunk in iter(lambda: response.read(1024 * 1024), b''):
                h.update(chunk)
                size += len(chunk)
        return size, h.hexdigest()


def publish(platform, tag, notes, paths, commit=None):
    """Returns the names skipped for exceeding the platform's size limit.

    The manifest still lists them: the app ignores manifest entries a source
    lacks and downloads those from the other source."""
    limit = getattr(platform, 'max_asset_size', None)
    skipped = [p.name for p in paths if limit and p.stat().st_size > limit]
    paths = [p for p in paths if p.name not in skipped]
    try:
        release = platform.find_release(tag)
    except ApiError as error:
        if error.status != 404:
            raise
        if commit:
            remote = platform.remote_commit(tag)
            if remote != commit:
                raise ValueError(f'{platform.target} on {platform.name} is not at the release commit; '
                                 'push or sync it first')
        release = platform.request('POST', platform.base + '/releases', {
            'tag_name': tag, 'name': tag, 'body': notes,
            'target_commitish': platform.target, 'prerelease': False,
            **({'draft': True} if platform.name == 'github' else {}),
        })
    if release.get('prerelease') or release.get('body', '').strip() != notes.strip():
        raise ValueError('Existing release type/notes conflict; refusing to overwrite')
    existing = {}
    for asset in platform.attachments(release):
        name = asset.get('name')
        if name in existing:
            raise ValueError('Duplicate attachment names')
        existing[name] = asset
    expected = {p.name: (p.stat().st_size, digest(p)) for p in paths}
    # Validate all existing files before uploading anything to this release.
    for path in paths:
        if path.name in existing and platform.asset_digest(existing[path.name]) != expected[path.name]:
            raise ValueError(f'Conflicting existing attachment: {path.name}')
    for path in paths:
        if path.name not in existing:
            platform.upload(release, path)
    release = platform.refresh(release, tag)
    verify(platform, release, expected, platform.asset_digest)
    if platform.name == 'github' and release.get('draft'):
        platform.request('PATCH', f"{platform.base}/releases/{release['id']}", {'draft': False})
        release = platform.refresh(release, tag)
    # Finally check the public URLs clients actually download from.
    verify(platform, release, expected, platform.remote_digest)
    return skipped


def verify(platform, release, expected, digest_of):
    final = {a['name']: a for a in platform.attachments(release)}
    for name, wanted in expected.items():
        if name not in final or digest_of(final[name]) != wanted:
            raise ValueError(f'Attachment verification failed: {name}')


def local_commit(tag):
    try:
        return subprocess.run(['git', 'rev-parse', '--verify', '--quiet', f'{tag}^{{commit}}'],
                              check=True, capture_output=True, text=True).stdout.strip()
    except subprocess.CalledProcessError:
        raise ValueError(f'Tag {tag} does not exist locally; create it on the release commit first') from None


def validate_bundle(directory, tag):
    manifest_path = directory / 'update-manifest.json'
    manifest = json.loads(manifest_path.read_text(encoding='utf-8'))
    if not re.fullmatch(r'v\d+\.\d+\.\d+', tag) or manifest.get('version') != tag[1:] or manifest.get('schemaVersion') != 1:
        raise ValueError('Tag/manifest mismatch')
    names = [f'FitnessPlan-{tag[1:]}-android{s}.apk' for s in ('', '-arm64-v8a', '-armeabi-v7a', '-x86_64')]
    entries = manifest['assets']
    if len(entries) != 4 or {e['name'] for e in entries} != set(names):
        raise ValueError('Expected exactly four ABI APKs')
    for entry in entries:
        path = directory / entry['name']
        if entry['size'] <= 0 or (path.stat().st_size, digest(path)) != (entry['size'], entry['sha256']):
            raise ValueError(f"Local APK mismatch: {entry['name']}")
    sums = ''.join(f"{e['sha256']}  {e['name']}\n" for e in entries)
    if (directory / 'SHA256SUMS').read_text(encoding='utf-8') != sums:
        raise ValueError('SHA256SUMS mismatch')
    return [directory / n for n in names] + [directory / 'SHA256SUMS', manifest_path]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--tag', required=True)
    parser.add_argument('--notes-file', type=Path, required=True)
    parser.add_argument('--dist', type=Path, default=Path('dist'))
    parser.add_argument('--github-repo', default='Gryvaen/FitnessPlan')
    parser.add_argument('--gitee-repo', default='Gryvaen/FitnessPlan')
    parser.add_argument('--github-target', default='main')
    parser.add_argument('--gitee-target', default='main')
    args = parser.parse_args()
    paths = validate_bundle(args.dist, args.tag)
    notes = args.notes_file.read_text(encoding='utf-8')
    try:
        commit = local_commit(args.tag)
    except ValueError as error:
        parser.error(str(error))
    failed = False
    for name in ('github', 'gitee'):
        token = os.environ.get(name.upper() + '_TOKEN')
        try:
            if not token:
                raise ValueError('Missing ' + name.upper() + '_TOKEN')
            platform = Platform(name, getattr(args, name + '_repo'), token, getattr(args, name + '_target'))
            skipped = publish(platform, args.tag, notes, paths, commit)
            print(f'{name}: published and verified {args.tag}')
            for skipped_name in skipped:
                print(f'{name}: skipped {skipped_name} (over the size limit; clients fall back to the other source)')
        except Exception as error:
            # Do not print transport errors: URLs may contain access tokens.
            detail = str(error) if isinstance(error, (ValueError, ApiError)) else type(error).__name__
            print(f'{name}: FAILED ({detail}); check target, permissions and network', file=sys.stderr)
            failed = True
    return int(failed)


if __name__ == '__main__':
    sys.exit(main())
