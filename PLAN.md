# ADRC-in-Ada — Build Plan

> Active Disturbance Rejection Control (ADRC) in SPARK, Silver-level assurance
> (gnatprove: absence of runtime errors on every unit in `src/`).
> Repo conventions follow the house pattern established by `shacl_ada`.

## Locked decisions

| Decision | Choice | Rationale |
|---|---|---|
| Arithmetic | Generic formal real type (`digits <>`) — float now, fixed-point instantiable later | The Ada answer: users choose the numeric type |
| Variant | Linear ADRC (bandwidth-parameterized, Gao 2003) first; nonlinear (fhan/fal) staged later | Algebraically simple, provable contracts |
| Plant order | 2nd-order plant, 3rd-order LESO | Covers most plants; the standard ADRC configuration |
| Scaffolding | Core-first: crate + SPARK core + tests + proof gate; full docs/CI pass later | Verify the hard part (proofs) before polishing the shell |
| Numerics | Explicit Euler at a caller-chosen fixed sample time `Ts`; saturation inside contracts; caller-owned state | Range checks dischargeable by gnatprove under stated `Pre` |

## Control law (Linear ADRC)

Plant model: `y'' = f(y, y', w, t) + b0*u` with `f` the lumped disturbance.

- **TD** (2nd-order linear tracking differentiator): `v1' = v2`,
  `v2' = -r^2 (v1 - ref) - 2r v2`; `r` = TD bandwidth.
- **LESO** (3rd-order): `z1' = z2 + B1 e`, `z2' = z3 + B2 e + b0 u`,
  `z3' = B3 e`, with `e = y - z1`;
  bandwidth parameterization `B1 = 3 wo`, `B2 = 3 wo^2`, `B3 = wo^3`.
- **Control**: `u0 = wc^2 (v1 - z1) - 2 wc z2`, `u = (u0 - z3) / b0`,
  saturated to `[U_Min, U_Max]`.

Design guidance (documented, not proven): Euler stability wants `Ts * wo` and
`Ts * wc` comfortably below ~0.3; the crate enforces a conservative bound as a
`Pre` condition on configuration validation.

## Architecture

```
src/adrc_ada.ads               root, generic over Real (digits <>)
src/adrc_ada-real.ads          constants, bounded subtypes, saturate helper
src/adrc_ada-td.ads/.adb       tracking differentiator
src/adrc_ada-leso.ads/.adb     linear extended state observer
src/adrc_ada-control.ads/.adb  feedback law + disturbance cancellation + saturation
src/adrc_ada-controller.ads/.adb  composition: Step(...) with caller-owned state
proof/spark_core.gpr           gnatprove project, src/ + proof/units only
proof/units/                   proof-only instantiation at a concrete capacity
tests/                         Alire test crate: unit checks + closed-loop simulation
scripts/verify.sh              local gate: alr build + gnatprove + tests
```

All `src/` units are `SPARK_Mode`, bounded memory, no heap, no I/O, no OS calls.
State lives in caller-owned records with range-constrained fields; `Step`
preserves the `Is_Valid` invariant (machine-checked, not assumed).

## Staged delivery

1. **This pass**: crate bootstrap, SPARK core, proof project, test crate
   (unit + closed-loop vs scripted plants + golden regression), `verify.sh`,
   README/CHANGELOG rows.
2. **Later**: full docs (DESIGN, SPECIFICATION, ROADMAP, ontology ttl),
   pre-commit, CI workflows, Alire index publication.
3. **Later**: nonlinear ADRC (`ADRC_Ada.Fhan`, `ADRC_Ada.Fal`) on the same
   state/contract skeleton; fixed-point instantiation example.

## Workflow

- Work lands on `dev`; `main` merges only via reviewed PR. Rebase, no merge
  commits. CHANGELOG row with every shipped change.
- `alr build` and `gnatprove` must pass before an implementation change is
  declared complete; report what was and was not verified.
