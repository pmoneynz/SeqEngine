#!/bin/bash
# Architecture boundary checker.
# Lightweight static import path checks from contract.yaml.

set -euo pipefail

workspace="${1:-$(pwd)}"
contract="$workspace/harness/architecture/contract.yaml"

if [[ ! -f "$contract" ]]; then
  echo "Architecture contract missing: $contract"
  exit 1
fi

if ! command -v python3 >/dev/null 2>&1; then
  echo "python3 required for architecture check"
  exit 1
fi

python3 - "$workspace" "$contract" << 'PY'
import pathlib
import re
import sys

workspace = pathlib.Path(sys.argv[1])
contract_path = pathlib.Path(sys.argv[2])

text = contract_path.read_text()

def parse_paths(layer_name):
    pattern = rf"{layer_name}:\n\s+paths:\n((?:\s+- .+\n)+)"
    m = re.search(pattern, text)
    if not m:
        return []
    return [line.strip().split("- ", 1)[1] for line in m.group(1).splitlines()]

layer_paths = {
    "domain": parse_paths("domain"),
    "application": parse_paths("application"),
    "infrastructure": parse_paths("infrastructure"),
    "interface": parse_paths("interface"),
}

allowed = {
    "domain": set(),
    "application": {"domain"},
    "infrastructure": {"domain", "application"},
    "interface": {"application"},
}

approved = set()
for m in re.finditer(r"- from_path: (.+)\n\s+to_path: (.+)", text):
    approved.add((m.group(1).strip(), m.group(2).strip()))

imports_pattern = re.compile(r'^\s*(?:import|from)\s+[^\n]*[\'"]([^\'"]+)[\'"]', re.MULTILINE)

def layer_for_file(path: pathlib.Path):
    rel = path.relative_to(workspace).as_posix()
    for layer, roots in layer_paths.items():
        for root in roots:
            if rel.startswith(root.rstrip("/") + "/") or rel == root.rstrip("/"):
                return layer
    return None

violations = []
for file in workspace.rglob("*"):
    if file.suffix not in {".ts", ".tsx", ".js", ".jsx", ".py"}:
        continue
    if ".git/" in file.as_posix() or "node_modules/" in file.as_posix():
        continue
    layer = layer_for_file(file)
    if not layer:
        continue

    rel_file = file.relative_to(workspace).as_posix()
    src = file.read_text(errors="ignore")
    for dep in imports_pattern.findall(src):
        if dep.startswith("."):
            continue
        dep_norm = dep.lstrip("/")
        dep_layer = None
        for candidate_layer, roots in layer_paths.items():
            for root in roots:
                root_clean = root.rstrip("/")
                if dep_norm.startswith(root_clean + "/") or dep_norm == root_clean:
                    dep_layer = candidate_layer
                    break
            if dep_layer:
                break

        if not dep_layer:
            continue
        if dep_layer in allowed[layer]:
            continue

        approved_match = False
        for from_path, to_path in approved:
            if rel_file.startswith(from_path.rstrip("/") + "/") and dep_norm.startswith(to_path.rstrip("/") + "/"):
                approved_match = True
                break
        if approved_match:
            continue
        violations.append((rel_file, dep_norm, layer, dep_layer))

if violations:
    print("Architecture violations detected:")
    for item in violations:
        print(f"  {item[0]} imports {item[1]} ({item[2]} -> {item[3]})")
    sys.exit(1)

print("Architecture check passed.")
PY
