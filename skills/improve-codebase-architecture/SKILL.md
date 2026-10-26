---
name: improve-codebase-architecture
description: Find deepening opportunities in a codebase (shallow modules to fold behind a smaller interface), rank them, then grill through the one the user picks. Use when the user asks to review, improve, or restructure a codebase's architecture, or to make an area easier to test.
disable-model-invocation: true
---

# Improve codebase architecture

Propose **deepening** refactors: more behaviour behind a smaller interface. The default instinct (split files, add a layer, extract an interface) usually makes modules shallower. Resist it.

Use these terms exactly:

- **Module**: anything with an interface and an implementation, at any scale (function, class, package).
- **Interface**: everything a caller must know: types, invariants, ordering, error modes, config. Not just the signature.
- **Deep**: lots of behaviour behind a small interface. **Shallow**: interface nearly as complex as the implementation.
- **Seam**: where an interface lives; a place behaviour can be swapped without editing there. **Adapter**: a concrete thing filling a seam.

## 1. Scope

If the user named an area, use it. Otherwise read a long stretch of `git log --name-only` and start at the hot spots: deepening pays off where code keeps changing. Read ADRs or design docs for that area; don't re-propose what they rejected unless the friction is real, and say which decision you'd reopen.

## 2. Explore

Hand the walk to a subagent. Look for friction, not rule violations:

- Understanding one concept means bouncing between many small modules.
- Pass-through wrappers, single-implementation interfaces, layers that only forward.
- Pure helpers extracted "for testability" while the bugs live in how they're called.
- Logic leaking across a seam; areas hard to test through their current interface.

Apply the **deletion test** to each suspect: imagine deleting it. If complexity vanishes, it was a pass-through. If it reappears across N callers, it earns its keep.

## 3. Present candidates

In chat, ranked. Per candidate: files; problem in one sentence; the deepening in one sentence; dependency category and how it would be tested (below); strength `Strong | Worth exploring | Speculative`. Close with the one you'd do first. Don't design interfaces yet: ask which to explore.

## 4. Grill the chosen one

Run the `grilling` skill on it: constraints, the deepened interface, what sits behind the seam, which tests survive. If the interface shape is genuinely open, spawn 3 subagents in parallel, each with a different constraint (minimal interface of 1–3 entry points; trivial common-caller path; ports & adapters), compare them on depth and where change concentrates, and recommend one.

## Rules for the deepened design

The dependency category decides the test strategy:

1. **In-process** (pure, in-memory): merge and test through the new interface. No seam.
2. **Local stand-in exists** (PGLite, in-memory FS): test against the stand-in; the seam stays internal.
3. **Owned remote service**: a port at the seam; network adapter in prod, in-memory adapter in tests.
4. **Third party** (Stripe, Twilio): inject it as a port; mock adapter in tests.

- **One adapter is a hypothetical seam; two is a real one.** No port unless two adapters (usually prod + test) need it.
- **The interface is the test surface.** A test that must reach past it means the module is the wrong shape. Internal seams stay private.
- **Replace, don't layer.** Once tests exist at the deepened interface, delete the old unit tests on the shallow pieces.
