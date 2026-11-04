# ROADMAP.md

What is planned, what is explicitly not being built, and the direction of the project. Updated **as part of the change** that shifts direction; stale entries are pruned, not left to accumulate. The canonical state is `project.ontology.ttl` (Milestone nodes); this file is the human-readable view.

## Direction

ADRC-in-Ada becomes the dependable Ada/SPARK building block for Active Disturbance Rejection Control: a pure SPARK core (bounded arithmetic, no heap, no I/O, OS-free) generic over the real type, with proof-level assurance on every unit, growing narrow and deep — linear proven, then nonlinear as siblings, then a fixed-point path for embedded targets — not wide.

## Planned

- **Fixed-point instantiation** — an example instantiation of the generic core at a fixed-point real type (no-FPU embedded path), demonstrating what the `Real_Type` contract requires of such a type.
- **Alire index publication** — submit the crate to the community index once the fixed-point path is demonstrated.

## Shipped

- **Linear ADRC core at SPARK Silver** — TD, LESO, law, composed controller, proven and golden-regressed (2026.11.02).
- **Compliance and presentation pass** — standards files, pre-commit gate, CI, ontology with shapes (2026.11.02).
- **Nonlinear ADRC packages** — Han's `fhan`-based tracking differentiator and `fal`-based observer/law corrections as sibling packages over the same bounded skeleton, proven to the same standard, tested side-by-side against the linear loop (2026.11.04).

## Explicitly not building

- **No binaries, servers, CLIs, or GUIs.** ADRC-in-Ada is a library; applications embed it and own their interfaces (the `examples/` programs are documentation, not product).
- **No I/O, plant models, or simulation framework inside the core.** Plant models exist only in `tests/` and `examples/` as simulation harnesses; the core consumes measured outputs and produces control values.
- **No automatic tuning.** Bandwidth/effectiveness selection stays caller work (guidance in `SPECIFICATION.md`); an autotuner would be a separate project.
- **No container image.** An OS-free library has no runtime to containerize.
- **No scheduled CI on the shared forge.** Event-driven pipelines only (§9 capacity awareness).
- **No documentation site.** README + the standards files are the documentation surface (§9).
- **No preferences or pointer skill in the repo.** Both are global assets; `AGENTS.md` carries agent orientation for this repository.

## Recently completed

- **2026.11.04** — compliance pass: standards files (DESIGN, SPECIFICATION, ROADMAP, MAINTAINERS, SECURITY, CONTRIBUTING, AGENTS, THIRD_PARTY_NOTICES), the pre-commit gate (gitleaks, cspell, Vale, hygiene, OpenGrep), the `ada` CI workflow (build + gnatprove + tests), Renovate, project ontology with SHACL shapes, issue forms and PR template. See `CHANGELOG.md` [Unreleased].
- **2026.11.02** — linear ADRC core: TD, LESO, control law, and the composed controller, generic over the real type, SPARK Silver (gnatprove 184 checks, level 3), unit and closed-loop tests with golden-value regression, three examples, and the `scripts/verify.sh` gate. See `CHANGELOG.md` [2026.11.02].
