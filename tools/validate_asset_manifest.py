#!/usr/bin/env python3
"""Validate Code Village asset manifest references.

This tool only reads assets/asset_manifest.json and checks referenced paths.
It does not inspect image contents, source files, diffs, secrets, or network data.
"""

from __future__ import annotations

import argparse
import json
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[1]
DEFAULT_MANIFEST = ROOT / "assets" / "asset_manifest.json"
ASSET_SECTIONS = (
    "tiles",
    "buildings",
    "environment",
    "characters",
    "ui",
    "effects",
    "growth_visuals",
)
DIRECTORY_SECTIONS = ("directories",)
VALID_MODES = {"placeholder", "production"}


@dataclass(frozen=True)
class Reference:
    source: str
    path: str
    kind: str


def _load_manifest(path: Path) -> tuple[dict[str, Any] | None, list[str]]:
    try:
        raw = path.read_text(encoding="utf-8")
    except OSError as exc:
        return None, [f"cannot read manifest: {path}: {exc}"]

    try:
        parsed = json.loads(raw)
    except json.JSONDecodeError as exc:
        return None, [f"manifest is not valid JSON: line {exc.lineno}: {exc.msg}"]

    if not isinstance(parsed, dict):
        return None, ["manifest must be a JSON object"]
    return parsed, []


def _local_res_path(res_path: str) -> Path | None:
    if not res_path.startswith("res://"):
        return None
    return ROOT / res_path.removeprefix("res://")


def _is_placeholder_ref(res_path: str) -> bool:
    return res_path.startswith("res://assets/placeholders/")


def _is_production_ref(res_path: str) -> bool:
    return res_path.startswith("res://assets/production/")


def _add_path_reference(
    refs: list[Reference],
    errors: list[str],
    source: str,
    path_value: Any,
    kind: str,
) -> None:
    if not isinstance(path_value, str) or path_value == "":
        errors.append(f"{source} must be a non-empty string path")
        return
    refs.append(Reference(source=source, path=path_value, kind=kind))


def _validate_basic_schema(manifest: dict[str, Any]) -> tuple[list[str], list[str]]:
    errors: list[str] = []
    warnings: list[str] = []

    schema_version = manifest.get("schema_version")
    if not isinstance(schema_version, int):
        errors.append("schema_version must be an integer")
    elif schema_version != 1:
        warnings.append(f"schema_version is {schema_version}; validator was written for version 1")

    mode = manifest.get("mode")
    if mode not in VALID_MODES:
        errors.append("mode must be one of: placeholder, production")

    tile_size = manifest.get("tile_size")
    if not isinstance(tile_size, int) or tile_size <= 0:
        errors.append("tile_size must be a positive integer")

    resolution = manifest.get("reference_resolution")
    if (
        not isinstance(resolution, list)
        or len(resolution) != 2
        or not all(isinstance(value, (int, float)) and value > 0 for value in resolution)
    ):
        errors.append("reference_resolution must be [positive_width, positive_height]")

    for section in ASSET_SECTIONS:
        if section not in manifest:
            errors.append(f"missing asset section: {section}")
        elif not isinstance(manifest[section], dict):
            errors.append(f"{section} must be an object")

    for section in DIRECTORY_SECTIONS:
        if section not in manifest:
            errors.append(f"missing directory section: {section}")
        elif not isinstance(manifest[section], dict):
            errors.append(f"{section} must be an object")

    if "sprite_layout" in manifest and not isinstance(manifest["sprite_layout"], list):
        errors.append("sprite_layout must be an array")
    if "state_visual_rules" in manifest and not isinstance(manifest["state_visual_rules"], list):
        errors.append("state_visual_rules must be an array")
    if "growth_effect_anchors" in manifest and not isinstance(manifest["growth_effect_anchors"], dict):
        errors.append("growth_effect_anchors must be an object")

    return errors, warnings


