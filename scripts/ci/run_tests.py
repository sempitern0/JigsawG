#!/usr/bin/env python3
"""Run the fast Godot regression suite; reject silent parser/test failures."""
from __future__ import annotations

import argparse
import os
from pathlib import Path
import re
import subprocess
import sys
import time

ROOT = Path(__file__).resolve().parents[2]
ERRORS = re.compile(r"(?:SCRIPT ERROR:|Parse Error:|Failed to load script|^ERROR:)", re.MULTILINE)
SUCCESS = re.compile(r"\b(?:PASS|passed)\b", re.IGNORECASE)


def execute(command: list[str], timeout: int, expect_pass: bool = False) -> bool:
    print("$ " + " ".join(command), flush=True)
    start = time.perf_counter()
    try:
        process = subprocess.run(
            command, cwd=ROOT, capture_output=True, text=True,
            errors="replace", timeout=timeout, check=False,
        )
    except FileNotFoundError:
        print("FAIL: Godot executable missing; pass --godot /path/to/godot.", file=sys.stderr)
        return False
    except subprocess.TimeoutExpired:
        print(f"FAIL: command exceeded {timeout}s", file=sys.stderr)
        return False
    output = process.stdout + "\n" + process.stderr
    print(output.rstrip(), flush=True)
    valid = process.returncode == 0 and not ERRORS.search(output)
    if expect_pass:
        valid = valid and bool(SUCCESS.search(output))
    print(f"{'PASS' if valid else 'FAIL'} | {time.perf_counter() - start:.2f}s", flush=True)
    return valid


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--godot", default=os.environ.get("GODOT_BIN", "godot"))
    parser.add_argument("--timeout", type=int, default=120)
    parser.add_argument("--skip-import", action="store_true")
    parser.add_argument("--test", action="append", default=[], help="Repeat test filename or stem")
    parser.add_argument("--list", action="store_true")
    args = parser.parse_args()
    available = sorted((ROOT / "tests").glob("test_*.gd"))
    if args.list:
        for test in available:
            print(test.name)
        return 0
    selected = available
    if args.test:
        selected = [test for test in available if test.name in args.test or test.stem in args.test]
        if len(selected) != len(set(args.test)):
            print("Unknown or duplicate --test name; use --list.", file=sys.stderr)
            return 2
    if not selected:
        print("No tests to execute.", file=sys.stderr)
        return 2
    if not args.skip_import and not execute(
        [args.godot, "--headless", "--path", str(ROOT), "--editor", "--quit"], args.timeout
    ):
        print("FAIL: import/parse; subsequent tests skipped.", file=sys.stderr)
        return 1
    failures = []
    for test in selected:
        command = [args.godot, "--headless", "--path", str(ROOT), "--script", f"res://tests/{test.name}"]
        if not execute(command, args.timeout, expect_pass=True):
            failures.append(test.name)
    print(f"RESULT: {len(selected) - len(failures)}/{len(selected)} passed")
    if failures:
        print("Failed: " + ", ".join(failures), file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
