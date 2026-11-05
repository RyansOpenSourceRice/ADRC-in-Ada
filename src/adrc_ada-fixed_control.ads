--  SPDX-License-Identifier: Apache-2.0
--
--  Fixed-point sibling of ADRC_Ada.Control: state-feedback control law
--  with disturbance cancellation.
--
--  With V1/V2 the tracking differentiator outputs (reference state and
--  derivative) and Z1/Z2/Z3 the observer estimates (output, derivative,
--  lumped disturbance), the law is
--
--      u0 = wc^2 (v1 - z1) - 2 wc z2
--      u  = (u0 - z3) / b0     saturated to +/- Max_Magnitude
--
--  with wc the controller bandwidth (1/s) and b0 the control
--  effectiveness. Every product, sum, and the quotient run through the
--  saturating helpers of the fixed-point limits unit. This unit is pure
--  SPARK: gnatprove proves absence of runtime errors.

with ADRC_Ada.Fixed_Limits;

generic

   --  The fixed-point arithmetic this unit runs in.
   type Real_Type is delta <>;

package ADRC_Ada.Fixed_Control with SPARK_Mode is

   --  Contract vocabulary of the family, at this unit's real type.
   package Lim is new ADRC_Ada.Fixed_Limits (Real_Type);
   subtype Signal is Lim.Signal;
   subtype Control_Signal is Lim.Control_Signal;
   subtype Bandwidth is Lim.Bandwidth;
   subtype Effectiveness is Lim.Effectiveness;

   --  One control-law evaluation; saturated into Control_Signal.
   function Law
     (Wc            : Bandwidth;
      V1, Z1        : Signal;
      Z2            : Signal;
      Z3            : Signal;
      B0            : Effectiveness) return Control_Signal;

end ADRC_Ada.Fixed_Control;
