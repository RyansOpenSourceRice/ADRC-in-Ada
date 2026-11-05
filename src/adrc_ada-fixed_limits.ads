--  SPDX-License-Identifier: Apache-2.0
--
--  Fixed-point sibling of ADRC_Ada.Limits: the shared bounded-subtype
--  vocabulary and the saturation helpers at a fixed-point real type
--  (the no-floating-point instantiation path).
--
--  The subtypes are the invariants, as in the floating-point sibling:
--  no subprogram in the family ever assigns an out-of-range value.
--
--  Three fixed-point specifics shape this unit:
--
--  * Floors of the small positive bounds sit at the type's delta.
--    Fixed-point types have no sub-delta values, and a literal floor
--    below the delta (such as the 1.0e-6 effectiveness floor of the
--    floating-point family) rounds to zero on the type's grid, which
--    would silently admit a zero divisor.
--
--  * Fixed-point products are exact universal_fixed intermediates and
--    may only be compared against typed values, not against real
--    literals.
--
--  * The universal_fixed intermediate of any binary operation on a
--    type of Size S is bounded by 2**S deltas of the result: a 32-bit
--    type admits intermediates up to about 2**31 * Delta real units,
--    a 64-bit type up to about 2**63 * Delta. An operation whose
--    operands are too large would raise Constraint_Error before any
--    result clamp could run, so each S_* helper first clamps its
--    operands into a proven operand band and only then clamps the
--    result into the signal range by comparison. The bands keep every
--    intermediate near 2**20 real units:
--
--      Sum_Band     500000.0   pair sums stay within 1.0e6
--      Product_Band 1000.0      pair products stay within 1.0e6
--
--  * Division of a wide dividend by a small divisor leaves the
--    universal intermediate before any clamp could run (the quotient
--    of a full-scale signal by a divisor near the delta exceeds the
--    intermediate bound by orders of magnitude), so the family offers
--    no general division. The one quotient the control law needs, the
--    reciprocal of the effectiveness, is available as S_Recip: the
--    divisor floor Min_Effectiveness keeps that quotient inside the
--    intermediate at the reference instantiations, and the law then
--    multiplies by it. Effectiveness values that are powers of two
--    give exact reciprocals on the grid; other values quantize, like
--    every other fixed-point operation.
--
--  Instantiation discipline: the instance type must contain the +/-
--  Max_Magnitude signal bound and hold the operand bands and
--  Min_Effectiveness on its grid. A 32-bit type does so from a
--  resolution of 2.0**(-11) on with Max_Magnitude <= 1.0e6 (delta
--  2.0**(-16) spans only +/- 32768 and does not fit). Q20_11 (32 bit)
--  and Q31_32 (64 bit) are the validated reference instantiations.

generic

   --  The fixed-point arithmetic this family runs in.
   type Real_Type is delta <>;

package ADRC_Ada.Fixed_Limits with SPARK_Mode is

   --  The Euler stability bound of the family, on this type's grid. The
   --  universal literal rounds to the nearest delta, which on a coarse
   --  grid tightens the bound slightly. Fixed-point products are exact
   --  universal intermediates and may only be compared against typed
   --  values, not against real literals.
   Euler_Bound : constant Real_Type := 0.3;

   --  Operand bands for the S_* helpers (derivation in the file
   --  header: every helper keeps its intermediate within 1.0e6 real
   --  units, far inside the 2**31 * Delta floor of a 32-bit type at
   --  delta 2.0**(-11)).
   Sum_Band     : constant Real_Type := 500000.0;
   Product_Band : constant Real_Type := 1000.0;

   --  Measurements, references, and observer estimates.
   subtype Signal is Real_Type'Base range -Max_Magnitude .. Max_Magnitude;

   --  Control output range after saturation.
   subtype Control_Signal is Real_Type'Base range -Max_Magnitude .. Max_Magnitude;

   --  Internal state values (tracking differentiator, observer).
   subtype State_Value is Real_Type'Base range -Max_Magnitude .. Max_Magnitude;

   --  Loop bandwidths (1/s).
   subtype Bandwidth is Real_Type'Base range Real_Type'Delta .. Max_Bandwidth;

   --  Control effectiveness b0 (plant units per control unit). The
   --  floor is the smallest value whose reciprocal stays inside the
   --  universal intermediate and the signal range (0.001 rounds to
   --  the nearest grid point; see the file header). Strictly
   --  positive: its reciprocal multiplies in the control law.
   Min_Effectiveness : constant Real_Type := 0.001;
   subtype Effectiveness is Real_Type'Base range Min_Effectiveness .. Max_Magnitude;

   --  Sample times (s).
   subtype Sample_Time is Real_Type'Base range Real_Type'Delta .. Max_Sample_Time;

   --  Saturate X into [Lo, Hi]. The postcondition is what lets gnatprove
   --  discharge the range check on every saturated assignment in this
   --  family.
   function Saturate (X, Lo, Hi : Real_Type'Base) return Real_Type'Base with
     Pre  => Lo <= Hi,
     Post => Saturate'Result >= Lo and then Saturate'Result <= Hi;

   --  Bounded arithmetic: each helper first clamps its operands into
   --  the band that keeps its intermediate inside the implementation's
   --  universal bound (see the file header), then clamps the exact
   --  universal_fixed result into the signal range by comparison, so
   --  the clamp decision itself never raises a range check. The
   --  operands are Signal, not Real_Type'Base: a fixed-point operation
   --  on unbounded values cannot be shown to stay inside the universal
   --  intermediate, and gnatprove would flag an overflow check on
   --  every operation.

   function S_Mul (A, B : Signal) return Signal with
     Post => S_Mul'Result >= -Max_Magnitude and then S_Mul'Result <= Max_Magnitude;

   function S_Add (A, B : Signal) return Signal with
     Post => S_Add'Result >= -Max_Magnitude and then S_Add'Result <= Max_Magnitude;

   function S_Sub (A, B : Signal) return Signal with
     Post => S_Sub'Result >= -Max_Magnitude and then S_Sub'Result <= Max_Magnitude;

   --  Reciprocal of an effectiveness value: the only division the
   --  family needs, with the divisor floored at Min_Effectiveness so
   --  the quotient stays inside the universal intermediate (see the
   --  file header). Powers of two are exact on the grid; other
   --  values quantize.
   function S_Recip (B : Signal) return Signal with
     Pre  => B >= Min_Effectiveness,
     Post =>
       S_Recip'Result >= 0.0 and then S_Recip'Result <= Max_Magnitude;

end ADRC_Ada.Fixed_Limits;
