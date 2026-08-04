---
name: promote
description: Weekly ritual that graduates durable facts out of private memory into the team-visible docs/, as a reviewable pull request. Use once a week, or when memory has accumulated facts that teammates would benefit from. This is the boundary gate between private state and shared knowledge.
argument-hint: [optional scope, e.g. "bigquery only"; omit to review all of memory]
user-invocable: true
---

# promote

The second half of the pipeline's compounding phase (step 13 of its full numbering), and the
only mechanism by which private knowledge becomes team knowledge. Run it weekly.

Memory is fast and private. `docs/` is durable, reviewable, and read by teammates. Facts that have
proven themselves in memory belong in `docs/`, and the pull request is the moment that transition
is made deliberately rather than by accident.

## 1 - Survey memory

Read the memory index, then read in full every entry that is a candidate. Do not judge from the
index line - it is a hook, not the fact.

An entry is ready to promote when **all** of these hold:

- **Durable.** It will still be true in six months. Live outages and in-flight decisions are not
  ready; they may never be.
- **Team-relevant.** A teammate hitting the same surface would need it. Personal working
  preferences never promote.
- **Verified.** It has survived contact with reality, not just been asserted once. If you cannot
  confirm it still holds, verify it now or leave it.
- **Safe.** No credentials, tokens, key paths, passwords or personal detail. This repo is
  company-visible. When in doubt it stays in memory.

## 2 - Verify before promoting

Promoting a stale fact into `docs/` is worse than leaving it in memory, because the team will
trust it. For each candidate:

- If it names a file or path, confirm it exists.
- If it describes data behaviour, re-check it against BigQuery. One cheap query.
- If it describes a platform config, confirm in GTM or GA4.

Anything that fails verification gets **corrected or deleted**, not promoted.

## 3 - Find its home

Fold into an existing file wherever possible. A new file is a last resort - the docs tree is
already navigable and every new file makes it less so.

| Kind of fact | Home |
|---|---|
| Warehouse layout, table behaviour, query gotcha | `docs/config/bigquery.md` |
| Event naming, controlled vocabulary, DOM hooks | `docs/config/conventions.md` |
| GA4 property config, custom dimensions | `docs/config/ga4.md` |
| GTM container, tags, triggers | `docs/config/gtm.md` |
| What an event means and which params it carries | `docs/dev/tracking-plan/<event>.md` |
| A metric definition | `docs/business/key-performance-indicators.md` |
| A cross-cutting rule such as spam | `docs/custom/` |
| How a dashboard is built and read | `docs/dashboards/` |
| How work flows end to end | `docs/sop/` |

Match the house style of the file you are editing: same heading depth, same table conventions,
same tone. A promoted fact should be indistinguishable from the surrounding text. Rewrite the
memory phrasing - memory is written for one reader, docs are written for the team.

## 4 - Open the pull request

```bash
git -C . pull --ff-only origin main        # always pull before branching
git checkout -b promote/<yyyy-mm-dd>
# apply the edits
git add docs/
git commit
gh pr create
```

Pull `main` first, every time, without exception. It avoids conflicts and avoids resurrecting
files that were deleted directly on `main`.

The PR body states, per promoted fact: what it is, where it came from, and how it was verified in
step 2. A reviewer should be able to check the claim without rerunning the investigation.

Keep the PR small. One week of promotions is a handful of facts. A fifty-file PR is not a
promotion, it is a migration, and it will not be reviewed properly.

## 5 - Delete the memory copies

**Only after the PR merges.** Then remove each promoted entry from memory and its line from the
index.

This step is not optional. Leaving both copies is exactly the duplication this architecture was
built to remove: two records of one fact, no sync, and whichever one is edited makes the other a
lie. The `docs/` copy is now the source of truth.

## 6 - Report

- What was promoted, and into which file.
- How each fact was verified.
- What was deliberately held back, and why: not durable, not team-relevant, unverifiable, or
  sensitive.
- What was deleted from memory outright rather than promoted.
- The memory index count before and after.
