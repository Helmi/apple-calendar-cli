#!/bin/bash
# Build a macOS .pkg installer for acal.
# Usage: scripts/build-pkg.sh --binary dist/release/acal --version 0.3.0 --output dist/release/acal-0.3.0.pkg
#
# Optional: --sign "Developer ID Installer: ..." to sign the pkg.
set -euo pipefail

BINARY=""
VERSION=""
OUTPUT=""
SIGN_IDENTITY=""
IDENTIFIER="com.helmi.acal"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --binary)   BINARY="$2"; shift 2 ;;
    --version)  VERSION="$2"; shift 2 ;;
    --output)   OUTPUT="$2"; shift 2 ;;
    --sign)     SIGN_IDENTITY="$2"; shift 2 ;;
    *) echo "Unknown option: $1" >&2; exit 1 ;;
  esac
done

[[ -n "$BINARY" ]]  || { echo "Error: --binary required" >&2; exit 1; }
[[ -n "$VERSION" ]] || { echo "Error: --version required" >&2; exit 1; }
[[ -n "$OUTPUT" ]]  || { echo "Error: --output required" >&2; exit 1; }
[[ -f "$BINARY" ]]  || { echo "Error: binary not found: $BINARY" >&2; exit 1; }

TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

# --- Payload: the binary goes into /usr/local/bin ---
mkdir -p "$TMPDIR/payload/usr/local/bin"
cp "$BINARY" "$TMPDIR/payload/usr/local/bin/acal"
chmod 755 "$TMPDIR/payload/usr/local/bin/acal"

# --- Post-install script: print getting-started message ---
mkdir -p "$TMPDIR/scripts"
cat > "$TMPDIR/scripts/postinstall" << 'POSTINSTALL'
#!/bin/sh
# Ensure /usr/local/bin is in PATH for GUI-launched terminals
if ! grep -q '/usr/local/bin' /etc/paths 2>/dev/null; then
  echo '/usr/local/bin' | sudo tee -a /etc/paths >/dev/null 2>&1 || true
fi
exit 0
POSTINSTALL
chmod 755 "$TMPDIR/scripts/postinstall"

# --- Welcome text for the installer UI ---
mkdir -p "$TMPDIR/resources"
cat > "$TMPDIR/resources/welcome.html" << WELCOME
<html>
<head><meta charset="utf-8"></head>
<body style="font-family: -apple-system, Helvetica Neue, sans-serif; padding: 20px;">
<h1>acal &#8212; Apple Calendar CLI</h1>
<p>This installer places the <code>acal</code> command-line tool on your Mac.</p>
<p><strong>Getting started:</strong></p>
<pre style="background: #f5f5f5; padding: 12px; border-radius: 6px; font-size: 13px;">acal auth grant      # grant calendar access (one time)
acal calendars list  # see your calendars
acal events list     # list upcoming events
acal mcp --help      # AI assistant integration</pre>
<p style="margin-top: 16px;">For AI assistants like Claude, run <code>acal mcp</code> to start the
<a href="https://modelcontextprotocol.io">MCP</a> server.</p>
<p style="color: #666; font-size: 12px;">Version ${VERSION} &#8212; Universal binary (Apple Silicon + Intel)</p>
</body></html>
WELCOME

cat > "$TMPDIR/resources/license.html" << 'LICENSE'
<html><body style="font-family: -apple-system, Helvetica Neue, sans-serif; padding: 20px;">
<h2>MIT License</h2>
<p>Copyright (c) 2026 Helmi</p>
<p>Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:</p>
<p>The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.</p>
<p>THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.</p>
</body></html>
LICENSE

# --- Distribution XML for the installer UI ---
cat > "$TMPDIR/distribution.xml" << DIST
<?xml version="1.0" encoding="utf-8"?>
<installer-gui-script minSpecVersion="2">
    <title>acal &#8212; Apple Calendar CLI</title>
    <welcome file="welcome.html" />
    <license file="license.html" />
    <options customize="never" require-scripts="false" hostArchitectures="arm64,x86_64" />
    <domains enable_localSystem="true" enable_currentUserHome="true" />
    <choices-outline>
        <line choice="default">
            <line choice="com.helmi.acal.pkg" />
        </line>
    </choices-outline>
    <choice id="default" />
    <choice id="com.helmi.acal.pkg" visible="false">
        <pkg-ref id="com.helmi.acal.pkg" />
    </choice>
    <pkg-ref id="com.helmi.acal.pkg" version="${VERSION}" onConclusion="none">acal-component.pkg</pkg-ref>
</installer-gui-script>
DIST

# --- Build component pkg ---
pkgbuild \
  --root "$TMPDIR/payload" \
  --identifier "$IDENTIFIER" \
  --version "$VERSION" \
  --scripts "$TMPDIR/scripts" \
  "$TMPDIR/acal-component.pkg"

# --- Build distribution pkg (nice UI) ---
if [[ -n "$SIGN_IDENTITY" ]]; then
  echo "Signing pkg with: $SIGN_IDENTITY"
  productbuild \
    --distribution "$TMPDIR/distribution.xml" \
    --resources "$TMPDIR/resources" \
    --package-path "$TMPDIR" \
    --sign "$SIGN_IDENTITY" \
    "$OUTPUT"
else
  productbuild \
    --distribution "$TMPDIR/distribution.xml" \
    --resources "$TMPDIR/resources" \
    --package-path "$TMPDIR" \
    "$OUTPUT"
fi

echo "Built: $OUTPUT"
ls -lh "$OUTPUT"
