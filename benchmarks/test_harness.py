"""Integrity checks for the measurements and corpus, not speed assertions."""

import copy
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

from corpus import corpus, scaling_corpus
from profile_jit import select_cpu_window
from run import (ack_digest, copy_ack_source, lane_groups, paired_comparisons,
                 scaling_sizes, summarize, timed_case_names, validate_worker)


class MeasurementIntegrityTests(unittest.TestCase):
    def result(self, samples=None):
        return {
            "checks": 10, "runtimeMode": "dart-aot", "engine": "ack",
            "results": [{
                "name": "flat-valid", "phase": "validate", "checksum": 10,
                "samples": samples or [{"iterations": 10, "elapsedNs": 100}],
            }],
        }

    def test_scales_batches_to_cost_per_operation(self):
        result = self.result([
            {"iterations": 10, "elapsedNs": 100},
            {"iterations": 100, "elapsedNs": 1000},
            {"iterations": 1000, "elapsedNs": 10000},
        ])
        summary = summarize([result])[0]
        self.assertEqual(summary["medianNs"], 10)
        self.assertEqual(summary["opsPerSecond"], 100_000_000)

    def test_weights_processes_equally_not_by_sample_count(self):
        short = self.result([{"iterations": 1, "elapsedNs": 10}])
        long = self.result([{"iterations": 1, "elapsedNs": 100}] * 9)
        self.assertEqual(summarize([short, long])[0]["medianNs"], 55)

    def test_rejects_missing_duplicate_and_unexpected_rows(self):
        for names in [[], ["flat-valid", "flat-valid"], ["other"]]:
            result = self.result()
            template = result["results"][0]
            result["results"] = [{**template, "name": name} for name in names]
            with self.subTest(names=names), self.assertRaises(ValueError):
                validate_worker(result, ["flat-valid"], 1)

    def test_rejects_invalid_measurements(self):
        for sample in [
            {"iterations": 0, "elapsedNs": 10},
            {"iterations": 1.5, "elapsedNs": 10},
            {"iterations": 1, "elapsedNs": 0},
            {"iterations": 1, "elapsedNs": float("nan")},
        ]:
            with self.subTest(sample=sample), self.assertRaises(ValueError):
                validate_worker(self.result([sample]), ["flat-valid"], 1)

    def test_rejects_missing_correctness_checks_and_samples(self):
        result = self.result()
        result["checks"] = 0
        with self.assertRaises(ValueError):
            validate_worker(result, ["flat-valid"], 1)
        with self.assertRaises(ValueError):
            validate_worker(self.result(), ["flat-valid"], 2)

    def test_accepts_correctness_only_worker(self):
        validate_worker({"checks": 800, "results": []}, [], 7)


class CorpusIntegrityTests(unittest.TestCase):
    def test_timing_filter_preserves_full_correctness_corpus(self):
        data = corpus()
        original = copy.deepcopy(data)
        self.assertEqual(timed_case_names(data, "flat-valid,string-valid"),
                         ["string-valid", "flat-valid"])
        self.assertEqual(data, original)

    def test_timing_filter_rejects_unknown_duplicates_and_untimed_probes(self):
        for selected in ["", "unknown", "flat-valid,flat-valid", "probe-string-min"]:
            with self.subTest(selected=selected), self.assertRaises(ValueError):
                timed_case_names(corpus(), selected)

    def test_deterministic_and_nonaliased(self):
        first = corpus()
        self.assertEqual(first, corpus())
        flat = next(c for c in first["cases"] if c["name"] == "flat-valid")
        original = copy.deepcopy(flat["inputs"][1])
        flat["inputs"][0]["value"]["tags"].append("changed")
        self.assertEqual(flat["inputs"][1], original)

    def test_mixed_case_is_balanced(self):
        mixed = next(c for c in corpus()["cases"] if c["name"] == "flat-mixed")
        self.assertEqual(sum(i["valid"] for i in mixed["inputs"]), 8)

    def test_every_schema_has_positive_and_negative_cases(self):
        data = corpus()
        names = [c["name"] for c in data["cases"]]
        self.assertEqual(len(names), len(set(names)))
        for schema in data["schemas"]:
            flags = {i["valid"] for c in data["cases"] if c["schema"] == schema
                     for i in c["inputs"]}
            self.assertEqual(flags, {True, False})


