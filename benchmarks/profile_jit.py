#!/usr/bin/env python3
"""JIT-only CPU/heap-state diagnostics, separate from throughput measurements.

The Dart 3.13.4 VM's allocation-profile accumulated fields are heap-census
aliases. This tool deliberately does NOT derive allocation bytes/operation.
"""

import argparse
from collections import Counter
from datetime import datetime, timezone
import fcntl
import json
from pathlib import Path
import queue
import signal
import subprocess
import tempfile
import threading
import time
from urllib.parse import urlencode, urlparse
from urllib.request import urlopen

from run import ROOT, capture, digest, positive, source_digest, write_json


def rpc(uri, method, **params):
    """The VM service supports HTTP GET for non-streaming protocol requests."""
    address = uri.rstrip("/") + "/" + method
    if params:
        address += "?" + urlencode(params)
    with urlopen(address, timeout=60) as response:
        document = json.load(response)
    if "error" in document:
        raise RuntimeError(f"VM service {method}: {document['error']}")
    return document["result"]


def select_cpu_window(samples, start, end):
    """Verify timestamps rather than trusting VM aggregate window filtering.

    Some service replies include samples immediately outside the requested
    interval. Keep the raw reply, filter by the worker's exact operation window,
    and count leaf-most reported frames and stack presence. The VM hides stubs
    from serialized stacks: these derived counts are NOT native/PC self ticks.
    """
    selected = [row for row in samples.get("samples", [])
                if start <= row["timestamp"] < end]
    functions = [{**{key: value for key, value in row.items()
                     if key not in {"exclusiveTicks", "inclusiveTicks"}},
                  "leafFrameSamples": 0, "stackPresenceSamples": 0}
                 for row in samples.get("functions", [])]
    for sample in selected:
        stack = sample.get("stack", [])
        if any(not isinstance(index, int) or not 0 <= index < len(functions)
               for index in stack):
            raise ValueError("CPU sample has an invalid function index")
        if stack:
            functions[stack[0]]["leafFrameSamples"] += 1
        for index in set(stack):
            functions[index]["stackPresenceSamples"] += 1
    # Service-level counters are not attributable to the selected interval.
    return {**{key: value for key, value in samples.items() if key != "_counters"},
            "samples": selected, "functions": functions,
            "sampleCount": len(selected), "timeOriginMicros": start,
            "timeExtentMicros": end - start,
            "unfilteredSampleCount": len(samples.get("samples", [])),
            "selection": "start <= timestamp < end; reported frames, NOT PC self ticks"}


def profile_summary(document, samples, raw_samples=None):
    rows = sorted(samples.get("functions", []),
                  key=lambda row: row.get("leafFrameSamples", 0), reverse=True)
    count = samples.get("sampleCount", len(samples.get("samples", [])))
    lines = ["# Dart JIT diagnostic profile", "",
             f"Engine: `{document['settings']['engine']}`; "
             f"case: `{document['settings']['case']}`; "
             f"mode: `{document['settings']['mode']}`.", "",
             f"Operations: {document['settings']['operations']}; CPU samples: {count}.", "",
             "This instrumented run is not a throughput comparison. The table",
             "counts leaf-most reported function frames and reported-stack presence,",
             "NOT native/PC self time. The VM omits stub/invisible frames from",
             "serialized stacks. Counts are timestamp-filtered to the worker's",
             "operation window. Stack presence overlaps across callers.",
             "Raw VM aggregate ticks remain available separately below/in JSON.",
             "Small samples and truncated stacks",
             "limit interpretation. JSON decoding/copying modes are diagnostic",
             "baselines, not validation APIs.", "",
             "`heap-before.json` and `heap-after.json` contain live-heap state.",
             "They are NOT cumulative allocation measurements or retained-output",
             "sizes. No allocation-bytes/op claim is made and no GC was forced.", "",
             "| Function | Leaf reported frame | Stack presence | Location |",
             "|---|---:|---:|---|"]
    for row in rows[:30]:
        function = row.get("function", {})
        name = function.get("name", "unknown").replace("|", "\\|")
        location = str(row.get("resolvedUrl", "")).replace("|", "\\|")
        lines.append(f"| {name} | {row.get('leafFrameSamples', 0)} | "
                     f"{row.get('stackPresenceSamples', 0)} | {location} |")
    lines += ["", "## Timestamp-filtered VM and native-entry tags", "",
              "Tags are reported separately from exported function frames.",
              "These views overlap; do not add tag counts to frame counts.", "",
              "| Tag field | Value | Selected samples |", "|---|---|---:|"]
    for key in ["vmTag", "nativeEntryTag"]:
        tags = Counter(sample[key] for sample in samples.get("samples", [])
                       if key in sample)
        for tag, tagged_count in tags.most_common():
            tag = str(tag).replace("|", "\\|")
            lines.append(f"| {key} | {tag} | {tagged_count} |")
    if raw_samples is not None:
        lines += ["", "## Unfiltered VM-attributed self ticks", "",
                  f"The original response contains {len(raw_samples.get('samples', []))} "
                  "samples, including any outside the requested window. These",
                  "VM-attributed ticks can include stubs hidden from reported",
                  "stacks. They are not timestamp-filtered and must not be",
                  "presented as exact operation-window self time.", "",
                  "| Function | VM self ticks | Location |", "|---|---:|---|"]
        raw_rows = sorted(raw_samples.get("functions", []),
                          key=lambda row: row.get("exclusiveTicks", 0), reverse=True)
        for row in raw_rows[:20]:
            name = row.get("function", {}).get("name", "unknown").replace("|", "\\|")
            location = str(row.get("resolvedUrl", "")).replace("|", "\\|")
            lines.append(f"| {name} | {row.get('exclusiveTicks', 0)} | {location} |")
    return "\n".join(lines) + "\n"


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--corpus", type=Path, required=True)
    parser.add_argument("--engine", choices=["ack", "ack-json-schema"], required=True)
    parser.add_argument("--case", required=True)
    parser.add_argument("--mode", choices=["validate", "decode-only", "decode+validate", "clone"],
                        default="validate")
    parser.add_argument("--operations", type=positive, default=1000)
    parser.add_argument("--warmup-ms", type=positive, default=2000)
    parser.add_argument("--worker-timeout", type=positive, default=180)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    with open(Path(tempfile.gettempdir()) / "ack-comparison-benchmark.lock", "w") as lock:
        try:
            fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
        except BlockingIOError:
            parser.error("Another ACK benchmark/profile process is running")
        run_profile(args)


