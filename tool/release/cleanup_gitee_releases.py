#!/usr/bin/env python3
"""Keep recent Gitee APKs while preserving release pages and source archives."""
import argparse
import os
import re
import sys

from publish_release import Platform


def version(tag):
    match = re.fullmatch(r'v(\d+)\.(\d+)\.(\d+)', tag)
    return tuple(map(int, match.groups())) if match else None


def cleanup(platform, tag, keep=3):
    current = version(tag)
    if current is None or keep < 2:
        raise ValueError('Expected a vX.Y.Z tag and keep >= 2')
    releases = []
    page = 1
    while True:
        batch = platform.request('GET', f'{platform.base}/releases?per_page=100&page={page}')
        releases.extend(batch)
        if len(batch) < 100:
            break
        page += 1
    eligible = [r for r in releases if version(r.get('tag_name', '')) is not None
                and version(r['tag_name']) <= current
                and not r.get('draft') and not r.get('prerelease')]
    # Count this release even before it has been created by the publisher.
    versions = sorted({current, *(version(r['tag_name']) for r in eligible)}, reverse=True)
    protected = set(versions[:keep])
    removed = []
    for release in sorted(eligible, key=lambda r: version(r['tag_name'])):
        if version(release['tag_name']) in protected:
            continue
        base = f"{platform.base}/releases/{release['id']}/attach_files"
        assets = []
        page = 1
        while True:
            batch = platform.request('GET', f'{base}?per_page=100&page={page}')
            assets.extend(batch)
            if len(batch) < 100:
                break
            page += 1
        # Delete only this application's APKs; leave all other attachments alone.
        for asset in assets:
            if not re.fullmatch(r'FitnessPlan-[\w.+-]+\.apk', asset.get('name', '')):
                continue
            platform.request('DELETE', f"{base}/{asset['id']}", {})
            removed.append(asset['name'])
            print('gitee: removed old APK ' + asset['name'], flush=True)
    return removed


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--tag', required=True)
    parser.add_argument('--repo', default='Gryvaen/FitnessPlan')
    parser.add_argument('--keep', type=int, default=3)
    args = parser.parse_args()
    token = os.environ.get('GITEE_TOKEN')
    if not token:
        parser.error('GITEE_TOKEN is required')
    try:
        cleanup(Platform('gitee', args.repo, token, 'main'), args.tag, args.keep)
    except Exception as error:
        # Transport exception URLs can contain the access token.
        print('gitee cleanup failed: ' + type(error).__name__, file=sys.stderr)
        return 1
    return 0


if __name__ == '__main__':
    sys.exit(main())
