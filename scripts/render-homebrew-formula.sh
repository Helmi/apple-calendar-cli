#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  render-homebrew-formula.sh \
    --version <semver> \
    --sha256 <sha256> \
    --repo <owner/repo> \
    [--asset-base <asset-base>] \
    [--output <path>]

Example:
  render-homebrew-formula.sh \
    --version 0.1.0 \
    --sha256 abc123... \
    --repo helmi/acal-cli \
    --asset-base acal-0.1.0-macos-universal \
    --output /tmp/Formula/acal.rb
EOF
}

VERSION=""
SHA256=""
REPO=""
ASSET_BASE=""
OUTPUT="Formula/acal.rb"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --version)
      VERSION="$2"
      shift 2
      ;;
    --sha256)
      SHA256="$2"
      shift 2
      ;;
    --repo)
      REPO="$2"
      shift 2
      ;;
    --asset-base)
      ASSET_BASE="$2"
      shift 2
      ;;
    --output)
      OUTPUT="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage
      exit 1
      ;;
  esac
done

if [[ -z "$VERSION" || -z "$SHA256" || -z "$REPO" ]]; then
  echo "Missing required arguments." >&2
  usage
  exit 1
fi

VERSION="${VERSION#v}"
TAG="v${VERSION}"

if [[ -z "$ASSET_BASE" ]]; then
  ASSET_BASE="acal-${VERSION}-macos-universal"
fi

ASSET_URL="https://github.com/${REPO}/releases/download/${TAG}/${ASSET_BASE}.zip"

mkdir -p "$(dirname "$OUTPUT")"

cat > "$OUTPUT" <<EOF
class Acal < Formula
  desc "Fast, EventKit-native A Calendar CLI for macOS"
  homepage "https://github.com/${REPO}"
  version "${VERSION}"
  url "${ASSET_URL}"
  sha256 "${SHA256}"
  license "MIT"

  def install
    binary = Dir["**/acal"].find { |path| File.file?(path) }
    odie "acal binary not found in release archive" if binary.nil?

    bin.install binary => "acal"
  end

  test do
    assert_match "schemaVersion", shell_output("#{bin}/acal schema --format json")
  end
end
EOF

echo "Wrote Homebrew formula to ${OUTPUT}"