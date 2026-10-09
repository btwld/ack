#!/usr/bin/env python3
"""Sequential, reproducible Dart/Node benchmark driver (Python 3.9+)."""

import argparse
from collections import defaultdict
from datetime import datetime, timezone
import fcntl
import hashlib
import json
import math
import os
from pathlib import Path
import platform
import random
import shutil
import signal
import statistics
import subprocess
import sys
import tarfile
import tempfile

from corpus import corpus, scaling_corpus

ROOT = Path(__file__).resolve().parent
REPO = ROOT.parent
DART_ENGINES = ["ack", "ack-json-schema", "acanthis", "validart", "json-schema"]
NODE_ENGINES = ["zod", "valibot", "ajv"]
EXCLUSIONS = {
    "acanthis": "2.0.0: constrained-string wrong-type input enters an "
    "unbounded recovery-value mock loop; see README.md. No timing claimed.",
}


def write_json(path, value):
    path.write_text(json.dumps(value, indent=2, allow_nan=False) + "\n")


def capture(command, cwd=REPO, timeout=120):
    return subprocess.run(
        command, cwd=cwd, check=True, text=True,
        stdout=subprocess.PIPE, stderr=subprocess.PIPE, timeout=timeout,
    ).stdout.strip()


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def source_digest():
    files = sorted([
        *ROOT.glob("*.py"), *ROOT.glob("dart/bin/*.dart"),
        *ROOT.glob("dart/lib/*.dart"), *ROOT.glob("node/*.mjs"),
        *REPO.glob("packages/ack/lib/**/*.dart"),
        ROOT / "dart/pubspec.yaml", ROOT / "node/package.json",
    ])
    combined = hashlib.sha256()
    for path in files:
        combined.update(str(path.relative_to(REPO)).encode() + b"\0")
        combined.update(path.read_bytes())
    return {"sha256": combined.hexdigest(), "fileCount": len(files)}


def ack_digest(root):
    paths = sorted([
        *root.glob("packages/ack/lib/**/*.dart"),
        root / "packages/ack/pubspec.yaml",
    ])
    combined = hashlib.sha256()
    for path in paths:
        combined.update(str(path.relative_to(root)).encode() + b"\0")
        combined.update(path.read_bytes())
    return combined.hexdigest()


def copy_ack_source(source, target):
    """Copy only ACK source, checking that the frozen input is complete/stable."""
    source = source.resolve()
    if not (source / "packages/ack/lib/ack.dart").is_file():
        raise ValueError("Baseline directory must contain packages/ack/lib/ack.dart")
    before = ack_digest(source)
    paths = [*source.glob("packages/ack/lib/**/*.dart"),
             source / "packages/ack/pubspec.yaml"]
    for path in paths:
        if path.is_symlink() or not path.resolve().is_relative_to(source):
            raise ValueError("Baseline source cannot contain external links")
        destination = target / path.relative_to(source)
        destination.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(path, destination)
    if before != ack_digest(source) or before != ack_digest(target):
        raise ValueError("Baseline source changed while copying")
    return before


def stage_baseline(ref, output, source=None):
    """Freeze ACK at a commit while keeping corpus, workers, and locks identical."""
    stage = output / "baseline-source"
    stage.mkdir()
    if source is not None:
        identity = copy_ack_source(source, stage)
        metadata = {"ref": None, "revision": f"source-sha256:{identity}",
                    "inputPath": str(source.resolve())}
    else:
        revision = capture([
            "git", "rev-parse", "--verify", "--end-of-options", f"{ref}^{{commit}}",
        ])
        archive = output / "baseline-source.tar"
        with archive.open("wb") as stream:
            subprocess.run([
                "git", "archive", "--format=tar", revision,
                "packages/ack/lib", "packages/ack/pubspec.yaml",
            ], cwd=REPO, check=True, stdout=stream)
        # Write only regular, repository-relative files, never archive symlinks.
        with tarfile.open(archive) as bundle:
            for member in bundle.getmembers():
                if member.isdir():
                    continue
                target = (stage / member.name).resolve()
                if not member.isfile() or not target.is_relative_to(stage):
                    raise ValueError(f"Unexpected baseline archive entry: {member.name}")
                target.parent.mkdir(parents=True, exist_ok=True)
                target.write_bytes(bundle.extractfile(member).read())
        metadata = {"ref": ref, "revision": revision,
                    "archiveSha256": digest(archive)}
    dart_dir = stage / "benchmarks/dart"
    shutil.copytree(ROOT / "dart", dart_dir,
                    ignore=shutil.ignore_patterns(".dart_tool", "build"))
    capture(["dart", "pub", "get", "--enforce-lockfile"], cwd=dart_dir)
    if digest(dart_dir / "pubspec.lock") != digest(ROOT / "dart/pubspec.lock"):
        raise ValueError("Baseline and current dependency locks differ")
    return {
        **metadata, "path": str(stage),
        "ackSourceSha256": ack_digest(stage),
        "lockSha256": digest(dart_dir / "pubspec.lock"),
    }