def _collect_direct_refs(manifest: dict[str, Any]) -> tuple[list[Reference], list[str]]:
    refs: list[Reference] = []
    errors: list[str] = []

    directories = manifest.get("directories", {})
    if isinstance(directories, dict):
        for key, path_value in directories.items():
            _add_path_reference(refs, errors, f"directories.{key}", path_value, "directory")

    for section in ASSET_SECTIONS:
        section_data = manifest.get(section, {})
        if not isinstance(section_data, dict):
            continue
        for key, path_value in section_data.items():
            _add_path_reference(refs, errors, f"{section}.{key}", path_value, "file")

    anchors = manifest.get("growth_effect_anchors", {})
    if isinstance(anchors, dict):
        for key, value in anchors.items():
            if not isinstance(value, dict):
                errors.append(f"growth_effect_anchors.{key} must be an object")
                continue
            _add_path_reference(
                refs,
                errors,
                f"growth_effect_anchors.{key}.path",
                value.get("path"),
                "file",
            )

    return refs, errors


def _resolve_section_key(
    manifest: dict[str, Any],
    refs: list[Reference],
    errors: list[str],
    source: str,
    section: Any,
    key: Any,
) -> None:
    if not isinstance(section, str) or not isinstance(key, str):
        errors.append(f"{source} must define string section and key")
        return
    section_data = manifest.get(section)
    if not isinstance(section_data, dict):
        errors.append(f"{source} references missing section: {section}")
        return
    if key not in section_data:
        errors.append(f"{source} references missing asset key: {section}.{key}")
        return
    _add_path_reference(refs, errors, f"{source} -> {section}.{key}", section_data[key], "file")


def _collect_indirect_refs(manifest: dict[str, Any]) -> tuple[list[Reference], list[str]]:
    refs: list[Reference] = []
    errors: list[str] = []

    sprite_layout = manifest.get("sprite_layout", [])
    if isinstance(sprite_layout, list):
        for index, entry in enumerate(sprite_layout):
            source = f"sprite_layout[{index}]"
            if not isinstance(entry, dict):
                errors.append(f"{source} must be an object")
                continue
            _resolve_section_key(manifest, refs, errors, source, entry.get("section"), entry.get("key"))
            position = entry.get("position")
            if not isinstance(position, list) or len(position) != 2:
                errors.append(f"{source}.position must be [x, y]")

    state_rules = manifest.get("state_visual_rules", [])
    if isinstance(state_rules, list):
        for index, entry in enumerate(state_rules):
            source = f"state_visual_rules[{index}]"
            if not isinstance(entry, dict):
                errors.append(f"{source} must be an object")
                continue
            if "path" in entry:
                _add_path_reference(refs, errors, f"{source}.path", entry.get("path"), "file")
            elif "growth_type" in entry:
                growth_type = entry.get("growth_type")
                visuals = manifest.get("growth_visuals", {})
                if not isinstance(growth_type, str):
                    errors.append(f"{source}.growth_type must be a string")
                elif not isinstance(visuals, dict) or growth_type not in visuals:
                    errors.append(f"{source} references missing growth_visuals.{growth_type}")
                else:
                    _add_path_reference(
                        refs,
                        errors,
                        f"{source} -> growth_visuals.{growth_type}",
                        visuals[growth_type],
                        "file",
                    )
            elif "section" in entry or "key" in entry:
                _resolve_section_key(manifest, refs, errors, source, entry.get("section"), entry.get("key"))
            else:
                errors.append(f"{source} must define path, growth_type, or section/key")

            position = entry.get("position")
            if not isinstance(position, list) or len(position) != 2:
                errors.append(f"{source}.position must be [x, y]")

    return refs, errors


def _validate_path_refs(refs: list[Reference]) -> list[str]:
    errors: list[str] = []
    for ref in refs:
        local_path = _local_res_path(ref.path)
        if local_path is None:
            errors.append(f"{ref.source} must use res:// path: {ref.path}")
            continue
        if ref.kind == "directory":
            if not local_path.is_dir():
                errors.append(f"{ref.source} directory does not exist: {ref.path}")
        elif not local_path.is_file():
            errors.append(f"{ref.source} file does not exist: {ref.path}")
    return errors


def _mode_warnings(mode: str, file_refs: list[Reference]) -> list[str]:
    warnings: list[str] = []
    placeholder_refs = [ref for ref in file_refs if _is_placeholder_ref(ref.path)]
    production_refs = [ref for ref in file_refs if _is_production_ref(ref.path)]

    if mode == "placeholder" and production_refs:
        warnings.append(
            "manifest mode is placeholder but production file refs are present: "
            f"{len(production_refs)}"
        )
    if mode == "production" and placeholder_refs:
        warnings.append(
            "manifest mode is production but placeholder file refs are present: "
            f"{len(placeholder_refs)}"
        )
    return warnings


