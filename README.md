# ADRC-in-Ada

[![License: Apache-2.0](https://img.shields.io/badge/License-Apache_2.0-blue.svg)](LICENSE)
[![ada](https://github.com/RyansOpenSourceRice/ADRC-in-Ada/actions/workflows/ada.yml/badge.svg)](https://github.com/RyansOpenSourceRice/ADRC-in-Ada/actions/workflows/ada.yml)
[![pre-commit](https://github.com/RyansOpenSourceRice/ADRC-in-Ada/actions/workflows/pre-commit.yml/badge.svg)](https://github.com/RyansOpenSourceRice/ADRC-in-Ada/actions/workflows/pre-commit.yml)
![SPARK](https://img.shields.io/badge/SPARK-Silver_(gnatprove)-teal)

Active Disturbance Rejection Control (ADRC) in Ada, SPARK Silver

## Status

Linear and nonlinear ADRC cores landed and proven: tracking
differentiator, extended state observer (linear and `fal`-based), and a
disturbance-cancelling state feedback law (linear bandwidth
parameterization per Gao 2003; nonlinear synthesis per Han) as a pure
SPARK core generic over the real type (`adrc_ada`), with caller-owned
bounded state, no heap, no I/O. gnatprove proves absence of runtime
errors on every core unit (Silver, level 3). A fixed-point
instantiation follows — see `ROADMAP.md` for direction and
`DESIGN.md`/`SPECIFICATION.md` for the reasoning and contracts.

## Using the repository

- The crate is built and consumed through [Alire](https://alire.ada.dev/);
  the descriptor is `alire.toml`.
- Verification gate (library + examples build, gnatprove, tests):
  `scripts/verify.sh`.
- Examples: `alr exec -- gnat make -q -P examples.gpr`.
- Contributions follow `CONTRIBUTING.md`; AI agents follow `AGENTS.md`.

## File map

| Path | Purpose |
|---|---|
| `alire.toml`, `adrc_ada.gpr`, `src/` | Alire crate descriptor, GNAT project, SPARK core (linear and nonlinear units) |
| `examples/`, `examples.gpr` | Four single-file demo programs |
| `tests/` | Alire test crate: unit checks + closed-loop simulation |
| `proof/` | gnatprove project and proof-only instantiations |
| `scripts/verify.sh` | Local verification gate |
| `DESIGN.md`, `SPECIFICATION.md` | Design reasoning, contracts and tuning |
| `ROADMAP.md`, `MAINTAINERS.md` | Direction and scope boundaries |
| `CONTRIBUTING.md`, `SECURITY.md`, `THIRD_PARTY_NOTICES.md` | Contribution flow, disclosure, notices |
| `AGENTS.md` | AI behavior guidance for this repository |
| `project.ontology.ttl`, `validation/` | Project ontology and its SHACL shapes |
| `PLAN.md`, `CHANGELOG.md` | Build order, change record |

## License

Apache-2.0 (see `LICENSE`).