def lane_groups(lanes):
    """Pair each ACK baseline/current lane; competitors stay standalone."""
    groups = []
    for runtime, engine in lanes:
        if engine.endswith("-baseline"):
            continue
        baseline = (runtime, f"{engine}-baseline")
        group = [baseline, (runtime, engine)] if baseline in lanes else [(runtime, engine)]
        groups.append(group)
    return groups


def paired_comparisons(runs):
    """Use per-fork ratios, not a ratio of independently pooled medians."""
    cells = {}
    for run in runs:
        for row in run["results"]:
            key = (run["runtimeMode"], run["engine"], row["name"], run["fork"])
            if key in cells:
                raise ValueError("Duplicate process/case in comparison")
            cells[key] = statistics.median(
                s["elapsedNs"] / s["iterations"] for s in row["samples"])
    grouped = defaultdict(list)
    for (runtime, engine, name, fork), before in cells.items():
        if not engine.endswith("-baseline"):
            continue
        current = engine.removesuffix("-baseline")
        key = (runtime, current, name, fork)
        if key not in cells:
            raise ValueError("Baseline measurement has no paired current process")
        after = cells[key]
        grouped[runtime, current, name].append({
            "fork": fork, "baselineNs": before, "currentNs": after,
            "speedup": before / after,
        })
    return [{
        "runtime": runtime, "engine": engine, "name": name,
        "baselineMedianNs": statistics.median(p["baselineNs"] for p in pairs),
        "currentMedianNs": statistics.median(p["currentNs"] for p in pairs),
        "medianPairedSpeedup": statistics.median(p["speedup"] for p in pairs),
        "minPairedSpeedup": min(p["speedup"] for p in pairs),
        "maxPairedSpeedup": max(p["speedup"] for p in pairs),
        "fasterPairs": sum(p["speedup"] > 1 for p in pairs),
        "pairs": sorted(pairs, key=lambda p: p["fork"]),
    } for (runtime, engine, name), pairs in sorted(grouped.items())]


def comparison_report(document):
    lines = [
        "# Paired ACK revision comparison", "",
        f"Baseline: `{document['baseline']['revision']}`.",
        f"Current: `{document['revision']}`.", "",
        f"Baseline ACK source: `{document['baseline']['ackSourceSha256']}`.",
        f"Current ACK source: `{document['ackSourceSha256']}` (includes uncommitted changes).", "",
        "Both revisions ran fresh in this session with identical workers,",
        "corpus, dependency locks, and case order within each pair. Processes",
        "ran sequentially; baseline/current order alternated across forks.",
        "These are not ratios against a historical run.", "",
        "Times are **microseconds per whole payload**. Speedup is the median",
        "of per-fork baseline/current ratios: >1 means current was faster.",
        "The range is the observed pair range, not a confidence interval.",
        "A consistent direction across a few noisy forks is not proof of",
        "statistical significance. No outliers were removed.", "",
        f"CPU: {document['machine']['cpu']}; "
        f"logical CPUs: {document['machine']['logicalCpus']}.",
        f"Load before: {document['machine']['loadBefore']}; "
        f"after: {document['machine']['loadAfter']}.", "",
        "See [results.json](results.json) for raw paired samples and",
        "[report.md](report.md) for the full package comparison and noise flags.",
    ]
    for runtime in sorted({r["runtime"] for r in document["comparison"]}):
        for engine in ["ack", "ack-json-schema"]:
            rows = {r["name"]: r for r in document["comparison"]
                    if r["runtime"] == runtime and r["engine"] == engine}
            if not rows:
                continue
            lines += ["", f"## {runtime} / {engine}", "",
                      "| Workload | Before µs | After µs | Paired speedup | Pair range | Faster pairs |",
                      "|---|---:|---:|---:|---|---:|"]
            for name in document["caseNames"]:
                r = rows[name]
                lines.append(
                    f"| {name} | {r['baselineMedianNs'] / 1000:.3f} | "
                    f"{r['currentMedianNs'] / 1000:.3f} | "
                    f"{r['medianPairedSpeedup']:.2f}× | "
                    f"{r['minPairedSpeedup']:.2f}–{r['maxPairedSpeedup']:.2f}× | "
                    f"{r['fasterPairs']}/{len(r['pairs'])} |")
    return "\n".join(lines) + "\n"


