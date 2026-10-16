#!/usr/bin/env python3
"""Multi-connection download into part files, then assemble (ODbL OFF dump friendly)."""

from __future__ import annotations

import argparse
import tempfile
import threading
import time
import urllib.request
from pathlib import Path

UA = "FitnessPlanFoodImporter/1.0 (local)"


def content_length(url: str) -> int:
    req = urllib.request.Request(url, method="HEAD", headers={"User-Agent": UA})
    with urllib.request.urlopen(req, timeout=60) as resp:
        cl = resp.headers.get("Content-Length")
        if not cl:
            raise RuntimeError("no Content-Length")
        return int(cl)


def fetch_range(url: str, dest: Path, start: int, end: int, progress: list[int], idx: int, lock: threading.Lock, errors: list) -> None:
    try:
        # Resume part file if partially downloaded
        have = dest.stat().st_size if dest.exists() else 0
        need_start = start + have
        if need_start > end:
            with lock:
                progress[idx] = end - start + 1
            return
        headers = {"User-Agent": UA, "Range": f"bytes={need_start}-{end}"}
        req = urllib.request.Request(url, headers=headers)
        mode = "ab" if have else "wb"
        with urllib.request.urlopen(req, timeout=180) as resp, dest.open(mode) as out:
            while True:
                chunk = resp.read(256 * 1024)
                if not chunk:
                    break
                out.write(chunk)
                with lock:
                    progress[idx] += len(chunk)
        final = dest.stat().st_size
        if final != (end - start + 1):
            raise RuntimeError(f"part {idx} size {final} != {end - start + 1}")
    except BaseException as e:  # noqa: BLE001
        with lock:
            errors.append(e)


def download(url: str, dest: Path, connections: int = 8) -> None:
    total = content_length(url)
    print(f"remote size: {total / (1024**3):.2f} GiB")

    if dest.exists() and dest.stat().st_size == total:
        print("already complete")
        return

    # Prefer continuing a contiguous prefix via single curl when possible is done
    # outside; here we always do part files for the whole file.
    parts_dir = dest.parent / (dest.name + ".parts")
    parts_dir.mkdir(parents=True, exist_ok=True)

    n = max(1, min(connections, total // (8 * 1024 * 1024) or 1))
    part_size = total // n
    ranges = []
    for i in range(n):
        s = i * part_size
        e = total - 1 if i == n - 1 else (i + 1) * part_size - 1
        ranges.append((s, e, parts_dir / f"{i:03d}.part"))

    progress = [0] * n
    # Seed progress from existing part sizes
    for i, (s, e, path) in enumerate(ranges):
        if path.exists():
            progress[i] = min(path.stat().st_size, e - s + 1)

    errors: list = []
    lock = threading.Lock()
    threads = [
        threading.Thread(
            target=fetch_range,
            args=(url, path, s, e, progress, i, lock, errors),
            daemon=True,
        )
        for i, (s, e, path) in enumerate(ranges)
    ]
    print(f"parts={n} already={sum(progress)/(1024**2):.1f} MiB")
    t0 = time.time()
    for t in threads:
        t.start()
    last = sum(progress)
    while any(t.is_alive() for t in threads):
        time.sleep(2)
        done = sum(progress)
        speed = (done - last) / 2
        last = done
        print(
            f"  {100*done/total:5.1f}%  {done/(1024**2):.1f}/{total/(1024**2):.1f} MiB  "
            f"{speed/1024:.0f} KiB/s  {time.time()-t0:.0f}s",
            flush=True,
        )
        if errors:
            break
    for t in threads:
        t.join(timeout=1)
    if errors:
        raise SystemExit(f"download failed: {errors[0]!r}")

    # Assemble
    tmp = dest.with_suffix(dest.suffix + ".assembling")
    with tmp.open("wb") as out:
        for _, _, path in ranges:
            with path.open("rb") as inp:
                while True:
                    chunk = inp.read(1024 * 1024)
                    if not chunk:
                        break
                    out.write(chunk)
    if tmp.stat().st_size != total:
        raise SystemExit(f"assembled size {tmp.stat().st_size} != {total}")
    tmp.replace(dest)
    print(f"done → {dest}")


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("url")
    ap.add_argument("-o", "--output", type=Path, required=True)
    ap.add_argument("-c", "--connections", type=int, default=8)
    args = ap.parse_args()
    download(args.url, args.output, args.connections)


if __name__ == "__main__":
    main()
