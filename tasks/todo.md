# Current: `np --clone` — Clone support for `np`

> Project: p (project directory jumper and scaffolder)
> Full plan: tasks/roadmap.md

**Goal**: Add `--clone URL` flag to `np` so users can clone existing repos into the project directory structure.

---

### Implementation
- [x] Add `_np_name_from_url` helper to both p.bash and p.zsh
- [x] Update help text with `--clone URL` option
- [x] Add `--clone` to arg parsing in both files
- [x] Derive name from clone URL when name omitted
- [x] Interactive clone prompt in interactive mode
- [x] Show clone URL in confirmation display
- [x] Conditional clone vs init logic
- [x] Add 8 tests covering clone functionality

### Verification
- [x] All 143 tests pass (bash variant)
- [ ] Manual test: `np --clone <url> --category <cat>` clones correctly
- [ ] Manual test: interactive flow with clone prompt works
