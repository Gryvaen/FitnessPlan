#!/usr/bin/env python3
"""Create a deterministic update manifest for exactly this build's four APKs."""
import argparse
import hashlib
import json
import re
from pathlib import Path


def digest(path):
    h = hashlib.sha256()
    with path.open('rb') as f:
        for chunk in iter(lambda: f.read(1024 * 1024), b''):
            h.update(chunk)
    return h.hexdigest()


def generate(directory, version):
    if not re.fullmatch(r'\d+\.\d+\.\d+', version):
        raise ValueError('Expected stable version x.y.z')
    names = [f'FitnessPlan-{version}-android{suffix}.apk'
             for suffix in ('', '-arm64-v8a', '-armeabi-v7a', '-x86_64')]
    assets = []
    for name in names:
        path = directory / name
        if path.stat().st_size <= 0:
            raise ValueError(f'Empty APK: {name}')
        assets.append(dict(name=name, size=path.stat().st_size, sha256=digest(path)))
    manifest = dict(schemaVersion=1, version=version, assets=assets)
    (directory / 'update-manifest.json').write_text(
        json.dumps(manifest, indent=2, ensure_ascii=False) + '\n', encoding='utf-8')
    (directory / 'SHA256SUMS').write_text(
        ''.join(f"{a['sha256']}  {a['name']}\n" for a in assets), encoding='utf-8')
    return manifest


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--dist', type=Path, default=Path('dist'))
    parser.add_argument('--version', required=True)
    args = parser.parse_args()
    generate(args.dist, args.version)
