#!/usr/bin/env python3
import csv
import hashlib
import json
import pathlib
import urllib.request

ROOT = pathlib.Path(__file__).resolve().parent
MANIFEST_PATH = ROOT / "fc27_complete_manifest.json"
OUT = ROOT / "FC27_COMPLETE"
BASE = "https://raw.githubusercontent.com/{repo}/{commit}/{path}"


def git_blob_sha1(data: bytes) -> str:
    header = f"blob {len(data)}\0".encode("ascii")
    return hashlib.sha1(header + data).hexdigest()


def count_csv_rows(path: pathlib.Path) -> int:
    with path.open("r", encoding="utf-8", newline="") as f:
        return max(sum(1 for _ in csv.reader(f)) - 1, 0)


def main():
    manifest = json.loads(MANIFEST_PATH.read_text(encoding="utf-8"))
    OUT.mkdir(exist_ok=True)
    failures = []

    for item in manifest["files"]:
        url = BASE.format(repo=manifest["repository"], commit=manifest["commit"], path=item["path"])
        dest = OUT / item["name"]
        print(f"Downloading {item['name']} ...")
        req = urllib.request.Request(url, headers={"User-Agent": "fc27-complete-dataset-verifier/1.0"})
        with urllib.request.urlopen(req, timeout=120) as r:
            data = r.read()
        dest.write_bytes(data)

        size_ok = len(data) == item["size_bytes"]
        sha = git_blob_sha1(data)
        sha_ok = sha == item["git_blob_sha1"]
        rows = count_csv_rows(dest)
        rows_ok = rows == item["data_rows_expected"]
        print(f"  bytes: {len(data)} ({'OK' if size_ok else 'FAIL'})")
        print(f"  git blob sha1: {sha} ({'OK' if sha_ok else 'FAIL'})")
        print(f"  data rows: {rows} ({'OK' if rows_ok else 'FAIL'})")
        if not (size_ok and sha_ok and rows_ok):
            failures.append(item["name"])

    if failures:
        raise SystemExit("Validation failed: " + ", ".join(failures))
    print(f"\nAll {len(manifest['files'])} files downloaded and validated in {OUT}")


if __name__ == "__main__":
    main()
