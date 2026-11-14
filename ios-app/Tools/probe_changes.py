#!/usr/bin/env python3
"""List every car field whose value changes during a probe recording (#92).

Usage: python3 ios-app/Tools/probe_changes.py LOG [LOG ...]. Each LOG is an
exported zip, a recording folder, a folder holding recordings, or a
probe.jsonl file; the probe writes probe.jsonl into the recording while
行車紀錄(測試) records with 探測其他資料 on. For each log it lists every field
path, known by name or unknown by number (with its wire type), whose value
changes between two replies of its group, fewest changes first. Each change is
shown as the window it happened in: from that group's previous reply to this
one (seconds since the recording started, and phone time), with the car's
speed (drive_state speed_float, as sent) and gear at both ends; the probe-only
groups are asked 30 s apart, so their windows are wide. A path with more than
--max-changes changes shows its count and only its first and last few changes.
Groups the car refused or did not answer are listed first; lines that are not
valid JSON (a recording cut off mid-line) are skipped and counted. With two or
more logs it ends with the paths that changed in every log (the pass line asks
for a second run). Standard library only.
"""

import argparse
import bisect
import json
import pathlib
import sys
import zipfile

GEARS = ("P", "R", "N", "D", "Invalid", "SNA")
# Changes shown at each end of a path with more than --max-changes.
EDGE = 3


def tokens(text):
    """Protobuf text format, as SwiftProtobuf writes it, as tokens."""
    i, n = 0, len(text)
    while i < n:
        c = text[i]
        if c.isspace():
            i += 1
        elif c in "{}:":
            yield c
            i += 1
        elif c == '"':
            j = i + 1
            while j < n and text[j] != '"':
                j += 2 if text[j] == "\\" else 1
            yield text[i:j + 1]
            i = j + 1
        else:
            j = i
            while j < n and not text[j].isspace() and text[j] not in "{}:":
                j += 1
            yield text[i:j]
            i = j


def parse(stream):
    """One message's fields, in order: (name, value) with value a string or a list of fields."""
    fields = []
    for name in stream:
        if name == "}":
            return fields
        after = next(stream)
        if after == ":":
            fields.append((name, next(stream)))
        elif after == "{":
            fields.append((name, parse(stream)))
        else:
            raise ValueError(f"unexpected {after!r} after {name!r}")
    return fields


def wire_type(value):
    if isinstance(value, list):
        return "length-delimited, empty message"
    if value.startswith('"'):
        return "length-delimited"
    if value.startswith("0x"):
        return "fixed32" if len(value) == 10 else "fixed64"
    return "varint"


def flatten(fields, prefix, out):
    """Path -> value; a repeated field gets [index]; an empty message is "{}"; an unknown field is #number."""
    counts = {}
    for name, _ in fields:
        counts[name] = counts.get(name, 0) + 1
    seen = {}
    for name, value in fields:
        index = seen.get(name, 0)
        seen[name] = index + 1
        label = f"#{name}" if name.isdigit() else name
        if counts[name] > 1:
            label += f"[{index}]"
        path = f"{prefix}.{label}" if prefix else label
        if isinstance(value, list) and value:
            # An unknown #number with fields under it is a length-delimited message.
            flatten(value, path, out)
        else:
            if name.isdigit():
                path += f" (unknown, {wire_type(value)})"
            out[path] = "{}" if isinstance(value, list) else value
    return out


def read_lines(arg):
    """(name, lines) for every probe.jsonl the argument holds."""
    path = pathlib.Path(arg)
    if path.is_file() and zipfile.is_zipfile(path):
        with zipfile.ZipFile(path) as archive:
            for name in sorted(archive.namelist()):
                if name.endswith("probe.jsonl"):
                    yield f"{path.name}:{name}", archive.read(name).decode("utf-8").splitlines()
    elif path.is_dir():
        for found in sorted(path.rglob("probe.jsonl")):
            yield str(found), found.read_text(encoding="utf-8").splitlines()
    elif path.is_file():
        yield str(path), path.read_text(encoding="utf-8").splitlines()
    else:
        sys.exit(f"not found: {arg}")


