---
name: sync-upstream
description: Evaluate and selectively merge new commits from the upstream github.com/Wei-Shaw/sub2api project into this internal Nexus Relay fork. Use when the user wants to sync upstream, merge upstream changes, pull in upstream fixes, check what is new upstream, or review upstream commits for cherry-picking.
---

# Sync Upstream

Evaluate and selectively merge new commits from the upstream `github.com/Wei-Shaw/sub2api` project
into this internal fork (Nexus Relay).

**Before starting:** Read [references/divergence-rules.md](references/divergence-rules.md) for
classification rules and [references/skip-log.md](references/skip-log.md) for commits already
reviewed and skipped.

---

## Step 1 — Fetch

```bash
git fetch upstream
```

If `upstream` is missing, add it first: `git remote add upstream https://github.com/Wei-Shaw/sub2api.git`

## Step 2 — List new upstream commits

```bash
git log upstream/main --oneline --not origin/main
```

If the output is empty, upstream is already in sync — report this and stop.

## Step 3 — Classify each commit

For each commit SHA, inspect what it touches:

```bash
git show <sha> --stat
git show <sha> -p   # if stat alone is insufficient
```

Apply the rules from `references/divergence-rules.md`:

| Result | Condition |
|--------|-----------|
| **TAKE** | Only touches TAKE areas (gateway, AI adapters, shared bug fixes) |
| **SKIP** | Only touches SKIP areas (payment, subscriptions, branding, sponsors) |
| **REVIEW** | Touches REVIEW areas (schema, new services, deps, CI) or is a mixed commit |

Check `references/skip-log.md` — if a SHA is already logged there, do not re-evaluate it.

## Step 4 — Present the plan

Before taking any action, output a summary table and ask the user to confirm:

```
| SHA      | Message                        | Classification | Reason          |
|----------|-------------------------------|----------------|-----------------|
| abc12345 | fix(openai): stream failover  | TAKE           | gateway fix     |
| def67890 | fix/subscription-direct-pay   | SKIP           | payment flow    |
| ghi11111 | feat: new ent schema column   | REVIEW         | schema change   |
```

List TAKE commits in chronological order (oldest first) so cherry-picks apply cleanly.

## Step 5 — Execute TAKE commits

After user confirmation, create a merge branch and cherry-pick:

```bash
git checkout -b merge/upstream-YYYYMMDD
git cherry-pick <sha1> <sha2> ...   # oldest → newest
```

**Conflict resolution:** For any conflict in a KEEP_INTERNAL path (see `references/divergence-rules.md`),
always keep our version:

```bash
git checkout HEAD -- <path>
git add <path>
git cherry-pick --continue
```

For conflicts outside KEEP_INTERNAL paths, resolve semantically — understand both sides before choosing.

## Step 6 — Handle REVIEW commits

For each REVIEW commit, show the full diff and explain:
- What the upstream change does
- Whether it conflicts with any SKIP rule or KEEP_INTERNAL path
- A recommendation (take / adapt / skip) with reasoning

Wait for the user's decision before proceeding.

## Step 7 — Log SKIP commits

For every commit classified as SKIP (new ones only — not already in `references/skip-log.md`),
append a row to `references/skip-log.md`:

```
| <sha8> | <YYYY-MM-DD> | <one-line commit message> | <reason category from references/divergence-rules.md> |
```

## Step 8 — Verify and create PR

Run the test suite to confirm nothing is broken:

```bash
cd backend && go test ./...
```

Then push and open a PR:

- Branch: `merge/upstream-YYYYMMDD`
- Title: `merge: upstream sync YYYY-MM-DD`
- Body should include:
  - How many commits evaluated / taken / skipped / deferred for review
  - Short list of what the TAKE commits bring
  - Any conflicts resolved and how
