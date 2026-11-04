# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/),
and this project adheres to SemVer (three-digit MAJOR.MINOR.PATCH) per
the library versioning convention.

## [Unreleased]

### Added

- Compliance and presentation pass: standards files (`DESIGN.md`,
  `SPECIFICATION.md`, `ROADMAP.md`, `MAINTAINERS.md`, `SECURITY.md`,
  `CONTRIBUTING.md`, `AGENTS.md`, `THIRD_PARTY_NOTICES.md`), the
  pre-commit gate (gitleaks, cspell, Vale, hygiene hooks, OpenGrep;
  open-code-review on manual stage), the `ada` CI workflow
  (build + gnatprove + tests), Renovate configuration, the project
  ontology with SHACL shapes, issue forms, and the pull-request
  template.
- README badges and an updated file map.

### Changed

- README status wording simplified; license section states the license
  without further framing.

## [2026.11.02]

### Added

- SPARK core, generic over the real type (`ADRC_Ada`, formal
  `Real_Type is digits <>`): tracking differentiator (`ADRC_Ada.TD`),
  third-order linear extended state observer (`ADRC_Ada.LESO`),
  disturbance-cancelling state-feedback law (`ADRC_Ada.Control`), and
  the composed one-call controller (`ADRC_Ada.Controller`) with
  caller-owned state and causal observer updates.
- Bounded-arithmetic contracts: signal, state, bandwidth, effectiveness,
  and sample-time subtypes with saturation of every intermediate term
  before combination, so gnatprove discharges every range and
  float-overflow check; `Euler_Bound` configuration contract for
  explicit-Euler stability margins.
- gnatprove project `proof/spark_core.gpr` (SPARK Silver target:
  absence of runtime errors) with a proof-only instantiation at IEEE
  double capacity (`proof/units/`).
- Test crate `tests/`: unit checks (saturation, control law,
  configuration validity, TD convergence, LESO zero-input hold) plus
  closed-loop simulation against double-integrator and damped plants
  with constant disturbances and a saturation stress case.
- Three example programs (`examples/`): step tracking, disturbance
  rejection, saturation.
- `scripts/verify.sh`: local gate (library + examples build, gnatprove,
  test run).
- `PLAN.md`: build-order record for the staged delivery.