def analyse(name, lines, max_changes):
    replies, skipped = [], 0
    for line in lines:
        if not line.strip():
            continue
        try:
            reply = json.loads(line)
            if not isinstance(reply.get("monotonic_ms"), int) or "group" not in reply:
                raise ValueError("not a probe reply")
            if "text" in reply:
                reply["fields"] = flatten(parse(iter(tokens(reply["text"]))), "", {})
        except (ValueError, StopIteration):
            skipped += 1
            continue
        replies.append(reply)
    replies.sort(key=lambda r: r["monotonic_ms"])
    print(f"== {name}")
    if skipped:
        print(f"   warning: skipped {skipped} line(s) that could not be read")
    if not replies:
        print("   no probe replies")
        return set()
    span = (replies[-1]["monotonic_ms"] - replies[0]["monotonic_ms"]) / 1000
    print(f"   {len(replies)} replies over {span:.1f} s, from {replies[0]['phone_time']}")

    for reply in replies:
        if not reply.get("answered"):
            why = reply.get("error") or "refused (action status not OK)"
            print(f"   not answered: {reply['group']} at {reply['monotonic_ms'] / 1000:.1f} s: {why}"
                  + (", not asked again" if reply.get("retired") else ""))

    # Speed and gear over time, from the drive replies.
    timeline, speeds, gears = [], [], []
    last = {}
    changes = {}
    for reply in replies:
        if "fields" not in reply:
            continue
        group = reply["group"]
        fields = reply["fields"]
        if group == "drive":
            drive = "vehicleData.drive_state"
            speed = fields.get(f"{drive}.speed_float", fields.get(f"{drive}.speed", "?"))
            gear = next((g for g in GEARS if f"{drive}.shift_state.{g}" in fields), "?")
            timeline.append(reply["monotonic_ms"])
            speeds.append(speed)
            gears.append(gear)
        before = last.get(group)
        last[group] = (fields, reply)
        if before is None:
            continue
        old_fields, previous = before
        for path in sorted(set(old_fields) | set(fields)):
            old, new = old_fields.get(path, "(absent)"), fields.get(path, "(absent)")
            if old != new:
                changes.setdefault(f"{group}: {path}", []).append((previous, reply, old, new))

    def car_at(ms):
        """Speed and gear from the last drive reply at or before `ms`."""
        i = bisect.bisect_right(timeline, ms) - 1
        return f"speed {speeds[i]} gear {gears[i]}" if i >= 0 else "no drive reply yet"

    start = replies[0]["monotonic_ms"]

    def show(change):
        previous, reply, old, new = change
        a, b = previous["monotonic_ms"], reply["monotonic_ms"]
        print(f"      +{(a - start) / 1000:.1f} .. +{(b - start) / 1000:.1f} s  "
              f"{previous['phone_time'][11:23]} .. {reply['phone_time'][11:23]}  {old} -> {new}   "
              f"(start: {car_at(a)}; end: {car_at(b)})")

    if not changes:
        print("   no field changed")
    quiet = sorted((p for p in changes if len(changes[p]) <= max_changes), key=lambda p: (len(changes[p]), p))
    noisy = sorted((p for p in changes if len(changes[p]) > max_changes), key=lambda p: (len(changes[p]), p))
    for path in quiet:
        print(f"   {path}: {len(changes[path])} change(s)")
        for change in changes[path]:
            show(change)
    if noisy:
        print(f"   more than {max_changes} changes (first and last {EDGE} shown):")
        for path in noisy:
            print(f"   {path}: {len(changes[path])} changes")
            listed = changes[path]
            for change in listed[:EDGE]:
                show(change)
            if len(listed) > 2 * EDGE:
                print(f"      … {len(listed) - 2 * EDGE} more")
            for change in listed[max(EDGE, len(listed) - EDGE):]:
                show(change)
    print()
    return set(changes)


def main():
    parser = argparse.ArgumentParser(description=(__doc__ or "").split("\n\n")[0])
    parser.add_argument("logs", nargs="+", help="exported zip, recording folder, or probe.jsonl")
    parser.add_argument("--max-changes", type=int, default=40, help="list the times of paths with at most this many changes (default 40)")
    args = parser.parse_args()
    changed = []
    for arg in args.logs:
        for name, lines in read_lines(arg):
            changed.append(analyse(name, lines, args.max_changes))
    if len(changed) >= 2:
        common = set.intersection(*changed)
        print(f"== changed in every log ({len(changed)} logs)")
        for path in sorted(common):
            print(f"   {path}")
        if not common:
            print("   none")


if __name__ == "__main__":
    main()
