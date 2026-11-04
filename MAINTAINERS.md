# MAINTAINERS.md

> **Scope:** boundaries, ownership, and "what this project does not do" for `ADRC-in-Ada`.

## Maintainer

- **Ryan** (`RyansOpenSourceRice` on GitHub) — sole maintainer.

## Scope

This project is a **linkable Active Disturbance Rejection Control library in SPARK for Ada**: tracking differentiator, extended state observer, disturbance-cancelling law, and their composed controller step. Pure SPARK core — bounded arithmetic, no heap, no I/O, OS-free — generic over the real type.

## What this project does

- Implements linear ADRC (bandwidth parameterization, Gao 2003) and staged nonlinear variants (Han's `fhan`/`fal`) as sibling packages over one contract skeleton.
- Provides an Alire-installable static library with a `pragma Pure` root package and caller-owned, reentrant controller state.
- Targets SPARK proof (gnatprove, Silver-level assurance on every core unit) for the control arithmetic.
- Demonstrates usage through single-file example programs and pins closed-loop behavior through golden-value regression tests.

## What this project does not do

- **Does not ship a controller binary, server, CLI, or GUI.** It is a library; applications embed it and own their interfaces.
- **Does not contain plant models or a simulation framework in the core.** Plants exist only as test/example harnesses; the core consumes measured outputs.
- **Does not tune itself.** Bandwidth, effectiveness, and sample-time selection are caller decisions (guidance in `SPECIFICATION.md`); no autotuning.
- **Does not read sensors or write actuators.** No I/O, no timing services, no OS calls: the caller supplies `Ts` and the measured value each step.
- **Does not enforce the maintainer's preferences on third-party repositories.** Scope guardrail from preferences.md §1.
- **Does not bundle the preferences or pointer skill.** Both are global assets with their home in `ryans-agentic-coding-preferences`; `AGENTS.md` carries agent orientation for this repository.

## Path to becoming a co-maintainer

Third-party contributions are welcome (see `CONTRIBUTING.md`). A co-maintainer gets write access after sustained, high-quality contributions to the core packages or the proof/test infrastructure plus agreement with the scope boundaries above. Changes to *what the project is* (scope, license, proof targets) stay with the maintainer; preference-level changes are mirrored upstream into `ryans-agentic-coding-preferences` first.

## Reporting issues

Use the issue forms in `.github/ISSUE_TEMPLATE/`. Issues are read and triaged; the maintainer reserves the right not to act on issues that conflict with the project's scope.

## Vulnerability disclosure

Follows `SECURITY.md` (100-day fix SLA framing, AI-use and model disclosure).

## Licensing

Apache-2.0 (see `LICENSE`).
