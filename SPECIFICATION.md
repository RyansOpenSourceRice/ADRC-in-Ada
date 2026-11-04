# SPECIFICATION.md

> What the library promises: units, contracts, ranges, semantics, tuning, and proof scope. Behavioral changes to anything described here ship with a `CHANGELOG.md` row and, when architecture-relevant, a `DESIGN.md` update.

## Overview

ADRC-in-Ada implements Active Disturbance Rejection Control as a SPARK core generic over the real type, in a linear and a nonlinear variant with the same contract skeleton. A controller run is a sequence of one-call steps:

1. `TD.Step` — filter the reference into `v1` (tracked reference) and `v2` (its derivative).
2. `LESO.Step` — estimate the plant state (`z1`, `z2`) and the lumped disturbance (`z3`) from the measured output and the previously applied control.
3. `Control.Law` — compute the disturbance-cancelling control value.
4. `Controller.Step` — performs 1–3 with caller-owned state and `Last_U` causality.

The nonlinear siblings (`NL_TD`, `NL_ESO`, `NL_Control`, `NL_Controller`, plus the shared `Fal` power function) follow the same four-step shape with Han's `fhan` synthesis and `fal` power-law corrections.

The plant model is the double integrator with effectiveness `b0` and lumped disturbance `d`: `y'' = b0 u + d`, where `d` collects every unmodeled effect. The observer estimates `d` directly, and the law cancels it.

## Equations

Per step of sample time `Ts`, with Euler integration:

Linear variant:

- TD: `v1' = v2`; `v2' = -r^2 (v1 - ref) - 2 r v2`
- LESO (error `e = z1 - y`): `z1' = z2 + 3 w_o e`; `z2' = z3 + 3 w_o^2 e + b0 u_prev`; `z3' = w_o^3 e`
- Law: `u = (w_c^2 (v1 - z1) - 2 w_c z2 - z3) / b0`, saturated to `±Max_Magnitude`

