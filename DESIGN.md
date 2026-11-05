# DESIGN.md

> The reasoning behind the design: decisions, trade-offs, and rejected alternatives. The canonical decision record is `project.ontology.ttl` (Decision nodes); this file is the human-readable view.

## Purpose

ADRC-in-Ada is a linkable Active Disturbance Rejection Control (ADRC) library for Ada: a tracking differentiator (TD), an extended state observer (ESO), and a disturbance-cancelling control law, composed as a one-call controller step. The core is pure SPARK — bounded arithmetic, no heap, no I/O, OS-free — generic over the real type, with gnatprove assurance (absence of runtime errors) on every unit.

## Decisions

### Linear ADRC first, nonlinear staged

The library ships the bandwidth-parameterized linear ADRC (Gao 2003): TD as a second-order filter with rate `r`, LESO as a third-order observer with poles placed at `-w_o`, and the law `u0 = w_c^2 (v1 - z1) - 2 w_c z2`, `u = (u0 - z3)/b0`. Nonlinear variants (Han's `fhan` differentiator and `fal`-based corrections) land as sibling packages reusing the same state and contract skeleton.

- *Alternative:* nonlinear ADRC from day one — rejected: the bounded-arithmetic proof pattern had to be established on the simplest variant first; nonlinear terms (`|e|^alpha`, piecewise `fhan`) extend a proven skeleton instead of bootstrapping one.

### Nonlinear siblings over the same skeleton

The nonlinear packages (`Fal`, `NL_TD`, `NL_ESO`, `NL_Control`, `NL_Controller`) reuse the linear units' contract vocabulary verbatim: same `Signal`/state subtypes, same saturate-before-combine discipline, same one-call `Step` shape with `Last_U` causality and caller-owned state. The composed controller instantiates its three sibling units internally at one real type — one arithmetic everywhere, mirroring the linear `Controller`.

`fhan` is proven interval-style rather than saturation-style: its synthesis parameters stay unsaturated (their positivity is what the final division needs), every remaining term stays inside interval bounds by construction, and the output bound `|fhan| <= r` is stated as a postcondition the prover discharges branch by branch.

- *Alternative:* one generic controller with a linear/nonlinear switch — rejected: two sibling controllers keep each surface honest (the configurations differ in shape, not just values) and keep the proof obligations per unit small.

### One trust boundary for fractional powers

`fal` needs real-exponent powers; the elementary exponentiation sits outside the SPARK view, and gnatprove cannot discharge its overflow check by interval reasoning (documented proof limitation). The library moves the exponentiation behind a `SPARK_Mode => Off` wrapper (`Frac_Power`) whose visible contract — input magnitude capped at `Max_Magnitude`, result bounded by `Max_Power = 1e9` — is an assumption at that boundary. Every use site saturates the result before combining. This is the same trust class as the elementary functions themselves; the wrapper keeps it in one place, documented in `SPECIFICATION.md` (proof scope).

- *Alternative:* justify the unproven overflow checks with review annotations — rejected: a stated assumption with an auditable one-line body beats a scattered set of waived checks.

### Generic over the real type

Every unit is generic over `type Real_Type is digits <>` and instantiates the contract vocabulary package `ADRC_Ada.Limits` internally with that same formal. The root package `ADRC_Ada` is deliberately non-generic: it carries only the documentation and the magnitude/bound constants shared by every instantiation. Consumers instantiate the units at `Long_Float` today, at a fixed-point type later.

- *Alternative:* fixed `Float` — rejected: it locks out the fixed-point instantiation path for embedded targets without an FPU, which is an explicit direction of this library family.
- *GNAT constraint recorded:* a child of a generic package must itself carry a `generic` declaration and does **not** inherit the parent's formals. The working structure is: non-generic root, generic `Limits` child carrying the subtypes and `Saturate`, and each arithmetic unit declaring its own formal real type and instantiating `Limits` itself.

### Fixed-point siblings with operand-band arithmetic

The linear family ships a fixed-point sibling set (`Fixed_Limits`, `Fixed_TD`, `Fixed_LESO`, `Fixed_Control`, `Fixed_Controller`) generic over `type Real_Type is delta <>` — a no-FPU instantiation path, mirroring how the standard library ships `Generic_Elementary_Functions` for floats only. The nonlinear units stay floating-point: they need elementary exponentiation, which fixed-point types cannot host.

Fixed-point arithmetic changed the proof strategy, because GNAT bounds the *universal_fixed intermediate* of every binary operation at about `2**Size * Delta` real units of the instantiated type (a 32-bit type at delta `2**(-11)` admits intermediates up to about `2**20`), and that intermediate is computed *before* any result clamp could run: a product or quotient of full-range signals would raise `Constraint_Error` before the saturating comparison even executes. The discipline the sibling family encodes:

- **Operand bands before the operation.** `S_Mul` clamps both operands to `Product_Band` (1000) and `S_Add`/`S_Sub` clamp to `Sum_Band` (5e5) first; pair products and sums then provably stay inside the intermediate bound at any admissible instantiation, and the result is clamped into the signal range by comparison on the exact intermediate. Values this far outside the demo band appear only at contract extremes; inside it the arithmetic is bit-identical to the floating-point family.
- **Division only as a reciprocal.** A quotient of a wide dividend by a small divisor leaves the intermediate by orders of magnitude, so the family has no general division. The one quotient the control law needs — dividing by the plant effectiveness — becomes a multiply by `S_Recip (b0)`, whose divisor floor `Min_Effectiveness` (1.0e-3, rounded to the nearest grid point) keeps the reciprocal inside the intermediate and inside the signal range at the reference instantiations. Effectiveness values that are powers of two give exact reciprocals on the grid; other values quantize like every fixed-point operation.
- **Reference instantiations prove the generic.** gnatprove analyzes generic code only through its instantiations, so `proof/units/adrc_proof_fixed_units.ads` instantiates the whole family at a 32-bit `Q20_11` grid (delta `2**(-11)`, the coarsest resolution that holds `±Max_Magnitude` in 32 bits) and a 64-bit `Q31_32` grid, and those instantiations are proved together with the floating-point core in `scripts/verify.sh`.

- *Alternative:* one arithmetic abstraction shared by float and fixed (`S_Mul`-style operators over both `digits <>` and `delta <>` formals) — deferred: it would reshape the proven core for a modest reuse win; the sibling duplication is ~10 files and zero proof risk. Revisit with measured proof/test effort before Alire index publication.
- *Alternative:* trusting the runtime overflow check on intermediates (no operand bands) — rejected: the check fires on contract-extreme inputs that the floating-point family survives by saturation; the bands are what keep the fixed family total over its contract range.

### Bounded-arithmetic proof strategy

SPARK 16 discharges range checks and float-overflow checks on `'Base` arithmetic. Unbounded intermediate expressions (product chains like `w_o^3 * e`) explode interval bounds and stall or time out the prover. The library therefore saturates **every intermediate term** into the `±Max_Magnitude` signal range immediately after each multiplication, before any addition: every constant is a single operation, and `Saturate`'s postcondition makes each verification condition interval-trivial. gnatprove proves all checks on the whole core at level 3.

- *Alternative:* `assume` statements bounding intermediate products — rejected: assumptions weaken assurance to trust-in-author.
- *Cost, documented:* saturation is active only beyond `±Max_Magnitude` (1.0e6). Within the normal operating band the computed trajectory is bit-identical to unsaturated arithmetic — the golden-value regression tests pin this.

### Explicit Euler with a configuration contract

All integration is explicit Euler with a caller-chosen sample time. Validity requires `Ts * w <= Euler_Bound (0.3)` for every bandwidth the configuration uses (`TD.r`, `LESO.w_o`, `Law.w_c`), checked by `Valid_Config` before any step runs. The bound keeps the discrete poles of the scaled integration loop inside the stable region with margin.

- *Alternative:* exact discrete pole placement (`z-transform` coefficients) — rejected for the first core: more constants per unit and a harder proof surface; the Euler-plus-bound contract is standard practice for bandwidth-parameterized ADRC and is fully checkable.

### Causality: `Last_U`

The LESO update consumes the control value from the *previous* step (`State.Last_U`), not the value being computed now. This breaks the algebraic loop between law and observer, keeps the one-call step semantics (`update TD, update LESO with last u, compute law, store u`) sequential and data-flow-provable, and matches how sampled controllers behave in front of a zero-order hold.

### Caller-owned state, no globals

Each unit exposes a `State` record the caller declares and passes in; the composed controller owns the three sub-states plus `Last_U`. No hidden global variables, no heap, no I/O: reentrant by construction, embeddable in a bare-metal task without further work.

## Architecture

| Unit | Responsibility |
|---|---|
| `ADRC_Ada` (non-generic) | Documentation, magnitude and bound constants |
| `ADRC_Ada.Limits` (generic) | Bounded subtypes (`Signal`, `State_Var`, `Bandwidth`, `Effectiveness`, `Sample_Time`) and `Saturate` |
| `ADRC_Ada.TD` | Tracking differentiator step (`v1`, `v2`) |
| `ADRC_Ada.LESO` | Extended state observer step (`z1`, `z2`, `z3`) |
| `ADRC_Ada.Control` | Disturbance-cancelling static law |
| `ADRC_Ada.Controller` | One-call step composing the three, with `Last_U` causality |

`Controller` instantiates its three siblings at the caller's real type (`Diff_Unit`, `Obs_Unit`, `Law_Unit`) and validates the configuration through `Valid_Config` before the first step.

## Proof scope

Proven: absence of runtime errors (SPARK Silver) on every core unit, including all intermediate saturations, subtype ranges, and the configuration-validity contracts. Not proven (and not claimable): control performance. Settling time, disturbance rejection quality, and robustness margins are simulation-scope properties — `tests/` pins them as golden-value regressions, not as proofs.

## Known limitations

- Explicit Euler only (see the decision above).
- `b0` is a known constant per configuration; the library does not estimate it. The observer absorbs modeling error into `z3`, which is the standard ADRC robustness argument, but a badly wrong `b0` still degrades the loop.
- Intermediate saturation activates only past `±1.0e6`; a configuration driven into that region is a design error the caller must avoid (the tests demonstrate the safe regime).

## License

Apache-2.0 (see `LICENSE`).
