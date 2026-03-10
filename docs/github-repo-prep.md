# GitHub Repository Prep (Local, No Upload Yet)

This checklist prepares the repository for publishing **without pushing/uploading anything yet**.

## Prepared locally

- ✅ Project structure stabilized
- ✅ Core implementation complete and test-verified
- ✅ `.github/workflows/ci.yml` present
- ✅ README upgraded with product-quality structure
- ✅ Docs and ADR baseline in place

## Next GitHub-only actions (deferred by request)

When you give the go-ahead to publish:

1. Create remote repository (`helmi/acal-cli` or chosen org)
2. Push local history
3. Configure branch protections
   - require PR review
   - require status checks
   - block force pushes on protected branches
4. Add default labels/milestones
5. Enable Discussions/Issues (optional)
6. Configure required secrets for release/signing workflows

## Notes

- No remote creation, push, release, or upload has been performed.
- This repo is intentionally in a local-prepared state.
