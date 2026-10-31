#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
version="$(node -e 'const p=require(process.argv[1]); process.stdout.write(p.version)' "$repo_root/plugin.json")"
output_dir="$repo_root/dist"
output_file="$output_dir/prodhub-chatgpt-plugin-$version.zip"

mkdir -p "$output_dir"
rm -f "$output_file"
cd "$repo_root"
zip -q -r "$output_file" plugin.json mcp.json assets skills
printf '%s\n' "$output_file"
