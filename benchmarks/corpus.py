"""One deterministic, JSON-only corpus consumed by every runtime."""

from copy import deepcopy


def corpus():
    token = {
        "type": "string", "minLength": 3, "maxLength": 64,
        "pattern": "^[a-z][a-z0-9_-]*$",
    }

    def obj(properties):
        return {
            "type": "object", "properties": properties,
            "required": list(properties), "additionalProperties": False,
        }

    flat = obj({
        "id": token,
        "count": {"type": "integer", "minimum": 0, "maximum": 10000},
        "active": {"type": "boolean"},
        "tags": {
            "type": "array", "items": token, "minItems": 1, "maxItems": 5,
        },
    })
    item = obj({
        "sku": token,
        "quantity": {"type": "integer", "minimum": 1, "maximum": 100},
        "active": {"type": "boolean"},
    })
    nested = obj({
        "id": token,
        "items": {
            "type": "array", "items": item,
            "minItems": 1, "maxItems": 1000,
        },
    })
    schemas = {"string": token, "flat": flat, "nested": nested}
    # Draft-7 is the shared subset, not a claim of 2020-12 parity.
    schemas = {
        name: {"$schema": "http://json-schema.org/draft-07/schema#", **schema}
        for name, schema in schemas.items()
    }
    cases = []

    def add(name, schema, values, valid=True, *, timed=True):
        flags = valid if isinstance(valid, list) else [valid] * len(values)
        assert len(values) == len(flags)
        cases.append({
            "name": name, "schema": schema, "phase": "validate",
            "timed": timed,
            "inputs": [
                {"value": value, "valid": flag}
                for value, flag in zip(values, flags)
            ],
        })

    def flats():
        return [
            {"id": f"user_{i}", "count": i * 37,
             "active": i % 2 == 0, "tags": [f"tag_{i}", "dart"]}
            for i in range(16)
        ]

    def nest(size):
        return [
            {"id": f"order_{i}", "items": [
                {"sku": f"sku_{i}_{j}", "quantity": 1 + (i + j) % 100,
                 "active": (i + j) % 2 == 0}
                for j in range(size)
            ]}
            for i in range(16)
        ]

    add("string-valid", "string", [f"token_{i}" for i in range(16)])
    add("string-invalid-type", "string", list(range(16)), False)
    add("string-invalid-constraint", "string", [f"BAD_{i}" for i in range(16)], False)
    add("flat-valid", "flat", flats())
    for name, mutate in [
        ("invalid-first", lambda v: v.update(id="BAD")),
        ("invalid-last", lambda v: v.update(tags=["valid", None])),
        ("invalid-many", lambda v: v.update(id="BAD", count=-1, active="yes", tags=[])),
        ("missing", lambda v: v.pop("count")),
        ("null", lambda v: v.update(count=None)),
        ("unknown-key", lambda v: v.update(extra=True)),
        ("numeric-string", lambda v: v.update(count="42")),
    ]:
        values = flats()
        for value in values:
            mutate(value)
        add(f"flat-{name}", "flat", values, False)
    mixed = flats()
    for i in range(1, 16, 2):
        mixed[i]["count"] = -1
    add("flat-mixed", "flat", mixed, [i % 2 == 0 for i in range(16)])
    for size in [1, 50, 500]:
        add(f"nested-{size}-valid", "nested", nest(size))
    for name, indices in [
        ("first", [0]), ("last", [49]), ("many", range(50)),
    ]:
        values = nest(50)
        for value in values:
            for i in indices:
                value["items"][i]["quantity"] = -1
        add(f"nested-50-invalid-{name}", "nested", values, False)

    # Untimed boundary probes prevent accidentally weaker adapters winning.
    for name, value, valid in [
        ("min", "abc", True), ("max", "a" * 64, True),
        ("short", "ab", False), ("long", "a" * 65, False),
        ("null", None, False), ("empty", "", False),
        ("object", {}, False), ("newline", "abc\ndef", False),
    ]:
        add(f"probe-string-{name}", "string", [value], valid, timed=False)
    for field, values in {
        "count": [(-1, False), (0, True), (10000, True), (10001, False), (1.5, False)],
        "tags": [([], False), (["abc"], True), (["abc"] * 5, True),
                 (["abc"] * 6, False), (["ab"], False), ("abc", False)],
        "active": [(False, True), (0, False), (None, False)],
    }.items():
        for index, (replacement, valid) in enumerate(values):
            value = flats()[0]
            value[field] = replacement
            add(f"probe-flat-{field}-{index}", "flat", [value], valid, timed=False)
    add("probe-flat-wrong-root", "flat", [None, [], "abc", 1], False, timed=False)
    for name, mutate in [
        ("item-extra", lambda v: v["items"][0].update(extra=True)),
        ("item-missing", lambda v: v["items"][0].pop("sku")),
        ("item-null", lambda v: v["items"].__setitem__(0, None)),
        ("empty-items", lambda v: v.update(items=[])),
        ("too-many-items", lambda v: v.update(items=v["items"] * 1001)),
        ("quantity-high", lambda v: v["items"][0].update(quantity=101)),
    ]:
        value = nest(1)[0]
        mutate(value)
        add(f"probe-nested-{name}", "nested", [value], False, timed=False)

    for source_name, phase in [
        ("flat-valid", "decode+validate"),
        ("nested-50-valid", "decode+validate"),
        ("string-valid", "construct+validate"),
        ("flat-valid", "construct+validate"),
        ("nested-50-valid", "construct+validate"),
    ]:
        source = deepcopy(next(c for c in cases if c["name"] == source_name))
        source.update(name=f"{source_name}/{phase}", phase=phase)
        cases.append(source)
    return {"version": 1, "schemas": schemas, "cases": cases}


