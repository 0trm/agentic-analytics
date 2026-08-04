---
name: clarify
description: Draft the clarifying questions for an incoming analytics request, grounded in what the data can actually answer. Use when a stakeholder ask arrives free-form or through the intake form and is not yet precise enough to execute. Produces a short list of questions for the analyst to approve and send, plus the assumptions it would use if no answer comes back.
argument-hint: [the request as it arrived - paste, task URL, or a description; omit to use the latest assistant response]
user-invocable: true
---

# clarify

The intake phase of the analytics pipeline - step 4 of its full numbering. A request has
arrived and is not yet precise enough to execute. Draft the questions that would make it
executable.

The point is not to interrogate the stakeholder. It is to find the small number of ambiguities
that would change the answer, ask only those, and state what you would assume otherwise so the
work can start without waiting.

## 1 - Read the request

The request is in `$ARGUMENTS`, or a task to read from the tracker, or the most recent assistant
response. Restate it in one sentence before going further. If your restatement already feels
precise, say so - some requests need no clarification and the skill should say that rather than
manufacture questions.

## 2 - Check what the data can answer

Before asking anything, find out whether the question is answerable as posed. This is what makes
the questions specific rather than generic.

- Read the relevant page in `docs/dev/tracking-plan/` for the events involved. What params exist,
  what surfaces they fire on, when the event was introduced.
- Check `docs/config/conventions.md` for the controlled vocabulary. A stakeholder saying
  "category pages" may mean `source_surface = 'category'`, or the path prefix, or both.
- Check whether the event is alive. The current dead list, with dates, is the Zero-is-not-absence
  trap in `CLAUDE.md`. If the request spans a dead window, that is not a clarifying question, it
  is a finding to lead with.
- Check the window is available. The newest finalized shard is whatever the session-start
  freshness line reported - never assume - and history starts where the export starts. "Last 12
  months" may not exist.

## 3 - Draft the questions

Aim for **two to four**. More than four means the request needs a conversation, not a form.

Ask only about things that change the work:

- **The decision.** What will change based on the answer. Ask it first: the answer often
  collapses the rest of the questions.
- **Metric definition.** Sessions or events? Users or sessions? `form_submit` over-fires ~8x, so
  for anything form-shaped this is always worth pinning.
- **Scope.** Which surfaces, which forms, which pages. Map their words onto the real vocabulary
  and offer the mapping, do not make them guess it.
- **Window and comparison.** Against what baseline? Prior period, prior year, or a launch date?

Do not ask about things you can decide: output format, whether to exclude spam (always yes),
which table to read, how to break it down when the request implies it.

Each question should be answerable in a sentence. Offer the likely options where you can - a
stakeholder picks from two options faster than they compose an answer.

## 4 - State the fallback assumptions

For every question, write the assumption you would proceed with if no answer arrives. This is the
part that keeps the pipeline moving:

```
If I don't hear back I'll assume: distinct sessions, last complete 8 weeks vs the 8 before,
spam excluded, contact forms only.
```

Often the stakeholder replies "that's fine" and the whole exchange costs one message.

## 5 - Output

Print, in this order:

1. **The request, restated** in one sentence.
2. **What I already know** - anything from the docs that reframes the ask, especially a dead
   event or an unavailable window. Lead with this if it is significant; it may make the questions
   moot.
3. **Questions** - the numbered list, ready to send as-is. Plain language, no analytics jargon.
   The stakeholder should not need to know what `source_surface` is.
4. **Fallback assumptions** - the block above.

Copy the questions to the clipboard with `pbcopy` so they can go straight into chat or email.

Then stop. **Do not send anything.** The analyst approves and sends. This skill drafts.