def validate_worker(result, expected_cases, samples):
    if result["checks"] <= 0:
        raise ValueError("Worker did not run correctness checks")
    rows = result["results"]
    if (len(rows) != len(expected_cases)
            or {row["name"] for row in rows} != set(expected_cases)):
        raise ValueError("Worker returned missing, duplicate, or unexpected cases")
    for row in rows:
        if len(row["samples"]) != samples or row["checksum"] <= 0:
            raise ValueError("Missing samples or unconsumed benchmark output")
        for sample in row["samples"]:
            if (not isinstance(sample["iterations"], int)
                    or sample["iterations"] <= 0
                    or not math.isfinite(sample["elapsedNs"])
                    or sample["elapsedNs"] <= 0):
                raise ValueError("Invalid timing sample")


def summarize(runs):
    grouped = defaultdict(list)
    for run in runs:
        for row in run["results"]:
            key = (run["runtimeMode"], run["engine"], row["name"], row["phase"])
            per_op = [s["elapsedNs"] / s["iterations"] for s in row["samples"]]
            grouped[key].append(statistics.median(per_op))
    summary = []
    for (runtime, engine, name, phase), medians in sorted(grouped.items()):
        median = statistics.median(medians)
        summary.append({
            "runtime": runtime, "engine": engine, "name": name, "phase": phase,
            "medianNs": median, "opsPerSecond": 1e9 / median,
            "forkMediansNs": medians,
            "forkRangePercent": 100 * (max(medians) - min(medians)) / median,
        })
    return summary


def report(document):
    settings = document["settings"]
    machine = document["machine"]
    noisy = [r for r in document["summary"] if r["forkRangePercent"] > 20]
    lines = [
        "# ACK local benchmark report", "",
        f"**Exploratory measurements:** {len(noisy)}/{len(document['summary'])} "
        "cells exceed the 20% process-spread flag. No universal ranking is claimed.", "",
        f"Created: {document['createdUtc']}", "",
        f"Revision: `{document['revision']}` (dirty: {bool(document['gitStatus'])}).",
        f"CPU: {machine['cpu']}; OS: {machine['os']}; arch: {machine['arch']}.", "",
        f"Load before: {machine['loadBefore']}; after: {machine['loadAfter']}; "
        f"logical CPUs: {machine['logicalCpus']}.", "",
        f"{settings['forks']} process forks, {settings['samples']} samples/case, "
        f"{settings['warmupMs']} ms warmup target, "
        f"{settings['sampleMs']} ms sample target.", "",
        f"Corpus suite: `{settings.get('suite', 'common')}`.", "",
        "Times below are **microseconds per whole payload**, lower is better.",
        "Each cell is the median of independent process medians. These are",
        "batch-average costs, NOT individual-request p50/p95/p99 latencies.", "",
        "All configured adapters passed the common acceptance/rejection, output",
        "equality, and input-mutation checks before measurement. Timed loops",
        "also verify the expected success/failure checksum.", "",
        "Parser APIs (ACK, Acanthis, Validart, Zod, Valibot) return data and",
        "errors. json_schema and Ajv validate without building parsed output.",
        "Error representation and collection details differ. Do not infer a",
        "universal ranking or Flutter/mobile/browser performance from these",
        "desktop measurements. No confidence interval is claimed.", "",
        "`construct+validate` includes schema translation, construction, and",
        "one validation; Ajv includes a new engine and uncached compilation.",
        "It is a repeated warm construction workload, not cold process startup.", "",
        "Raw data, order, checksums, source/lock hashes, and metadata are in",
        "[results.json](results.json); exact fixtures are in [corpus.json](corpus.json).",
    ]
    if document["exclusions"]:
        lines += ["", "## Exclusions", ""]
        lines += [f"- **{engine}:** {reason}"
                  for engine, reason in document["exclusions"].items()]
    if settings.get("suite") == "scaling":
        lines += ["", "## Payload sizes", "",
                  "Compact UTF-8 JSON bytes describe transport size, not heap size.",
                  "All sizes use the same schema within this run. Invalid workloads",
                  "have different error traversal contracts across engines; they are",
                  "diagnostic cases, not equivalent all-errors rankings.", "",
                  "| Workload | Items/payload | Varying inputs | Bytes (min–max) |",
                  "|---|---:|---:|---:|"]
        for case in document["caseMetadata"]:
            sizes = case["payloadBytesUtf8"]
            lines.append(f"| {case['name']} | {case['itemsPerPayload']} | "
                         f"{case['inputCount']} | {min(sizes)}–{max(sizes)} |")
    for runtime in sorted({r["runtime"] for r in document["summary"]}):
        rows = [r for r in document["summary"] if r["runtime"] == runtime]
        engines = [e for engine in DART_ENGINES + NODE_ENGINES
                   for e in [f"{engine}-baseline", engine]
                   if any(r["engine"] == e for r in rows)]
        lines += ["", f"## {runtime}", ""]
        lines += ["| Workload | " + " | ".join(engines) + " |",
                  "|---|" + "---:|" * len(engines)]
        by_key = {(r["name"], r["engine"]): r for r in rows}
        for name in document["caseNames"]:
            values = [f"{by_key[name, e]['medianNs'] / 1000:.3f}" for e in engines]
            lines.append(f"| {name} | " + " | ".join(values) + " |")
    lines += ["", "## Variability", "",
              f"{len(noisy)} of {len(document['summary'])} cells have a "
              "process-median range greater than 20% of their median.",
              "This is a descriptive noise flag, not a significance test.",
              "Use more forks on an idle, controlled machine before making",
              "release gates or public performance claims.", ""]
    if noisy:
        lines += ["| Runtime | Engine | Workload | Fork range / median |",
                  "|---|---|---|---:|"]
        lines += [
            f"| {r['runtime']} | {r['engine']} | {r['name']} | "
            f"{r['forkRangePercent']:.1f}% |" for r in noisy
        ]
    return "\n".join(lines) + "\n"


