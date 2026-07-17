#!/usr/bin/env python3
"""Validate canonical Artifact YAML against the v1alpha1 JSON Schemas."""

import json
from pathlib import Path

import yaml
from jsonschema import Draft202012Validator


class JSONLikeLoader(yaml.SafeLoader):
    """Keep YAML timestamps as strings so the value follows JSON data types."""


JSONLikeLoader.yaml_implicit_resolvers = {
    key: [entry for entry in entries if entry[0] != "tag:yaml.org,2002:timestamp"]
    for key, entries in yaml.SafeLoader.yaml_implicit_resolvers.items()
}

ROOT = Path(__file__).resolve().parent.parent
VECTORS = {
    "schemas/v1alpha1/context-artifact.schema.json": "examples/artifact/manifest.yaml",
    "schemas/v1alpha1/artifact-lock.schema.json": "examples/artifact/lock.yaml",
}

failed = False
for schema_name, vector_name in VECTORS.items():
    schema = json.loads((ROOT / schema_name).read_text(encoding="utf-8"))
    vector = yaml.load((ROOT / vector_name).read_text(encoding="utf-8"), Loader=JSONLikeLoader)
    for error in sorted(Draft202012Validator(schema).iter_errors(vector), key=lambda item: list(item.path)):
        location = ".".join(str(part) for part in error.path) or "$"
        print(f"{vector_name}:{location}: {error.message}")
        failed = True

raise SystemExit(1 if failed else 0)
