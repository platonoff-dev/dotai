---
name: vet-ticket
description: For a task the user was assigned that was probably written by someone's AI agent and can't be taken at face value. Use it to decide whether to implement, rewrite, cancel, or ask the author. Use when the user shares a task in any form (tracker issue, pasted text, Slack thread, doc) and asks to vet it, check whether it holds, or make it agent-ready. Also use when they call it AI slop, half wrong, or confusing.
---

# Vet a ticket

AI-written tickets read confidently whether they are right or not. They often mix a real symptom with an invented cause, cite functions that don't exist, and propose a fix for the wrong problem. Treat the ticket as **claims from an unreliable narrator**: its prose is never evidence for itself, and each claim stands or falls on what you find in the code.

## 1. Gather

Get the whole task from wherever it lives:

- a tracker issue (Jira, GitHub, Linear…), through whatever tool is connected
- a pasted description
- a Slack thread
- a doc

If you only have a link and no tool can read it, ask the user to paste the task. Collect:

- the discussion, not just the description
- who wrote it and when
- any commit, version, or log it cites

Check what changed since the task was written: `git log` in the area it names, from its date on. These tickets are often written against code that has since moved, or that someone has already fixed. If the task lives in a tracker you can search, look for duplicates **by concept**, not by its wording: the author's agent may have filed the same problem in different words.

## 2. Split into claims

Before checking anything, list every claim as a numbered, one-line restatement in your own words. Doing this first stops the ticket's narrative from steering your investigation. If you can't restate a claim, it is vague, and that is a finding.

Kinds of claim to look for:

- **Symptom**: X happens under Y.
- **Cause**: because of Z.
- **Location**: in function or file F.
- **Scope**: also affects W.
- **Fix**: change it like this.
- **Implied requirement**: what "done" would mean, even if unstated.

## 3. Verify each claim on its own

Evidence is:

- a code path you read at HEAD
- a command or test you ran
- a log line

Give each claim one verdict:

- **holds**
- **doesn't hold**
- **inconclusive**: name what would settle it

Reproduce when it's cheap; otherwise trace the code path. If a claim is half right, split it in two rather than adjusting it until it becomes true. Otherwise a wrong part slips through on the back of a right one.

Watch for the usual failure modes:

- names or line numbers that don't exist in this version
- a plausible cause with no path from it to the symptom
- scope ("affects all X") with nothing behind it
- work that is already done

## 4. Judge the proposed fix separately

The problem can be real while the fix is wrong, so the fix gets its own review, as you would give an outside reviewer's suggestion. Ask:

- **Cause**: does it target the *verified* cause, or only the ticket's claimed cause?
- **Breakage**: what would it break? Check callers, tests, and supported versions.
- **History**: why is the code this way now? `git log` or `blame` on those lines often shows a deliberate reason.
- **Need**: is the thing being "fixed properly" used at all? If nothing calls it, removing it may be the real fix.
- **Scope**: does it bundle a refactor the problem doesn't need?

Verdict: **accept**, **adjust**, **replace**, or **drop**. If you replace it, describe the new direction as behavior, and leave the implementation to whoever builds it.

## 5. Sort the open questions

Facts are your job: don't ask the user anything you could look up. Decisions belong to the user; put them as a `grilling`-style round. Questions only the author can answer go to the author. These are usually intent, where they saw the problem, customer context, and priority.

## 6. Report and recommend one outcome

Show:

- a table: `# | claim | verdict | evidence`
- the fix verdict
- one recommended outcome, with its draft

The outcomes:

- **Spec for agent**: the problem holds and the direction is clear. Write the brief below.
- **Rewrite the task**: the problem is real, but the framing, scope, or fix is wrong. Draft a replacement description. If the task bundles unrelated problems, split it.
- **Cancel**: the core claims don't hold, or it is already fixed or a duplicate. Draft a short note that cites the evidence.
- **Ask the author**: only the author can unblock it. Draft a message with two parts:
  - **Established so far**: the verified claims, so the work isn't lost.
  - **Need from you**: specific, answerable questions; "please clarify" gets nothing back.

The user sends these under their own name to a colleague, so write them in the user's voice. Write nothing back to the task's source until they approve the exact text.

## Agent brief

The brief is the contract; the original task is only context. The implementing agent will probably read the original too, so the brief has to say which parts of it are wrong.

```markdown
**Summary:** one line
**Current behavior (verified):** what happens now, plus the evidence
**Desired behavior:** what should happen, including edge and error cases
**Key interfaces:** types, functions, config shapes to change, named not located
**Acceptance criteria:**
- [ ] independently testable criterion
**Out of scope:** what not to touch
**Do not follow from the original task:** each disproven claim or rejected fix, one line each
```

Describe behavior, not steps, and name interfaces rather than file paths or line numbers. The agent explores the code fresh, and paths go stale before it picks the task up.
