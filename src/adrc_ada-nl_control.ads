--  SPDX-License-Identifier: Apache-2.0
--
--  Nonlinear state-error feedback law (NLSEF) with disturbance
--  cancellation.
--
--  With V1/V2 the tracking differentiator outputs and Z1/Z2/Z3 the
--  observer estimates, the law combines fal-shaped error terms and
--  cancels the estimated disturbance:
--
--      e1 = v1 - z1;  e2 = v2 - z2
--      u0 = Beta1 * fal(e1, Alpha1, Delta) + Beta2 * fal(e2, Alpha2, Delta)
--      u  = (u0 - z3) / b0     saturated to +/- Max_Magnitude
--
--  Classical tuning: Alpha1 = 0.75, Alpha2 = 1.25, Beta1 ~ wc^2,
--  Beta2 ~ 2 wc. This unit is pure SPARK: gnatprove proves absence of
--  runtime errors.

with ADRC_Ada.Fal;
with ADRC_Ada.Limits;

generic

   --  The real arithmetic this unit runs in.
   type Real_Type is digits <>;

package ADRC_Ada.NL_Control with SPARK_Mode is

   --  Contract vocabulary of the library, at this unit's real type.
   package Lim is new ADRC_Ada.Limits (Real_Type);
   package Fal_Unit is new ADRC_Ada.Fal (Real_Type);

   subtype Signal is Lim.Signal;
   subtype Control_Signal is Lim.Control_Signal;
   subtype Effectiveness is Lim.Effectiveness;

   --  Feedback gains. Strictly positive; large by design.
   subtype Gain is Real_Type'Base range 1.0E-9 .. Max_Gain;

   type Config is record
      --  Feedback gains, in the order of the combination above.
      Beta1 : Gain := 100.0;
      Beta2 : Gain := 20.0;
      --  fal parameters of the two error terms.
      Alpha1 : Fal_Unit.Alpha_Range := 0.75;
      Alpha2 : Fal_Unit.Alpha_Range := 1.25;
      Width : Fal_Unit.Delta_Range := 0.01;
      --  Control effectiveness b0. Strictly positive: it divides in
      --  the disturbance-cancellation term.
      B0 : Effectiveness := 1.0;
   end record;

   --  One control-law evaluation; saturated into Control_Signal. The
   --  law is a static map: no sample-time contract applies.
   function Law (C : Config; V1, Z1, V2, Z2, Z3 : Signal) return Control_Signal;

end ADRC_Ada.NL_Control;
