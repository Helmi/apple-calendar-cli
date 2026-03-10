# Privacy and Telemetry Stance

acal defaults to local-only operation.

## Commitments

1. No telemetry is sent by default.
2. No remote backend is required for core command execution.
3. Command output is limited to requested calendar metadata/event data.
4. Permission handling is explicit (`doctor`, `auth status`, `auth grant`, `auth reset`).

## Future telemetry policy

If optional telemetry is ever added, it must be:

- explicit opt-in,
- documented in README and release notes,
- disabled by default.