def validate_manifest(
    manifest_path: Path,
    require_production: bool = False,
    strict_mode: bool = False,
) -> dict[str, Any]:
    manifest, load_errors = _load_manifest(manifest_path)
    if manifest is None:
        return {
            "manifest": str(manifest_path),
            "mode": None,
            "errors": load_errors,
            "warnings": [],
            "references": {},
        }

    schema_errors, schema_warnings = _validate_basic_schema(manifest)
    direct_refs, direct_errors = _collect_direct_refs(manifest)
    indirect_refs, indirect_errors = _collect_indirect_refs(manifest)
    refs = direct_refs + indirect_refs
    file_refs = [ref for ref in refs if ref.kind == "file"]
    directory_refs = [ref for ref in refs if ref.kind == "directory"]
    placeholder_file_refs = [ref for ref in file_refs if _is_placeholder_ref(ref.path)]
    production_file_refs = [ref for ref in file_refs if _is_production_ref(ref.path)]
    path_errors = _validate_path_refs(refs)

    errors = schema_errors + direct_errors + indirect_errors + path_errors
    warnings = schema_warnings + _mode_warnings(str(manifest.get("mode", "")), file_refs)

    if strict_mode:
        strict_warnings = _mode_warnings(str(manifest.get("mode", "")), file_refs)
        errors.extend(f"strict mode: {warning}" for warning in strict_warnings)

    if require_production:
        if manifest.get("mode") != "production":
            errors.append("production check requires manifest mode to be production")
        if placeholder_file_refs:
            examples = ", ".join(ref.source for ref in placeholder_file_refs[:8])
            if len(placeholder_file_refs) > 8:
                examples += ", ..."
            errors.append(
                "production check failed: "
                f"{len(placeholder_file_refs)} file refs still point to assets/placeholders "
                f"({examples})"
            )

    missing_count = sum(1 for error in path_errors if "does not exist" in error)
    return {
        "manifest": str(manifest_path),
        "mode": manifest.get("mode"),
        "require_production": require_production,
        "strict_mode": strict_mode,
        "references": {
            "total": len(refs),
            "files": len(file_refs),
            "directories": len(directory_refs),
            "placeholder_files": len(placeholder_file_refs),
            "production_files": len(production_file_refs),
            "missing": missing_count,
        },
        "errors": errors,
        "warnings": warnings,
    }


def _print_text_summary(result: dict[str, Any]) -> None:
    refs = result.get("references", {})
    if result["errors"]:
        print("ERROR: asset manifest validation failed.", file=sys.stderr)
        for error in result["errors"]:
            print(f"- {error}", file=sys.stderr)
    else:
        print(
            "OK: asset_manifest valid. "
            f"mode={result['mode']} "
            f"file_refs={refs.get('files', 0)} "
            f"placeholder_refs={refs.get('placeholder_files', 0)} "
            f"production_refs={refs.get('production_files', 0)} "
            f"warnings={len(result['warnings'])}"
        )

    for warning in result["warnings"]:
        print(f"WARNING: {warning}", file=sys.stderr)


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="Validate Code Village asset manifest.")
    parser.add_argument("--manifest", type=Path, default=DEFAULT_MANIFEST)
    parser.add_argument(
        "--require-production",
        action="store_true",
        help="Fail if manifest is not production-ready or any file ref still uses placeholders.",
    )
    parser.add_argument(
        "--strict-mode",
        action="store_true",
        help="Fail when manifest mode and referenced asset folder disagree.",
    )
    parser.add_argument("--json", action="store_true", help="Print machine-readable validation result.")
    args = parser.parse_args(argv)

    result = validate_manifest(
        args.manifest,
        require_production=args.require_production,
        strict_mode=args.strict_mode,
    )

    if args.json:
        print(json.dumps(result, ensure_ascii=False, indent=2, sort_keys=True))
    else:
        _print_text_summary(result)

    return 1 if result["errors"] else 0


if __name__ == "__main__":
    raise SystemExit(main())
