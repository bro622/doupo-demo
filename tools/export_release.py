#!/usr/bin/env python3
"""Export release builds while excluding editor-only development addons."""

from __future__ import annotations

import argparse
import hashlib
import os
import shutil
import subprocess
import sys
import time
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
PROJECT = ROOT / "doupo-demo"
TMP_ROOT = ROOT / ".release_tmp"
DOWNLOADS = ROOT / "downloads"

DEVELOPMENT_ADDONS = [
    PROJECT / "addons" / "godot_mcp",
]

EXPORTS = [
    (
        "Windows Desktop",
        PROJECT / "windows" / "斗破苍穹·斗帝之路 - Demo.exe",
        DOWNLOADS / "doupo-demo-v0.1.0.exe",
    ),
    (
        "Android",
        PROJECT / "Android" / "斗破苍穹·斗帝之路 - Demo.apk",
        DOWNLOADS / "doupo-demo-v0.1.0.apk",
    ),
]

KNOWN_GODOT_PATHS = [
    Path(r"C:\Users\ASUS\Downloads\ABDM\Compressed\Godot_v4.5-stable_mono_win64\Godot_v4.5-stable_mono_win64_console.exe"),
]

FORBIDDEN_NEEDLES = [
    b"godot_mcp",
    b"addons/godot_mcp",
]


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--godot",
        type=Path,
        default=None,
        help="Path to Godot console executable. Defaults to GODOT_EXECUTABLE or a known local path.",
    )
    return parser.parse_args()


def resolve_godot(explicit: Path | None) -> Path:
    candidates: list[Path] = []
    if explicit:
        candidates.append(explicit)
    if os.environ.get("GODOT_EXECUTABLE"):
        candidates.append(Path(os.environ["GODOT_EXECUTABLE"]))
    candidates.extend(KNOWN_GODOT_PATHS)

    for candidate in candidates:
        if candidate.exists() and candidate.is_file():
            return candidate

    raise FileNotFoundError("Godot executable not found. Pass --godot or set GODOT_EXECUTABLE.")


def assert_inside(path: Path, parent: Path) -> None:
    resolved = path.resolve()
    resolved_parent = parent.resolve()
    if resolved != resolved_parent and resolved_parent not in resolved.parents:
        raise RuntimeError(f"Refusing to operate outside {resolved_parent}: {resolved}")


def move_development_addons_out() -> list[tuple[Path, Path]]:
    TMP_ROOT.mkdir(exist_ok=True)
    moved: list[tuple[Path, Path]] = []

    for addon in DEVELOPMENT_ADDONS:
        assert_inside(addon, PROJECT)
        if not addon.exists():
            continue

        parked = TMP_ROOT / addon.relative_to(PROJECT)
        if parked.exists():
            raise RuntimeError(f"Temporary addon path already exists: {parked}")
        parked.parent.mkdir(parents=True, exist_ok=True)
        shutil.move(str(addon), str(parked))
        moved.append((addon, parked))

    return moved


def restore_development_addons(moved: list[tuple[Path, Path]]) -> None:
    for addon, parked in reversed(moved):
        if addon.exists():
            raise RuntimeError(f"Cannot restore addon because destination exists: {addon}")
        parked.parent.mkdir(parents=True, exist_ok=True)
        shutil.move(str(parked), str(addon))

    if TMP_ROOT.exists() and not any(path.is_file() for path in TMP_ROOT.rglob("*")):
        shutil.rmtree(TMP_ROOT)


def remove_stale_export(path: Path) -> None:
    assert_inside(path, PROJECT)
    if path.exists():
        path.unlink()


def scan_artifact(path: Path) -> None:
    overlap = max(len(needle) - 1 for needle in FORBIDDEN_NEEDLES)
    previous = b""
    with path.open("rb") as handle:
        while True:
            chunk = handle.read(1024 * 1024)
            if not chunk:
                return
            data = previous + chunk
            for needle in FORBIDDEN_NEEDLES:
                if needle in data:
                    raise RuntimeError(f"{path} contains forbidden development addon marker {needle!r}")
            previous = data[-overlap:]


def copy_artifact(source: Path, destination: Path) -> None:
    last_error: OSError | None = None
    for attempt in range(8):
        try:
            shutil.copy2(source, destination)
            return
        except OSError as exc:
            last_error = exc
            if attempt == 7:
                break
            time.sleep(0.75 * (attempt + 1))
    raise RuntimeError(f"Could not copy release artifact to {destination}: {last_error}") from last_error


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def export_builds(godot: Path) -> None:
    for preset, export_path, download_path in EXPORTS:
        export_path.parent.mkdir(parents=True, exist_ok=True)
        DOWNLOADS.mkdir(exist_ok=True)
        remove_stale_export(export_path)

        print(f"exporting {preset}: {export_path}")
        subprocess.run(
            [
                str(godot),
                "--headless",
                "--path",
                str(PROJECT),
                "--export-release",
                preset,
                str(export_path),
            ],
            cwd=PROJECT,
            check=True,
        )

        if not export_path.exists():
            raise RuntimeError(f"Export did not create artifact: {export_path}")

        scan_artifact(export_path)
        copy_artifact(export_path, download_path)
        scan_artifact(download_path)
        print(f"ready {download_path} size={download_path.stat().st_size} sha256={sha256(download_path)}")


def main() -> int:
    args = parse_args()
    godot = resolve_godot(args.godot)
    moved: list[tuple[Path, Path]] = []

    try:
        moved = move_development_addons_out()
        export_builds(godot)
    finally:
        restore_development_addons(moved)

    return 0


if __name__ == "__main__":
    sys.exit(main())
