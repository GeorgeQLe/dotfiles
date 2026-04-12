# Current: P_NP_HOOK — Post-Creation Hook for `np`

> Project: p (project directory jumper and scaffolder)
> Full plan: tasks/roadmap.md

**Goal**: Add a `P_NP_HOOK` extension point so users can run custom logic after `np` creates a project.

---

### Implementation
- [x] Add hook call to `np()` in p.bash and p.zsh (after `_p_record_visit`, before cache invalidation)
- [x] Add 4 hook tests to p.bats (correct args, failure warns, unset skips, non-executable skips)
- [x] Document `P_NP_HOOK` in README.md (Hooks section + env var table)
- [x] Create `scripts/np-hook` in lexcorp repo (shell entry point with interactive prompts)
- [x] Create `scripts/add-product.ts` in lexcorp repo (TS worker: edits seed-data.ts + upserts DB)

### Verification
- [x] All 135 tests pass (including 4 new hook tests)
- [ ] Manual test: set P_NP_HOOK, run `np`, verify hook fires and prompts appear
- [ ] Manual test: verify seed-data.ts has new entry after hook runs
- [ ] Manual test: verify database has new product after hook runs

---

**Implementation plan for Steps 3.2-3.4:**

All three fixes are small and independent. Implement them together.

**Step 3.2: Last-category guard in `_pconfig_remove`**
- p.bash (line ~1165): after the `(( ${#_p_categories[@]} == 0 ))` check, add:
  ```bash
  if (( ${#_p_categories[@]} == 1 )); then
    echo "Cannot remove last category."
    return 1
  fi
  ```
- p.zsh: same guard (same line range, same syntax works)

**Step 3.3: Optimize `_p_classify_dirs` — parent-stack approach**
- p.bash (lines 32-59): replace inner loop with a stack of standalone parents
  - After sorting, maintain an array of "active parents" (standalone dirs)
  - For each dir, only check if it starts with the most recent standalone entry (not all previous entries)
  - Since dirs are sorted, a child always comes right after its parent
  - Pop stack entries that are no longer ancestors of the current dir
  ```bash
  local stack=()
  for (( i=0; i<${#dirs_arr[@]}; i++ )); do
    d="${dirs_arr[$i]}"
    # Pop stack entries that are not ancestors of d
    while (( ${#stack[@]} > 0 )) && [[ "$d" != "${stack[-1]}/"* ]]; do
      unset 'stack[-1]'
    done
    if (( ${#stack[@]} > 0 )); then
      echo "P $d"
    else
      echo "S $d"
      stack+=("$d")
    fi
  done
  ```
- p.zsh: same logic with 1-based indexing and `${stack[-1]}` → `${stack[-1]}` (same in zsh), `unset 'stack[-1]'` → `stack[-1]=(); stack=(${stack[@]})` or use shift/pop

**Step 3.4: Fix `_p_doctor` cache reporting**
- p.bash (line ~206): change the cache reporting block to check `-s` (non-empty):
  ```bash
  if [[ -s "$cfile" ]]; then
    # ... compute age ...
    echo "  ✓ $cname cache: valid ($age_min min old)"
  else
    echo "  ⚠ $cname cache: present (empty)"
  fi
  ```
  Keep the outer `[[ -f "$cfile" ]]` check, nest `-s` inside it.
- p.zsh: same fix

**Verification:**
- `bats tests/p.bats` — all 134 tests should pass (0 failures)
- `TEST_SHELL=zsh bats tests/p.bats` — all pass
- `shellcheck -s bash p.bash` — clean