def positive(value):
    number = int(value)
    if number < 1:
        raise argparse.ArgumentTypeError("Must be a positive integer")
    return number


def scaling_sizes(value):
    try:
        sizes = [int(part) for part in value.split(",")]
    except ValueError as error:
        raise argparse.ArgumentTypeError("Sizes must be comma-separated integers") from error
    if (not sizes or min(sizes) < 1 or max(sizes) > 100_000
            or len(sizes) != len(set(sizes))):
        raise argparse.ArgumentTypeError("Use distinct sizes between 1 and 100000")
    return sorted(sizes)


def timed_case_names(payload, selected=None):
    names = [case["name"] for case in payload["cases"] if case["timed"]]
    if selected is None:
        return names
    requested = selected.split(",")
    if len(requested) != len(set(requested)) or not set(requested) <= set(names):
        raise ValueError("--cases must name distinct timed workloads in the selected suite")
    return [name for name in names if name in requested]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true", help="Correctness only")
    parser.add_argument("--quick", action="store_true", help="Smoke timing, not a baseline")
    parser.add_argument("--forks", type=positive, default=3)
    parser.add_argument("--samples", type=positive, default=7)
    parser.add_argument("--sample-ms", type=positive, default=50)
    parser.add_argument("--warmup-ms", type=positive, default=100)
    parser.add_argument("--worker-timeout", type=positive, default=120,
                        help="Seconds per worker; timeout fails without retry")
    parser.add_argument("--seed", type=int, default=20261008)
    baseline = parser.add_mutually_exclusive_group()
    baseline.add_argument("--baseline-ref", help="Pair current ACK with this git revision")
    baseline.add_argument("--baseline-source", type=Path,
                          help="Pair with frozen packages/ack source under this directory")
    parser.add_argument("--suite", choices=["common", "scaling"], default="common")
    parser.add_argument("--sizes", type=scaling_sizes,
                        help="Item counts for the separate scaling suite")
    parser.add_argument("--cases", help="Comma-separated timed workloads; all correctness vectors still run")
    parser.add_argument("--runtimes", default="dart-jit,node",
                        help="dart-jit,node; AOT measurements are discontinued")
    parser.add_argument("--engines", default=",".join(
        e for e in DART_ENGINES + NODE_ENGINES if e not in EXCLUSIONS))
    parser.add_argument("--output", type=Path)
    args = parser.parse_args()
    if args.suite != "scaling" and args.sizes is not None:
        parser.error("--sizes requires --suite scaling")
    args.sizes = args.sizes or [1, 10, 100, 1000, 10000]
    if args.quick:
        args.forks, args.samples, args.sample_ms, args.warmup_ms = 1, 3, 10, 40
    runtimes = args.runtimes.split(",")
    engines = args.engines.split(",")
    if not set(runtimes) <= {"dart-jit", "node"}:
        parser.error("Supported runtimes are dart-jit,node; AOT is discontinued")
    if not set(engines) <= set(DART_ENGINES + NODE_ENGINES):
        parser.error("Unknown engine")
    if len(set(runtimes)) != len(runtimes) or len(set(engines)) != len(engines):
        parser.error("Duplicate runtimes or engines")
    lanes = [(runtime, engine) for runtime in runtimes for engine in engines
             if engine in (NODE_ENGINES if runtime == "node" else DART_ENGINES)]
    if not lanes:
        parser.error("No compatible runtime/engine pairs selected")
    if args.baseline_ref or args.baseline_source:
        baseline_lanes = [(runtime, f"{engine}-baseline")
                          for runtime, engine in lanes
                          if engine in {"ack", "ack-json-schema"}]
        if not baseline_lanes:
            parser.error("A baseline comparison requires an ACK Dart lane")
        lanes += baseline_lanes

    # One benchmark at a time across all worktrees on this machine.
    with open(Path(tempfile.gettempdir()) / "ack-comparison-benchmark.lock", "w") as lock:
        try:
            fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
        except BlockingIOError:
            parser.error("Another ACK comparison benchmark is already running")
        run(args, lanes)