def scaling_corpus(sizes, variants=4):
    """Separate larger-payload cohort; never silently alter the common corpus.

    Keep schemas constant within this cohort, even as the item count changes.
    Four independently allocated payloads per case bound fixture memory while
    avoiding a single constant input. Max-size boundary probes stay untimed.
    """
    sizes = sorted(set(sizes))
    if not sizes or sizes[0] < 1 or sizes[-1] > 100_000:
        raise ValueError("Scaling sizes must be between 1 and 100000")
    if variants < 2 or variants > 16:
        raise ValueError("Scaling corpus needs 2 to 16 varying payloads")
    base = corpus()
    schema = deepcopy(base["schemas"]["nested"])
    schema["properties"]["items"]["maxItems"] = sizes[-1]
    cases = []

    def payload(size, variant):
        return {
            "id": f"order_{variant}",
            "items": [
                {"sku": f"sku_{variant}_{index}",
                 "quantity": 1 + (variant + index) % 100,
                 "active": (variant + index) % 2 == 0}
                for index in range(size)
            ],
        }

    def add(name, values, valid, phase="validate", timed=True, size=None):
        cases.append({
            "name": name, "schema": "nested", "phase": phase,
            "timed": timed, "itemsPerPayload": size,
            "inputs": [{"value": value, "valid": valid} for value in values],
        })

    for size in sizes:
        for suffix in ["valid", "invalid-first", "invalid-last", "invalid-many"]:
            values = [payload(size, variant) for variant in range(variants)]
            for value in values:
                if suffix == "invalid-first":
                    value["items"][0]["quantity"] = -1
                elif suffix == "invalid-last":
                    value["items"][-1]["quantity"] = -1
                elif suffix == "invalid-many":
                    for item in value["items"]:
                        item["quantity"] = -1
            add(f"nested-{size}-{suffix}", values, suffix == "valid", size=size)
        add(f"nested-{size}-valid/decode+validate",
            [payload(size, variant) for variant in range(variants)], True,
            phase="decode+validate", size=size)

    # Retain the common nested semantic probes, with this cohort's size bound.
    for original in base["cases"]:
        if original["schema"] != "nested" or original["timed"]:
            continue
        probe = deepcopy(original)
        if probe["name"] == "probe-nested-too-many-items":
            probe["inputs"] = [{"value": payload(sizes[-1] + 1, 0), "valid": False}]
        cases.append(probe)
    add("probe-nested-upper-bound", [payload(sizes[-1], 0)], True,
        timed=False, size=sizes[-1])
    add("probe-nested-wrong-root", [None, [], "abc", 1], False, timed=False)
    return {
        "version": 2, "suite": "scaling", "sizes": sizes,
        "variants": variants, "schemas": {"nested": schema}, "cases": cases,
    }
