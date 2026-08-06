# agentic-analytics-for-startups

One person runs the whole analytics function of a startup: intake, tracking, warehouse, QA,
delivered reports. This repo is the harness that makes that workable - AI does the work, the human
sets direction and holds the bar.

The files are the production ones, sanitized: the company is a startup, ids and event names are
placeholders. The knowledge and delivery trees - `docs/`, `src/`, `reporting/` - hold company data
and stayed behind. What is published is the harness that operates them.

![The work root: what this repo publishes](assets/repo-map.png)

## The constraint

Data teams get organized three ways, and each buys one thing by giving up another:

| Model | Wins | Loses |
|---|---|---|
| **Centralized** - one team serves everyone | standards, depth, one platform | a queue, and distance from business context |
| **Embedded** - analysts inside each function | context, speed | silos, and every team reinventing the stack |
| **Hybrid** - central platform, embedded analysts | both, in theory | headcount and coordination it takes to run |

A one-person function is the centralized model at its extreme: one set of standards, one brain as
the queue. Its two failure modes are the backlog and the distance from context. Agents take the
throughput-bound work off the one pair of hands; a clarification loop at intake closes the context
gap. Hybrid behaviour, no headcount.

## The objective

**Minimize the time from raw data to a trusted insight, on the question that matters most right
now.** Two bounds come before speed:

- **Direction.** Humans decide what is worth working on. Speed in the wrong direction is waste.
- **Accuracy.** A constraint, not a trade-off. Fast but wrong is a failure, not a near miss.

Inside those bounds, maximize speed. The metric is median time from request to delivery, guarded by
rework iterations per task; the task tracker supplies both, since every request enters it at intake
and leaves at delivery. Rework climbing means the work is pointed wrong or the bar is being missed,
and either one makes a faster median meaningless.

There are three ways to engage AI: automation, where it executes a task you define; augmentation,
where you think through one together; and agency, where you configure it to act on your behalf. An
analytics function has enough recurring shape - requests arrive, get scoped, queried, checked,
delivered - that the third pays off, *if* you build rails. The rest of this is the rails.

## The harness

A harness is three things: **model + tools + skills**. The model is rented (here: Claude, through
Claude Code). Tools are what it can touch. Skills are written procedures it can be handed. No
custom infrastructure: markdown files, one shell script, and a folder convention.

The stack underneath is an ordinary one, and the harness is shaped by it:

| Layer | Tool | How the agent reaches it |
|---|---|---|
| Collection | GA4, Google Tag Manager | Python + `google-auth` scripts in `src/gtm-api/` |
| Warehouse | BigQuery, EU multi-region | `bq` CLI, read verbs allowlisted in [`settings.json`](.claude/settings.json) |
| Analysis | Python, Jupyter `# %%` scripts | shell, through `uv run` |
| Delivery | [Evidence](https://evidence.dev) on Cloudflare Pages | shell: `npm run build`, then `./deploy.sh` |
| Intake and tasks | ClickUp | MCP server |
| Verification | Chrome | Claude in Chrome, driven by [`tracking-qa`](.claude/agents/tracking-qa.md) |
| Versioning | git, GitHub | `git` and `gh` CLIs; a PR when the diff should be reviewed |

Every surface is reachable as a CLI or an MCP server, which is what makes unattended agent work
possible at all. Swap the vendors and the harness holds.

Two rails are enforced by the harness rather than written down as instructions. A [session-start
hook](.claude/hooks/data-freshness.sh) prints the newest finalized export shard, so no session
assumes data that does not exist yet. [`settings.json`](.claude/settings.json) allowlists a narrow
set of routine commands while denying `bq rm`/`bq cp` and reads of the credential paths outright.

![The harness: model plus tools plus skills, on two rails the harness enforces itself](assets/harness.png)

### One repo is the whole system

Knowledge and the tooling that operates on it live in one clone. Open the repo in Claude Code and
the session assembles its own context:

![What a session knows: the five stores and when each loads](assets/session-context.png)

The design rule: **one fact, one home, chosen by how often it is needed and how fast it goes
stale.**

| Store | Loaded | Holds | Goes stale |
|---|---|---|---|
| [`CLAUDE.md`](CLAUDE.md) | every session | the repo map, and the traps | slowly |
| [`.claude/skills/`](.claude/skills/) | name only, body on invoke | procedures with steps | slowly |
| `docs/` | on demand | durable domain truth, team-readable | slowly |
| private memory | index every session | live outages, in-flight decisions | fast |
| `wip/` | never committed | per-task scratch | immediately |

`CLAUDE.md` is small on purpose, because everything in it costs context on every session. What
earns a place there is the **Traps** section: each entry is a way this stack returns a *plausible
number that is wrong*. A derived table that lags two days. A form event that over-fires 8x. Events
that died silently and still chart as zeros. All of them are properties of the stack above. A
generic model knows SQL and it knows GA4; it does not know *this* park of silent errors. One line
each, loaded always, is the cheapest accuracy mechanism in this system.

### The pipeline

Every request runs through five phases. Trivial asks are handled on the spot but still logged;
everything else is structured and reviewed against the goal before it ships:

![The analytics pipeline: five phases across stakeholder, analyst and agent lanes, with four feedback loops](assets/pipeline.png)

Four dashed loops, each cheaper than the one after it:

1. **Sharpen the ask, at intake.** [`/clarify`](.claude/skills/clarify/SKILL.md) checks what the
   data can actually answer and drafts the questions - including the one that collapses the rest:
   what decision will the answer change. A correction here is free.
2. **A QA FAIL returns to the session.** The [`qa`](.claude/agents/qa.md) agent re-derives every
   result from the brief by its own route before a human sees it; two routes agreeing is evidence,
   one route re-read twice is not. For instrumentation,
   [`tracking-qa`](.claude/agents/tracking-qa.md) drives a real browser against the spec instead. A
   FAIL costs a session iteration, not a delivery.
3. **Human review reframes, last.** It lands on work that already passed QA, so it is a direction
   and framing check, not a correctness hunt.
4. **Rework after delivery.** A stakeholder bouncing a delivered answer costs the whole task. The
   three loops above exist to starve it.

Between the loops, work runs against a written definition of done
([`/cupify`](.claude/skills/cupify/SKILL.md) produces it, carrying the decision the answer serves),
with schema hunts delegated to the [`bq-explore`](.claude/agents/bq-explore.md) agent so
exploration noise never crowds out reasoning. Delivery runs through
[`/report`](.claude/skills/report/SKILL.md). Tracking runs its own define-spec-build-QA-ship flow
through [`/tracking-spec`](.claude/skills/tracking-spec/SKILL.md), which stops at a KPI gate: a
proposed metric must feed a KPI row or a named decision, or it goes back to be sharpened or
dropped.

### The compounding loop

The fifth phase serves the next request instead of the current one:

![The memory loop: capture into private memory, weekly promote into team docs](assets/memory-loop.png)

[`/capture`](.claude/skills/capture/SKILL.md) runs before a task closes and routes what the session
*discovered* by tier: durable facts toward `docs/`, procedure corrections into the relevant skill,
and only volatile state into private memory - which loads every session, so it stays small.
[`/promote`](.claude/skills/promote/SKILL.md) runs weekly and headless: it verifies each candidate
fact still holds, folds it into `docs/`, and opens a PR. After the merge the memory copy is
deleted; two copies of one fact drift. The PR is also the privacy boundary, the only route from one
person's private memory into the shared repo, and it passes human review.

Each week's sessions start from a richer baseline than the last. That is the compounding.

---

MIT licensed. Built with [Claude Code](https://claude.com/claude-code); the pattern transfers to
any harness with files, tools and subagents.