class RevisionComparisonTests(unittest.TestCase):
    def test_source_baseline_is_detached_and_only_copies_ack(self):
        with tempfile.TemporaryDirectory() as directory:
            source, target = Path(directory) / "before", Path(directory) / "frozen"
            (source / "packages/ack/lib").mkdir(parents=True)
            code = source / "packages/ack/lib/ack.dart"
            code.write_text("const version = 1;\n")
            (source / "packages/ack/pubspec.yaml").write_text("name: ack\n")
            (source / "unrelated.txt").write_text("not benchmark source")
            identity = copy_ack_source(source, target)
            self.assertEqual(identity, ack_digest(target))
            code.write_text("const version = 2;\n")
            self.assertEqual(identity, ack_digest(target))
            self.assertNotEqual(identity, ack_digest(source))
            self.assertFalse((target / "unrelated.txt").exists())

    def test_source_baseline_rejects_incomplete_source(self):
        with tempfile.TemporaryDirectory() as directory:
            with self.assertRaises(ValueError):
                copy_ack_source(Path(directory), Path(directory) / "out")

    def run_row(self, engine, fork, ns):
        return {
            "runtimeMode": "dart-aot", "engine": engine, "fork": fork,
            "results": [{
                "name": "flat-valid", "phase": "validate",
                "samples": [{"iterations": 1, "elapsedNs": ns}],
            }],
        }

    def test_pairs_by_runtime_engine_and_fork(self):
        runs = [
            self.run_row("ack-baseline", 0, 100),
            self.run_row("ack", 0, 10),
            self.run_row("ack-baseline", 1, 1),
            self.run_row("ack", 1, 1),
            self.run_row("validart", 0, 0.5),
        ]
        row = paired_comparisons(runs)[0]
        # Median of [10x, 1x], not ratio of medians 50.5/5.5.
        self.assertEqual(row["medianPairedSpeedup"], 5.5)
        self.assertEqual(row["fasterPairs"], 1)
        self.assertEqual(row["minPairedSpeedup"], 1)
        self.assertEqual(row["maxPairedSpeedup"], 10)

    def test_does_not_pair_different_forks(self):
        with self.assertRaises(ValueError):
            paired_comparisons([
                self.run_row("ack-baseline", 0, 100),
                self.run_row("ack", 1, 10),
            ])

    def test_does_not_pair_different_runtimes(self):
        candidate = self.run_row("ack", 0, 10)
        candidate["runtimeMode"] = "dart-jit"
        with self.assertRaises(ValueError):
            paired_comparisons([self.run_row("ack-baseline", 0, 100), candidate])

    def test_rejects_duplicate_measurements(self):
        with self.assertRaises(ValueError):
            paired_comparisons([self.run_row("ack", 0, 10)] * 2)

    def test_keeps_revision_workers_adjacent_and_competitors_separate(self):
        lanes = [
            ("dart-aot", "ack"), ("node", "ajv"),
            ("dart-aot", "ack-baseline"),
        ]
        self.assertEqual(lane_groups(lanes), [
            [("dart-aot", "ack-baseline"), ("dart-aot", "ack")],
            [("node", "ajv")],
        ])


