# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

`dotai` is a personal, hand-curated collection of AI agent skills used for day-to-day development — the "dotfiles" of AI tooling. Remote: `git@github.com:platonoff-dev/dotai.git`.

There is no build, lint, or test tooling yet. If any is added, document the commands here.

## Curation rule (the most important thing in this repo)

The list must stay **very, very curated**. Only the best of the best earns a place. Treat every addition as guilty until proven useful.

When asked to add, generate, or import a skill:

- **Default to no.** Push back if a skill is generic, overlaps an existing one, duplicates what the model already does well without instructions, or exists "just in case".
- **It must encode something non-obvious** — a workflow, convention, or piece of hard-won knowledge the model would otherwise get wrong or do inconsistently. A skill that restates general best practices is slop.
- **It must be used regularly.** Speculative or one-off skills don't belong here.
- **Prefer improving or merging over adding.** If a new skill overlaps an existing one, fold it in.
- **Keep each skill tight.** Cut filler, motivational preamble, and padded examples. Shorter and sharper beats longer and comprehensive.
- **Removing is a feature.** Suggest deleting skills that are stale, unused, or superseded.

Never bulk-import skill packs or auto-generate batches of skills.

## Layout

Skills follow the Claude Code skill format: one directory per skill containing a `SKILL.md` with YAML frontmatter (`name`, `description`) and optional supporting files next to it. The `description` drives when the skill triggers, so it should say precisely what the skill does and when to use it.
