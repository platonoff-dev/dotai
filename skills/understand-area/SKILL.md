---
name: understand-area
description: Build an evidence-backed map of an unfamiliar part of a codebase or system - what it does, who uses it, how it works end to end, and why it ended up this way - so the user can review changes there or plan work in it. Use when the user is new to a module, service, or flow and says "what does this do", "who uses this", "why is it like this", "explain this area", "map this", "onboard me", or needs context before reviewing a PR/MR or planning a change in code they don't know. Use it even when they only paste a path, service name, or PR and say it's unfamiliar. Not for reviewing a diff in code they already know (that is a code review) or a one-line question about a single function.
---

# Understand an area

The user needs to judge work in code they don't know: review an agent's diff, or decide on a plan. They don't need a tour. They need a map they can trust: every claim traceable to code, history, or runtime evidence, and the gaps marked as gaps.

## 1. Scope

Pin down three things before reading code:

- **The area**: a module, service, endpoint, table, or flow. If it is fuzzy, find its edges first (step 2, "Boundaries") and confirm them with the user.
- **The use**: reviewing a PR/MR, planning a change, debugging. This decides depth: a review needs the flows the diff touches; a plan needs the boundaries and constraints.
- **Pointers**: links, tickets, paths, and people the user gave. Keep them verbatim.
- **Sources**: find out what this environment has; don't assume it.
  - the code host: `git remote -v`
  - the tracker: ticket IDs in `git log`, links in the README
  - where docs live: in the repo, or a wiki
  - which CLIs and connected tools reach these places
  Use whatever is there. List anything you couldn't reach under **Not covered**, so its absence is visible.

Turn the need into 2-6 **descriptive** questions: "how does X reach Y today", "what reads table Z". Strip the planned change out of them. A question like "how would we add X" bends the research toward a design before the code has been seen.

## 2. Investigate through four lenses

**Boundaries — what it is.** Find the entry points: routes, CLI commands, jobs, cron, queue consumers, exported API. Find what it owns: tables, queues, caches, config, feature flags. Find what it calls out to. Show responsibility as an annotated file tree.

**Consumers — who uses it.** This is the lens the code alone hides, so look outward:

- in-repo callers of its public surface, and the code that produces the events it consumes
- other repos: use the code host's search (GitHub, GitLab, Sourcegraph), or grep across local clones. Hosted search usually covers only default branches, and none of these match routes or names built from strings. Say what the search covered: which repos, which branches, and exact or fuzzy matching.
- other readers of its tables, topics, and endpoints: other services, analytics, cron jobs
- deploy and infra config: what runs it, how often, and with what flags
- runtime evidence, if the user has access (logs, metrics, traces, dashboards); only this proves something is used in production

"No caller found" is a scoped fact: name where you looked. It is never proof that nothing uses it.

**Mechanics — how it works.** Trace the 1-3 flows the use depends on:

1. **Entry**: what starts it.
2. **Flow**: the call chain, and the data that changes at each step.
3. **Hand-offs**: what it passes to, or receives from, other parts.
4. **Failure paths**: errors, retries, timeouts, partial writes.
5. **Tests**: unit, integration, or e2e, with file locations. If a flow has no tests, say so. A reviewer needs to know whether a change here would be caught.

**Follow the calls.** Whether a step is safe usually depends on what the code it calls actually does, and the call site doesn't show that. Don't trust a name: open `checkQuota()` and confirm that it checks a quota. Read through each branch it can exit by, including early returns and error branches. A guarantee that holds only on the happy path is really an assumption. For each assumption the flow makes, record what establishes it. When nothing does, write `nothing found`. A reviewer needs these most, because they are where a change breaks things quietly.

**History — why it is this way.** Code shows behavior, not intent. Search the decision record:

- ADRs, design docs, READMEs, and comments near the odd parts; also the team's wiki or docs tool, if one is reachable. Search it by the area's name and its ticket IDs.
- `git log --follow --oneline -- <file>`: renames and turning points
- `git blame -w -C -C -C -L <range> <file>`: the last commit to touch a line, following moves across files. That commit is often a reformat, rename, or bulk refactor. If so, run `git blame <sha>^ -L <range> -- <file>` to step past it, or use `git log -L <start>,<end>:<file>` to see every change to those lines.
- `git log -S'<snippet>' --oneline`: when a pattern appeared or disappeared
- the PR/MR and the ticket behind a commit. Start with git, which works on any host:
  - The commit message or branch name often carries the IDs: `#123` or `!123` for a PR/MR, `PROJ-123` for a ticket.
  - The merge that brought the commit in usually names the PR/MR: `git show -s $(git log --ancestry-path --merges --reverse --format=%H <sha>..HEAD | head -1)`.
  - Then read the description, the review thread, and the linked ticket with whatever reaches the host and the tracker: a CLI or a connected tool. The reason is usually there, not in the title.
- the tickets that shaped the area: `git log --format='%s%n%b' -- <path> | grep -oE '[A-Z][A-Z0-9]+-[0-9]+|[#!][0-9]+' | sort | uniq -c | sort -rn | head`
- `git shortlog -sn --no-merges --since=2.years HEAD -- <path>`: who to ask. Ignore bot accounts (`[bot]`, dependabot, renovate). Keep `HEAD`: without a revision, `shortlog` reads stdin and hangs in a non-interactive shell.

Label every "why" as **documented** (cite it), **inferred** (say from what), or **unknown**. A missing record does not mean there was no reason. Before you present an old constraint as a current requirement, check that it still applies.

For a large area, give each lens or each ownership boundary to its own subagent (2-4 of them), each told to return `file:line` evidence and open gaps. If you need more than four, the question is still too broad: narrow it. Where subagent reports overlap or disagree, read the source yourself; a summary is not a trace.

## 3. Rules while writing

- **Describe; don't prescribe.** The user is the one judging. If critique comes before they've seen how the area works, it anchors their judgment. Mixed in with facts, it also makes them hard to tell apart. So no improvements, refactors, or critique unless the user asks; if they do, put it in a separate section after the map. Explaining a choice does not endorse it.
- **Cite every claim** as `file:line` or `file:L40-L88`, a commit SHA, a PR/MR, a ticket, or a doc. Citations let the user spot-check the map instead of trusting it. A claim you can't cite goes to open questions.
- **No hedges.** "Probably" and "seems to" hide whether something was checked, so the reader can't tell evidence from guesswork. Turn each one into a cited claim or an open question.
- **Disclose coverage.** Readers assume the map is complete, so say what you didn't trace.

## 4. Deliver

If the answer fits on a screen, answer in chat. For a whole area, write a Markdown file wherever the user keeps notes; ask once if unsure. Don't add it to the repo being studied unless they ask. Then summarize in chat with the path.

Write each heading as a takeaway, not a topic: "Orders are written to Postgres before the event is published", not "Order persistence". Someone who reads only the headings should come away with how the area works. Put each tree or diagram right beside the paragraph it supports.

```markdown
# <Area>: <one-line takeaway>

**Covered:** <what was traced> · **Not covered:** <what wasn't> · **Commit:** <sha>

## Summary
<3-5 sentences: what it does, who depends on it, how the main flow runs, and the most surprising fact.>

## <Takeaway about boundaries>        — annotated file tree, entry points, owned state
## <Takeaway about consumers>         — table: consumer | how it uses it | evidence
## <Takeaway per traced flow>         — call tree or sequence diagram, failure paths, tests
## <Takeaway about history>           — timeline of turning points, each why labelled documented / inferred / unknown

## Load-bearing facts
<The invariants and constraints that any change must preserve, each cited, with every `nothing found` assumption listed. This is the checklist for reviewing a diff or a plan in this area.>

## Who to ask
<People, from shortlog and the PR/MR and ticket history, and what each one knows.>

## Open questions
<What is still unclear, and what would settle each question.>
```

Call trees, file trees, and data contracts read best as plain-text blocks:

```text
POST /orders → OrderController.create
  OrderService.place(cmd)
    inventory.reserve(items)        # throws OutOfStock before anything is written
    orderRepo.insert(order)         # Postgres, same transaction as the outbox row; if it fails, nothing releases the reservation (nothing found)
    outbox.enqueue(OrderPlaced)     # relayed to Kafka by OutboxRelay (jobs/outbox.ts:12)
```