def run(args, lanes):
    stamp = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%S.%fZ")
    output = (args.output or ROOT / "results" / stamp).resolve()
    payload = scaling_corpus(args.sizes) if args.suite == "scaling" else corpus()
    names = timed_case_names(payload, args.cases)
    output.mkdir(parents=True, exist_ok=False)
    # Compact on disk to avoid spending most artifact size on indentation.
    fixtures = output / "corpus.json"
    fixtures.write_text(json.dumps(payload, separators=(",", ":")) + "\n")
    cpu = (capture(["sysctl", "-n", "machdep.cpu.brand_string"])
           if sys.platform == "darwin" else platform.processor() or "unknown")
    document = {
        "schemaVersion": 1, "status": "running", "createdUtc": stamp,
        "revision": capture(["git", "rev-parse", "HEAD"]),
        "gitStatus": capture(["git", "status", "--short"]),
        "source": source_digest(), "corpusSha256": digest(fixtures),
        "ackSourceSha256": ack_digest(REPO),
        "machine": {
            "cpu": cpu, "os": platform.platform(), "arch": platform.machine(),
            "logicalCpus": os.cpu_count(), "loadBefore": os.getloadavg(),
        },
        "settings": {
            "suite": args.suite,
            "sizes": args.sizes if args.suite == "scaling" else None,
            "forks": args.forks, "samples": args.samples,
            "sampleMs": args.sample_ms, "warmupMs": args.warmup_ms,
            "seed": args.seed, "quick": args.quick, "checkOnly": args.check,
            "workerTimeoutSeconds": args.worker_timeout,
        },
        "caseNames": names,
        "caseMetadata": [{
            "name": case["name"], "phase": case["phase"],
            "inputCount": len(case["inputs"]),
            "itemsPerPayload": case.get("itemsPerPayload"),
            "payloadBytesUtf8": [len(json.dumps(entry["value"],
                separators=(",", ":"), ensure_ascii=False).encode("utf-8"))
                for entry in case["inputs"]],
        } for case in payload["cases"] if case["name"] in names],
        "commands": [], "runs": [], "preflight": [],
        "pythonVersion": platform.python_version(), "lockHashes": {},
        "exclusions": {e: reason for e, reason in EXCLUSIONS.items()
                       if not any(engine == e for _, engine in lanes)},
    }
    write_json(output / "results.json", document)
    try:
        if args.baseline_ref or args.baseline_source:
            print("Staging the baseline ACK source and identical workers...", flush=True)
            document["baseline"] = stage_baseline(args.baseline_ref, output,
                                                  args.baseline_source)
        dart_selected = any(runtime.startswith("dart") for runtime, _ in lanes)
        if dart_selected:
            document["dartVersion"] = capture(["dart", "--version"])
            document["dartDependencies"] = json.loads(capture(
                ["dart", "pub", "deps", "--json"], cwd=ROOT / "dart"))
        if any(runtime == "node" for runtime, _ in lanes):
            document["nodeVersion"] = capture(["node", "--version"])
        for source, name in [
            (ROOT / "dart/pubspec.lock", "dart-pubspec.lock"),
            (ROOT / "node/package-lock.json", "node-package-lock.json"),
        ]:
            if source.exists():
                shutil.copy2(source, output / name)
                document["lockHashes"][name] = digest(source)
        baseline_dir = None
        if "baseline" in document:
            baseline_dir = Path(document["baseline"]["path"]) / "benchmarks/dart"

        def execute(runtime, engine, fork, check_only, case_order):
            is_baseline = engine.endswith("-baseline")
            worker_engine = engine.removesuffix("-baseline")
            job = {
                "engine": worker_engine, "checkOnly": check_only,
                "cases": case_order, **document["settings"],
            }
            job["checkOnly"] = check_only
            prefix = f"{runtime}-{engine}-{'check' if check_only else fork}"
            job_path = output / f"{prefix}.job.json"
            write_json(job_path, job)
            command = {
                "dart-jit": ["dart", "run", "bin/worker.dart"],
                "node": ["node", str(ROOT / "node/worker.mjs")],
            }[runtime] + [str(fixtures), str(job_path)]
            document["commands"].append(command)
            print(f"{'Check' if check_only else 'Fork ' + str(fork + 1)}: "
                  f"{runtime} / {engine}", flush=True)
            # No retry: interruptions are preserved and require a new explicit run.
            raw = capture(
                command,
                cwd=(baseline_dir if is_baseline else ROOT / "dart")
                if runtime != "node" else ROOT / "node",
                timeout=args.worker_timeout,
            )
            result = json.loads(raw)
            if result["engine"] != worker_engine:
                raise ValueError("Worker returned the wrong engine")
            if result["checks"] != 2 * sum(len(c["inputs"]) for c in payload["cases"]):
                raise ValueError("Worker did not check the complete corpus")
            validate_worker(result, [] if check_only else names, args.samples)
            result.update(runtimeMode=runtime, fork=fork, caseOrder=case_order,
                          engine=engine, variant="baseline" if is_baseline else "current")
            return result

        rng = random.Random(args.seed)
        # Validate every selected lane before accepting any timing results.
        for runtime, engine in lanes:
            document["preflight"].append(execute(runtime, engine, 0, True, names))
        if not args.check:
            for fork in range(args.forks):
                order = lane_groups(lanes)
                rng.shuffle(order)
                for group in order:
                    case_order = names.copy()
                    rng.shuffle(case_order)
                    # Balanced AB/BA with an even fork count; identical case order.
                    if fork % 2:
                        group = list(reversed(group))
                    for runtime, engine in group:
                        document["runs"].append(
                            execute(runtime, engine, fork, False, case_order))
                        write_json(output / "results.json", document)
        document["sourceAfter"] = source_digest()
        if document["sourceAfter"] != document["source"]:
            raise ValueError("Source changed during the run; timings are not a baseline")
        for name, source in [
            ("dart-pubspec.lock", ROOT / "dart/pubspec.lock"),
            ("node-package-lock.json", ROOT / "node/package-lock.json"),
        ]:
            if name in document["lockHashes"] and digest(source) != document["lockHashes"][name]:
                raise ValueError("Dependency lock changed during the run")
        document["summary"] = summarize(document["runs"])
        if "baseline" in document:
            baseline = document["baseline"]
            if ack_digest(Path(baseline["path"])) != baseline["ackSourceSha256"]:
                raise ValueError("Baseline source changed during measurement")
            document["comparison"] = paired_comparisons(document["runs"])
        document["machine"]["loadAfter"] = os.getloadavg()
        document["status"] = "complete"
        write_json(output / "results.json", document)
        if not args.check:
            (output / "report.md").write_text(report(document))
            if "baseline" in document:
                (output / "comparison.md").write_text(comparison_report(document))
        print(f"Complete: {output}", flush=True)
    except BaseException as error:
        document["status"] = "interrupted" if isinstance(error, KeyboardInterrupt) else "failed"
        document["error"] = str(error)
        if isinstance(error, subprocess.CalledProcessError):
            document["error"] += "\n" + (error.stderr or "")
        write_json(output / "results.json", document)
        print(f"Incomplete run retained at {output}; no automatic restart.", file=sys.stderr)
        raise


if __name__ == "__main__":
    def interrupted(_signal, _frame):
        raise KeyboardInterrupt("Benchmark terminated by signal; no retry")

    signal.signal(signal.SIGTERM, interrupted)
    main()
