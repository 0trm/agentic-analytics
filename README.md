# agentic-analytics

One person runs the whole analytics function of a startup: intake, tracking, warehouse, QA,
delivered reports. This repo is the system that makes that workable - an agent harness in which
AI does the work while the human sets direction and holds the quality bar.

The files are the production ones, sanitized. The company is "a startup", ids and event names are
placeholders; the structure, skills, agents and rules are exactly what runs every day.

**Outline**

1. [Where analytics sits in an org](#where-analytics-sits-in-an-org) - the constraint this solves
2. [Three ways to engage AI](#three-ways-to-engage-ai) - the move: from doing the work to directing it
3. [What the system optimizes for](#what-the-system-optimizes-for) - the objective, and its two bounds
4. [The system](#the-system) - one repo, one pipeline, one compounding loop
5. [What is here, and what stayed home](#what-is-here-and-what-stayed-home) - the boundary of this repo

## Where analytics sits in an org

Data teams get organized three ways, and each buys one thing by giving up another:

| Model | Wins | Loses |
|---|---|---|
| **Centralized** - one team serves everyone | standards, depth, one platform | a queue, and distance from business context |
| **Embedded** - analysts inside each function | context, speed | silos, and every team reinventing the stack |
| **Hybrid** - central platform, embedded analysts | both, in theory | headcount and coordination it takes to run |

A one-person function is the centralized model at its most extreme: one set of standards, and one
brain as the queue. Its two classic failure modes - the backlog, and the distance from context -
are exactly what this system attacks. Agents multiply throughput past what one pair of hands can
do, and a clarification loop at intake closes the context gap. The result behaves like a hybrid
team, without the headcount.

## Three ways to engage AI

| Mode | What happens | Best when |
|---|---|---|
| **Automation** | AI executes a task you define (summarize, draft, plan) | You know exactly what you want |
| **Augmentation** | You and AI think through a task together | The solution is not straightforward and you need room to explore |
| **Agency** | You configure AI to act on your behalf: director, not scriptwriter | Routine interactions can run without you |

No mode is better, and one project may use all three. But an analytics function has enough
recurring shape - requests arrive, get scoped, queried, checked, delivered - that the third mode
pays off, *if* you build rails. Everything below is the rails.

## What the system optimizes for

One objective: **minimize the time from raw data to a trusted insight, on the question that
matters most right now.** Two bounds come before speed:

- **Direction.** Humans decide what is worth working on. Speed in the wrong direction is waste.
- **Accuracy.** A hard constraint, not a trade-off. Fast but wrong is a failure, not a near miss.

Within the right direction and under the accuracy bar, speed is what gets maximized: agents
supply the speed, the human sets the direction and the bar. The metric is median time from
request to delivery, guarded by rework iterations per task - rework climbing means the work is
pointed wrong or the bar is being missed, and either one makes a faster median meaningless.

Every structural choice below traces back to one of those three. If a mechanism seems fussy, ask
which bound it enforces.

## The system

A harness is three things: **model + tools + skills**. The model is rented (here: Claude, through
Claude Code). Tools are what it can touch - a shell, BigQuery, a browser, the task tracker.
Skills are written procedures it can be handed. Nothing below required custom infrastructure; it
is markdown files, one shell script, and a folder convention, arranged deliberately.

### One repo is the whole system

Knowledge and the tooling that operates on it live in one clone. Open the repo in Claude Code and
the session assembles its own context - nothing is pasted in, nothing lives in one person's head:

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

`CLAUDE.md` is deliberately small, because everything in it costs context on every session. What
earns a place there is the **Traps** section: each entry is a way this specific stack returns a
*plausible number that is wrong* - an export that lags two days, a form event that over-fires 8x,
events that died silently and still chart as zeros. Generic models know SQL; they do not know
your park of silent errors. One line each, loaded always, is the cheapest accuracy mechanism
that exists.

### The pipeline

Every request runs through five phases. Trivial asks are handled on the spot but still logged;
everything else is structured and reviewed against the goal before it ships:

![The analytics pipeline: five phases across stakeholder, analyst and agent lanes, with four feedback loops](assets/pipeline.png)

The four dashed loops are the accuracy mechanism, ordered by cost:

1. **Clarify at intake.** [`/clarify`](.claude/skills/clarify/SKILL.md) checks what the data can
   actually answer and drafts the questions; the analyst approves and sends. A correction here is
   free; the same correction after delivery costs the whole task.
2. **Iterate inside the session.** Work runs against a written definition of done
   ([`/cupify`](.claude/skills/cupify/SKILL.md) produces it), with schema hunts delegated to the
   [`bq-explore`](.claude/agents/bq-explore.md) agent so exploration noise never crowds out
   reasoning.
3. **The QA gate.** The [`qa`](.claude/agents/qa.md) agent re-derives every result from the brief
   by its own route before a human sees it - two routes agreeing is evidence; one route re-read
   twice is not. For instrumentation, [`tracking-qa`](.claude/agents/tracking-qa.md) drives a
   real browser against the spec instead.
4. **Human review, last.** Because it lands on work that already passed QA, it is a direction and
   framing check, not a correctness hunt.

The loop this buys out of is the expensive one: a stakeholder bouncing a delivered answer.
Delivery itself runs through [`/report`](.claude/skills/report/SKILL.md), and tracking work runs
its own define-spec-build-QA-ship flow through
[`/tracking-spec`](.claude/skills/tracking-spec/SKILL.md) - same idea, different contract.

### The compounding loop

The phases above take one request from intake to delivery. The fifth phase serves the next
request instead of the current one:

![The memory loop: capture into private memory, weekly promote into team docs](assets/memory-loop.png)

[`/capture`](.claude/skills/capture/SKILL.md) runs before a task closes and routes what the
session *discovered* by tier: durable facts toward `docs/`, procedure corrections into the
relevant skill, and only volatile state into private memory - which loads every session, so it is
kept ruthlessly small. [`/promote`](.claude/skills/promote/SKILL.md) runs weekly and headless: it
verifies each candidate fact still holds, folds it into `docs/`, and opens a PR. After the merge
the memory copy is deleted - two copies of one fact drift. The PR is also the privacy boundary:
the only route from one person's private memory into the shared repo, and it passes human review.

Each week's sessions start from a richer baseline than the last. That is the compounding.

## What is here, and what stayed home

![Repo map: what lives where and why](assets/repo-map.png)

The harness in this repo is complete and real: `CLAUDE.md`, the six skills, the three agents, the
hook, the settings. Every skill stops at a decision boundary - drafts but never sends, builds but
never deploys without a checkpoint - because the judgment calls are the part that stays human.
Three things deliberately stayed home: the `docs/` tree (the startup's data dictionary; the map
shows its shape), credentials (the [settings](.claude/settings.json) deny even *reading* key
files - an agent that cannot read a key cannot leak it), and private memory (local to each
machine, bridged only by `/promote`).

The honest caveat, back at the org question this started with: the harness did not remove the
analyst. It moved the analyst up a level - from writing every query to directing the system that
writes them and auditing what it returns. That is what "agency" mode means, and the rails are
what make it safe.

---

MIT licensed. Built with [Claude Code](https://claude.com/claude-code); the pattern transfers to
any harness with files, tools and subagents.
