# Contributing to acal

Thanks for helping improve `acal`.

This repository is built for both human contributors and agent workflows, so we optimize for traceability, small changes, and deterministic behavior.

## Ground rules

- Keep changes small and reviewable.
- Prefer explicit behavior over clever behavior.
- Do not break JSON output contracts without an ADR/update.
- Use `td` issues for planning and status tracking.

## Development setup

```bash
swift build
swift test
```

Optional local quality checks (if installed):

```bash
swiftformat .
swiftlint
```

## Workflow (required)

### 1) Attach work to a td issue

Use an existing issue or create one before implementation.

```bash
td status
td ready
td start <issue-id>
td focus <issue-id>
```

### 2) Implement + verify

At minimum before review:

```bash
swift build -c debug
swift build -c release
swift test --parallel
```

If you changed style-sensitive code, run formatter/lint locally too.

### 3) Document decisions

- Add `td log` entries while working
- Add `td comment` for important context
- Update docs/ADRs when behavior changes

### 4) Handoff + review

```bash
td handoff <issue-id> \
  --done "what is done" \
  --remaining "what is left" \
  --decision "key choice" \
  --uncertain "open question"

td review <issue-id> --reason "ready for review"
```

## Coding conventions

- Swift style controlled by `.swiftformat` and `.swiftlint.yml`
- Keep public command behavior backwards-compatible where feasible
- Add/update tests for behavior changes (especially recurrence + auth + output contract)

## Commit guidance

Use concise Conventional Commit style when possible:

- `feat: ...`
- `fix: ...`
- `docs: ...`
- `chore: ...`
- `test: ...`

## Pull request checklist

Before opening a PR:

- [ ] Issue is tracked in `td`
- [ ] `swift build` passes (debug + release)
- [ ] `swift test` passes
- [ ] Docs/ADRs updated if needed
- [ ] JSON/output behavior changes called out explicitly

## Security and privacy

- Never commit secrets, tokens, certs, or private keys
- Keep telemetry/privacy behavior aligned with `docs/policy/privacy-telemetry.md`

Thanks for contributing.
