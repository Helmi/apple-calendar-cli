# AGENTS.md — apple-calendar-cli

This repository uses **td** as the source of truth for planning and execution.

If you work here (human or agent), follow this flow exactly.

---

## 1) Session Start (Required)

At the start of a conversation/session:

```bash
td usage --new-session
```

Then set a readable session name (optional but recommended):

```bash
td session "<name>"
```

Always check current state before doing work:

```bash
td status
td ready
```

---

## 2) Work Must Be Attached to Issues

Do not start implementation without a td issue.

- Create epics/tasks first (`td epic create`, `td task create`)
- Set dependencies when relevant (`td dep add ...`)
- Use priorities (P0..P4)

---

## 3) Status Workflow (Canonical)

Use `td workflow` for authoritative transitions.

Current model:
- `open`
- `in_progress`
- `blocked`
- `in_review`
- `closed`

Common transitions:
- `open -> in_progress` via `td start <id>`
- `in_progress -> in_review` via `td review <id>`
- `in_review -> closed` via `td approve <id>` (different reviewer session)
- `in_review -> in_progress` via `td reject <id>`
- blocked/unblocked via `td block` / `td unblock`

---

## 4) Implementation Flow (Required)

### Start work
```bash
td start <issue-id>
td focus <issue-id>
```

### During work (keep trace)
Use log entries for progress and decisions:

```bash
td log "implemented parser skeleton"
td log --decision "use EventKit full-access API on macOS 14+"
```

Add comments when context matters for reviewers:

```bash
td comment <issue-id> "why we changed this"
```

### If blocked
```bash
td block <issue-id> --reason "waiting for API key"
```

### Before review (handoff required)
Create a structured handoff:

```bash
td handoff <issue-id> \
  --done "what is finished" \
  --remaining "what is left" \
  --decision "important decision" \
  --uncertain "open question"
```

Then submit for review:

```bash
td review <issue-id> --reason "ready for review"
```

### Review outcome
- Approve/close:
  ```bash
  td approve <issue-id> --reason "looks good"
  ```
- Reject back to in-progress:
  ```bash
  td reject <issue-id> --reason "needs changes"
  ```

---

## 5) End-of-Session Safety

Before ending a session, verify no missing handoffs:

```bash
td check-handoff
```

If it fails, add handoff(s) first.

Then check dashboard:

```bash
td status
```

---

## 6) Multi-Issue Work Sessions (Optional)

For parallel work streams, use `td ws`:

```bash
td ws start "name"
td ws tag <issue-id>
# ...work...
td ws handoff
```

---

## 7) Repo Policy for This Project

1. Planning is done in `td` (epics/tasks/deps/status)
2. No “stealth implementation” without an active task in progress
3. Keep PRD and logbook updated when decisions change:
   - `docs/PRD.md`
   - `docs/LOGBOOK.md`
4. Prefer small, reviewable increments
5. Every completed task should be review-submitted through td

---

## 8) Quick Command Cheatsheet

```bash
# discover work
td ready
td next

# inspect
td show <id>
td comments <id>

# plan
td epic create "..."
td task create "..." --parent <epic-id> --priority P1

# execute
td start <id>
td focus <id>
td log "..."
td comment <id> "..."
td handoff <id> --done "..." --remaining "..."
td review <id> --reason "..."
td approve <id> --reason "..."
```