def run_profile(args):
    output = args.output.resolve()
    output.mkdir(parents=True, exist_ok=False)
    service_info = output / "service-info.json"
    command = ["dart", "--enable-vm-service=0/127.0.0.1", "--profiler",
               f"--write-service-info={service_info}", "bin/profile_worker.dart",
               str(args.corpus.resolve()), args.engine, args.case, args.mode]
    document = {
        "status": "running", "createdUtc": datetime.now(timezone.utc).isoformat(),
        "revision": capture(["git", "rev-parse", "HEAD"]),
        "source": source_digest(), "dartVersion": capture(["dart", "--version"]),
        "corpusSha256": digest(args.corpus), "command": command,
        "settings": {key: str(value) if isinstance(value, Path) else value
                     for key, value in vars(args).items()},
        "limitations": [
            "Instrumented diagnostics, not throughput leaderboard timings.",
            "Heap snapshots are live-heap state, NOT allocation bytes/op.",
            "CPU samples are statistical samples, not exact call counts or wall-time attribution.",
            "Serialized stacks omit stubs/invisible frames; leaf-frame counts are not PC self ticks.",
            "Raw VM aggregate ticks may include samples outside the requested operation window.",
            "No forced GC, allocation reset, automatic retry, or concurrent measurement.",
        ],
    }
    write_json(output / "profile.json", document)
    lines = queue.Queue()
    started = time.monotonic()
    process = subprocess.Popen(command, cwd=ROOT / "dart", stdin=subprocess.PIPE,
                               stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                               text=True, bufsize=1)

    def read_output():
        with (output / "worker.log").open("w") as log:
            for line in process.stdout:
                log.write(line)
                log.flush()
                lines.put(line)
        lines.put(None)

    thread = threading.Thread(target=read_output, daemon=True)
    thread.start()

    def reply(expected):
        deadline = time.monotonic() + args.worker_timeout
        while True:
            remaining = deadline - time.monotonic()
            if remaining <= 0:
                raise TimeoutError(f"No worker reply for {expected}")
            line = lines.get(timeout=remaining)
            if line is None:
                raise RuntimeError(f"Worker exited before {expected}; see worker.log")
            try:
                value = json.loads(line)
            except json.JSONDecodeError:
                continue
            if value.get("event") == "error":
                raise RuntimeError(f"Worker error: {value}")
            if value.get("event") == expected:
                return value

    def send(value):
        process.stdin.write(json.dumps(value) + "\n")
        process.stdin.flush()

    try:
        ready = reply("ready")
        validity_checks = (2 * ready.get("inputCount", -1)
                           if args.mode in {"validate", "decode+validate"} else 0)
        if (ready.get("engine") != args.engine or ready.get("case") != args.case
                or ready.get("mode") != args.mode or not ready.get("isolateId")
                or ready.get("inputCount", 0) <= 0
                or ready.get("validityChecks", -1) != validity_checks
                or ready.get("modeChecks", 0) != 2 * ready.get("inputCount", -1)):
            raise ValueError("Worker identity or selected-case correctness checks disagree")
        document["ready"] = ready
        # Service startup and worker startup happen independently.
        while not service_info.exists():
            if time.monotonic() - started > args.worker_timeout:
                raise TimeoutError("VM service info file did not appear")
            time.sleep(0.02)
        uri = json.loads(service_info.read_text())["uri"]
        parsed = urlparse(uri)
        if parsed.hostname != "127.0.0.1" or parsed.scheme != "http":
            raise ValueError("Expected an authenticated loopback VM service URI")
        isolate = ready["isolateId"]
        document["serviceVersion"] = rpc(uri, "getVersion")
        send({"command": "warmup", "milliseconds": args.warmup_ms})
        document["warmup"] = reply("warmup")
        rpc(uri, "clearCpuSamples", isolateId=isolate)
        # Omit gc/reset parameters: false is rejected by this SDK implementation.
        before = rpc(uri, "getAllocationProfile", isolateId=isolate)
        write_json(output / "heap-before.json", before)
        send({"command": "measure", "operations": args.operations})
        measurement = reply("measure")
        if (measurement.get("operations") != args.operations
                or measurement.get("checksum") != measurement.get("expectedChecksum")
                or measurement.get("sinkBytes", 0) <= 0
                or measurement["endMicros"] <= measurement["startMicros"]):
            raise ValueError("Worker returned invalid measurement boundaries/checksum")
        document["measurement"] = measurement
        raw_samples = rpc(uri, "getCpuSamples", isolateId=isolate,
                      timeOrigin=measurement["startMicros"],
                      timeExtent=measurement["endMicros"] - measurement["startMicros"])
        write_json(output / "cpu-samples.json", raw_samples)
        samples = select_cpu_window(raw_samples, measurement["startMicros"],
                                    measurement["endMicros"])
        write_json(output / "cpu-samples-window.json", samples)
        timestamps = [row["timestamp"] for row in samples.get("samples", [])]
        document["cpuWindow"] = {
            "requestedStartMicros": measurement["startMicros"],
            "requestedEndMicros": measurement["endMicros"],
            "reportedTimeOriginMicros": raw_samples.get("timeOriginMicros"),
            "reportedTimeExtentMicros": raw_samples.get("timeExtentMicros"),
            "samplePeriodMicros": samples.get("samplePeriod"),
            "returnedSamples": len(raw_samples.get("samples", [])),
            "selectedSamples": len(timestamps),
            "outsideWindowSamples": len(raw_samples.get("samples", [])) - len(timestamps),
            "firstSampleMicros": min(timestamps) if timestamps else None,
            "lastSampleMicros": max(timestamps) if timestamps else None,
            "truncatedStackSamples": sum(bool(row.get("truncated"))
                                         for row in samples.get("samples", [])),
        }
        after = rpc(uri, "getAllocationProfile", isolateId=isolate)
        write_json(output / "heap-after.json", after)
        document["cpuSampleCount"] = len(samples.get("samples", []))
        document["sourceAfter"] = source_digest()
        if document["sourceAfter"] != document["source"]:
            raise ValueError("Source changed during profiling")
        send({"command": "exit"})
        process.stdin.close()
        process.wait(timeout=30)
        if process.returncode:
            raise RuntimeError(f"Worker exit code {process.returncode}")
        document["status"] = "complete"
        document["elapsedSeconds"] = time.monotonic() - started
        (output / "report.md").write_text(profile_summary(document, samples, raw_samples))
        print(f"Complete: {output}", flush=True)
    except BaseException as error:
        document["status"] = "interrupted" if isinstance(error, KeyboardInterrupt) else "failed"
        document["error"] = str(error)
        raise
    finally:
        if process.poll() is None:
            process.terminate()
            try:
                process.wait(timeout=10)
            except subprocess.TimeoutExpired:
                process.kill()
                process.wait(timeout=10)
        thread.join(timeout=5)
        write_json(output / "profile.json", document)


if __name__ == "__main__":
    def interrupted(_signal, _frame):
        raise KeyboardInterrupt("Profiler terminated; no automatic retry")

    signal.signal(signal.SIGTERM, interrupted)
    main()
