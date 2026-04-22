#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd -- "$script_dir/.." && pwd)"
manifest_path="$repo_root/nix/package-manifest.json"
tmpdir="$(mktemp -d)"

cleanup() {
  rm -rf "$tmpdir"
}
trap cleanup EXIT

require() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "missing required command: $1" >&2
    exit 1
  }
}

require git
require jq

source_owner="$(jq -r '.source.owner' "$manifest_path")"
source_repo_name="$(jq -r '.source.repo' "$manifest_path")"
default_branch="$(jq -r '.source.defaultBranch // "main"' "$manifest_path")"
source_repo="${1:-https://github.com/$source_owner/$source_repo_name.git}"
source_ref="${2:-$default_branch}"
upstream_dir="$tmpdir/upstream"

echo "syncing $source_repo @ $source_ref"
git clone --depth 1 --branch "$source_ref" "$source_repo" "$upstream_dir" >/dev/null 2>&1
rev="$(git -C "$upstream_dir" rev-parse HEAD)"
version="$(sed -n 's/^version = "\([^"]*\)"/\1/p' "$upstream_dir/Cargo.toml" | head -n 1)"
archive_url="https://github.com/$source_owner/$source_repo_name/archive/$rev.tar.gz"
hash="$(nix store prefetch-file --json --unpack "$archive_url" | jq -r '.hash')"

if [[ -z "$version" ]]; then
  echo "failed to determine version from $upstream_dir/Cargo.toml" >&2
  exit 1
fi

jq \
  --arg version "$version" \
  --arg rev "$rev" \
  --arg hash "$hash" \
  --arg branch "$source_ref" \
  --arg owner "$source_owner" \
  --arg repo "$source_repo_name" \
  '.source.type = "github"
   | .source.owner = $owner
   | .source.repo = $repo
   | .source.channel = "github-head"
   | .source.defaultBranch = $branch
   | .source.version = $version
   | .source.rev = $rev
   | .source.hash = $hash
   | .package = (.package // {})' \
  "$manifest_path" > "$manifest_path.tmp"
mv "$manifest_path.tmp" "$manifest_path"

echo "updated:"
echo "  source:   $source_repo"
echo "  ref:      $source_ref"
echo "  rev:      $rev"
echo "  hash:     $hash"
echo "  version:  $version"
