--  SPDX-License-Identifier: Apache-2.0

package body ADRC_Ada.Fixed_Control with SPARK_Mode is

   function Law
     (Wc     : Bandwidth;
      V1, Z1 : Signal;
      Z2     : Signal;
      Z3     : Signal;
      B0     : Effectiveness) return Control_Signal
   is
      W : constant Signal := Wc;
      --  Bounded fixed-point arithmetic: the proportional and
      --  derivative terms are saturated into the signal range through
      --  the exact-universal helpers of the limits unit, the factor-2
      --  term is a sum of two saturated products, and the disturbance
      --  cancellation multiplies by the reciprocal of the
      --  effectiveness (a quotient of a wide dividend leaves the
      --  universal intermediate before any clamp; the reciprocal of a
      --  floored divisor stays inside it).
      D : constant Signal := Lim.S_Sub (V1, Z1);
      Prop : constant Signal := Lim.S_Mul (Lim.S_Mul (W, W), D);
      Deriv : constant Signal :=
        Lim.S_Add (Lim.S_Mul (W, Z2), Lim.S_Mul (W, Z2));
      U0 : constant Signal := Lim.S_Sub (Prop, Deriv);
      Err : constant Signal := Lim.S_Sub (U0, Z3);
      Raw : constant Signal := Lim.S_Mul (Err, Lim.S_Recip (B0));
   begin
      return Raw;
   end Law;

end ADRC_Ada.Fixed_Control;
