#!/bin/sh
# Install acal — Apple Calendar CLI
# Usage: curl -sSL https://raw.githubusercontent.com/Helmi/acal-apple-calendar-cli/main/install.sh | sh
set -e

REPO="Helmi/acal-apple-calendar-cli"
INSTALL_DIR="/usr/local/bin"
BINARY="acal"

# Allow override via environment
INSTALL_DIR="${ACAL_INSTALL_DIR:-$INSTALL_DIR}"

info() { printf '  \033[1;34m→\033[0m %s\n' "$1"; }
success() { printf '  \033[1;32m✓\033[0m %s\n' "$1"; }
fail() { printf '  \033[1;31m✗\033[0m %s\n' "$1" >&2; exit 1; }

# Check macOS
[ "$(uname -s)" = "Darwin" ] || fail "acal only runs on macOS (requires EventKit)."

# Find latest release tag
info "Finding latest release..."
TAG=$(curl -sSf "https://api.github.com/repos/${REPO}/releases/latest" \
  | grep '"tag_name"' | head -1 | sed 's/.*"tag_name": *"\([^"]*\)".*/\1/')
[ -n "$TAG" ] || fail "Could not determine latest release."
VERSION="${TAG#v}"
info "Latest version: ${VERSION}"

# Download
ASSET="acal-${VERSION}-macos-universal.zip"
URL="https://github.com/${REPO}/releases/download/${TAG}/${ASSET}"
CHECKSUM_URL="${URL}.sha256"
TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

info "Downloading ${ASSET}..."
curl -sSfL -o "${TMPDIR}/${ASSET}" "$URL" || fail "Download failed. Check https://github.com/${REPO}/releases"

# Verify checksum if available
if curl -sSfL -o "${TMPDIR}/checksum.sha256" "$CHECKSUM_URL" 2>/dev/null; then
  info "Verifying checksum..."
  EXPECTED=$(awk '{print $1}' "${TMPDIR}/checksum.sha256")
  ACTUAL=$(shasum -a 256 "${TMPDIR}/${ASSET}" | awk '{print $1}')
  [ "$EXPECTED" = "$ACTUAL" ] || fail "Checksum mismatch. Expected ${EXPECTED}, got ${ACTUAL}."
  success "Checksum verified"
fi

# Extract
info "Extracting..."
unzip -qo "${TMPDIR}/${ASSET}" -d "${TMPDIR}"
[ -f "${TMPDIR}/${BINARY}" ] || fail "Binary not found in archive."
chmod +x "${TMPDIR}/${BINARY}"

# Install
if [ -w "$INSTALL_DIR" ]; then
  mv "${TMPDIR}/${BINARY}" "${INSTALL_DIR}/${BINARY}"
else
  info "Installing to ${INSTALL_DIR} (requires sudo)..."
  sudo mv "${TMPDIR}/${BINARY}" "${INSTALL_DIR}/${BINARY}"
fi

success "acal ${VERSION} installed to ${INSTALL_DIR}/${BINARY}"
echo ""
echo "  Get started:"
echo "    acal doctor        # check permissions"
echo "    acal auth grant    # grant calendar access"
echo "    acal calendars list"
echo ""
echo "  For AI assistants (Claude Desktop, Claude Code):"
echo "    acal mcp --help"
echo ""