class ScalingCorpusTests(unittest.TestCase):
    def test_aot_is_rejected_before_starting_a_worker(self):
        result = subprocess.run(
            [sys.executable, str(Path(__file__).with_name("run.py")),
             "--runtimes", "dart-aot"], text=True, capture_output=True)
        self.assertEqual(result.returncode, 2)
        self.assertIn("AOT is discontinued", result.stderr)

    def test_sizes_change_payloads_without_changing_schema_between_cases(self):
        data = scaling_corpus([1, 10, 100])
        self.assertEqual(len(data["schemas"]), 1)
        self.assertEqual(data["schemas"]["nested"]["properties"]["items"]["maxItems"], 100)
        timed = [case for case in data["cases"] if case["timed"]]
        self.assertEqual(len(timed), 15)
        for case in timed:
            self.assertEqual(len(case["inputs"]), 4)
            for entry in case["inputs"]:
                self.assertEqual(len(entry["value"]["items"]), case["itemsPerPayload"])

    def test_first_last_and_many_errors_are_where_advertised(self):
        data = scaling_corpus([10])
        for suffix, expected in [("valid", []), ("invalid-first", [0]),
                                 ("invalid-last", [9]), ("invalid-many", list(range(10)))]:
            case = next(c for c in data["cases"] if c["name"] == f"nested-10-{suffix}")
            for entry in case["inputs"]:
                invalid = [i for i, item in enumerate(entry["value"]["items"])
                           if item["quantity"] < 1]
                self.assertEqual(invalid, expected)
                self.assertEqual(entry["valid"], not expected)

    def test_upper_bound_probes_track_requested_maximum(self):
        data = scaling_corpus([5, 20])
        for name, size, valid in [("probe-nested-upper-bound", 20, True),
                                 ("probe-nested-too-many-items", 21, False)]:
            case = next(c for c in data["cases"] if c["name"] == name)
            self.assertFalse(case["timed"])
            entry = case["inputs"][0]
            self.assertEqual(len(entry["value"]["items"]), size)
            self.assertEqual(entry["valid"], valid)

    def test_inputs_are_independent_and_common_corpus_is_unchanged(self):
        original = corpus()
        data = scaling_corpus([1, 10])
        case = next(c for c in data["cases"] if c["name"] == "nested-10-valid")
        case["inputs"][0]["value"]["items"][0]["quantity"] = -999
        self.assertGreater(case["inputs"][1]["value"]["items"][0]["quantity"], 0)
        self.assertEqual(original, corpus())

    def test_rejects_unbounded_or_duplicate_cli_sizes(self):
        import argparse
        for value in ["", "0", "-1", "100001", "10,10", "abc"]:
            with self.subTest(value=value), self.assertRaises(argparse.ArgumentTypeError):
                scaling_sizes(value)
        self.assertEqual(scaling_sizes("100,1,10"), [1, 10, 100])


class CpuWindowTests(unittest.TestCase):
    def test_excludes_service_samples_outside_exact_operation_window(self):
        raw = {"sampleCount": 4, "_counters": {"unwindowed": 10},
               "functions": [{"exclusiveTicks": 20, "inclusiveTicks": 30}, {}],
               "samples": [{"timestamp": 9, "stack": [1]},
                           {"timestamp": 10, "stack": [0, 1, 0]},
                           {"timestamp": 19, "stack": [1]},
                           {"timestamp": 20, "stack": [0]}]}
        result = select_cpu_window(raw, 10, 20)
        self.assertEqual(result["sampleCount"], 2)
        self.assertEqual(result["functions"][0]["leafFrameSamples"], 1)
        self.assertEqual(result["functions"][0]["stackPresenceSamples"], 1)
        self.assertEqual(result["functions"][1]["stackPresenceSamples"], 2)
        self.assertNotIn("exclusiveTicks", result["functions"][0])
        self.assertNotIn("inclusiveTicks", result["functions"][0])
        self.assertNotIn("_counters", result)
        self.assertEqual(raw["functions"][0]["exclusiveTicks"], 20)
        self.assertEqual(len(raw["samples"]), 4)

    def test_rejects_invalid_function_indexes(self):
        with self.assertRaises(ValueError):
            select_cpu_window({"functions": [],
                               "samples": [{"timestamp": 1, "stack": [0]}]}, 0, 2)


if __name__ == "__main__":
    unittest.main()