Nonlinear variant (Han's formulation, error `e = y - z1` in the observer):

- `fal(e, a, d) = e^a` when `|e| <= d`; `d^(a-1) * e` when `|e| > d` (both branches agree at `|e| = d`)
- `fhan`: the bounded-acceleration synthesis `fhan(e1, e2, r, h0)` with region parameter `d = r * h0`, linear inside `d0 = h0 * d`, square-root outside; its magnitude never exceeds `r`
- NL_TD: `v1' = v2`; `v2' = fhan(v1 - ref, v2, r, h0)` with filter factor `h0`
- NL_ESO: `z1' = z2 + beta01 * e`; `z2' = z3 + beta02 * fal(e, a1, d) + b0 u_prev`; `z3' = beta03 * fal(e, a2, d)`
- NLSEF law: `u = (beta1 * fal(v1 - z1, a1, d) + beta2 * fal(v2 - z2, a2, d) - z3) / b0`, saturated to `±Max_Magnitude`

## Contracts and ranges

`ADRC_Ada` (non-generic root) defines the constants every instantiation uses:

| Name | Value | Role |
|---|---|---|
| `Max_Magnitude` | 1.0e6 | Saturation bound for signals and every intermediate term |
| `Min_Bandwidth` / `Max_Bandwidth` | 1.0e-3 / 1.0e4 | Bandwidth subtype range (`r`, `w_o`, `w_c`) |
| `Min_Effectiveness` | 1.0e-6 | Lower bound for `b0` (division safety) |
| `Min_Sample_Time` / `Max_Sample_Time` | 1.0e-5 / 1.0e1 | Sample-time subtype range (`Ts`) |
| `Euler_Bound` | 0.3 | Upper bound for `Ts * w` for every configured bandwidth |
| `Max_Gain` | 1.0e14 | Upper bound for the nonlinear observer correction gains |

`ADRC_Ada.Limits` (generic) defines the bounded subtypes (`Signal`, `State_Var`, `Bandwidth`, `Effectiveness`, `Sample_Time`) and `Saturate`, which clamps any real value into the `Signal` range. Every arithmetic unit instantiates `Limits` with its own formal real type.

### Configuration validity

`Valid_Config (Ts, TD_Rate, Obs_Bandwidth, Ctl_Bandwidth, B0)` returns true when all values lie in their subtype ranges and `Ts * w <= Euler_Bound` holds for all three bandwidths. The composed controller rejects an invalid configuration with `Invalid_Configuration`; individual units assume their callers pass subtype-valid parameters.

### Step semantics

Each `Step` takes a state record (caller-owned), the measured inputs, and `Ts`, and returns the updated state and outputs. All values are saturated into the `Signal` range; the state fields live in `State_Var` (same bound). `Controller.State` additionally carries `Last_U`, the control value applied at the previous step, which the observer consumes — this ordering is the documented causality (see `DESIGN.md`).

## Tuning guidance

- Choose `w_c` (control bandwidth) from the desired settling scale: a first-order approximation gives roughly `4 / w_c` seconds to settle on the double-integrator plant.
- Set the observer bandwidth `w_o = (3 .. 10) * w_c`. Lower ratios filter measurement noise harder; higher ratios reject disturbance sooner at the cost of noise sensitivity.
- Set the TD rate `r >= w_c`; `r = w_c` tracks without overshoot lag on step references, larger `r` approaches passing the reference through unchanged.
- Identify `b0` from the plant: `b0 ~ y'' / u` on the linearized, disturbance-free plant. A factor-of-two error in `b0` is typically absorbed by `z3`; orders of magnitude are not.
- Respect `Ts * w <= 0.3` for all three bandwidths — `Valid_Config` enforces it, and valid-but-marginal values near the bound trade phase margin for speed.
- Nonlinear variant: the classical Han gain triples (e.g. `beta = (3 w_o, 3 w_o^2, w_o^3)`, the library defaults) come from continuous-time synthesis and need fine sample times. In discrete time, the `fal` continuation slope outside the width region is `d^(a-1)`, so the effective gain of the `z3` correction is roughly `Ts * beta03 * d^(a2-1)`; keep that product well inside 1 (the test suite documents a stability-feasible cascade at `Ts = 0.01`). Raising the width `d` or moving exponents `a` toward 1 both buy stability margin at the cost of nonlinearity.

## Proof scope

gnatprove proves absence of runtime errors on every core unit (SPARK Silver, level 3, `proof/spark_core.gpr`): subtype ranges, division safety (`B0 >= Min_Effectiveness`), and every intermediate saturation. One trust boundary is documented and deliberately small: the fractional-power evaluation behind `fal` (and the elementary square root behind `fhan`) run outside the SPARK view; their visible contracts (input range, result bound) are assumptions at that boundary, every use site saturates the result, and the mathematical bounds (error magnitude capped at `Max_Magnitude`, exponent window `0.25 .. 1.5`) keep the underlying arithmetic far inside the real type's float range. Control performance — settling, rejection, noise behavior — is simulation scope, pinned by the golden-value regression tests in `tests/`, not a proof claim.

## Surface area

| Path | Purpose |
|---|---|
| `src/adrc_ada.ads` | Constants and contract documentation (non-generic) |
| `src/adrc_ada-limits.{ads,adb}` | Bounded subtypes and `Saturate` |
| `src/adrc_ada-td.{ads,adb}` | Tracking differentiator |
| `src/adrc_ada-leso.{ads,adb}` | Extended state observer |
| `src/adrc_ada-control.{ads,adb}` | Control law |
| `src/adrc_ada-controller.{ads,adb}` | Composed one-call step |
| `src/adrc_ada-fal.{ads,adb}` | `fal` power function (shared nonlinear primitive) |
| `src/adrc_ada-nl_td.{ads,adb}` | `fhan`-based tracking differentiator |
| `src/adrc_ada-nl_eso.{ads,adb}` | Nonlinear extended state observer |
| `src/adrc_ada-nl_control.{ads,adb}` | Nonlinear state error feedback law |
| `src/adrc_ada-nl_controller.{ads,adb}` | Composed one-call nonlinear step |
| `examples/` | Single-file demonstration programs |
| `tests/` | Unit checks and closed-loop simulation regressions |
| `proof/` | gnatprove project and proof-only instantiations |

## Compatibility

The library targets the current Alire/GNAT toolchain (see `alire.toml`) and follows SemVer: additions to the package surface are minor versions; changes to step semantics, contracts, or ranges are major versions. The proof project pins the gnatprove release used for the `0.x` series.
