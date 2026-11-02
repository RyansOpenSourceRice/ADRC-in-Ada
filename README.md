# ADRC-in-Ada
Active Disturbance Rejection Control (ADRC) in Ada Spark Silver

## Status

Bootstrap, first core landed: linear ADRC after Han (bandwidth
parameterization per Gao 2003) — tracking differentiator, third-order
linear extended state observer, and a disturbance-cancelling state
feedback law — as a pure SPARK core generic over the real type
(`adrc_ada`), with caller-owned bounded state, no heap, no I/O. The
build order lives in `PLAN.md`: full docs pass (DESIGN,
SPECIFICATION, ROADMAP), CI, and Alire index publication follow.

## Using the repository

- The crate is built and consumed through [Alire](https://alire.ada.dev/);
  the descriptor is `alire.toml`.
- Verification gate (build + gnatprove + tests): `scripts/verify.sh`.
- Examples: `alr exec -- gnat make -q -P examples.gpr`.
- Contributions follow `CONTRIBUTING.md` (when present); AI agents
  follow `AGENTS.md` (when present).

## File map

| Path | Purpose |
|---|---|
| `alire.toml`, `adrc_ada.gpr`, `src/` | Alire crate descriptor, GNAT project, SPARK core |
| `examples/`, `examples.gpr` | Three single-file demo programs |
| `tests/` | Alire test crate: unit checks + closed-loop simulation |
| `proof/` | gnatprove project and proof-only instantiations |
| `scripts/verify.sh` | Local verification gate |
| `PLAN.md`, `CHANGELOG.md` | Build order, change record |

## License

Apache-2.0 (see `LICENSE`).
