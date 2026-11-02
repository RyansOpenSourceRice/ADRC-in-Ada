--  SPDX-License-Identifier: Apache-2.0

package body ADRC_Ada.Control with SPARK_Mode is

   function Law
     (Wc     : Bandwidth;
      V1, Z1 : Signal;
      Z2     : Signal;
      Z3     : Signal;
      B0     : Effectiveness) return Control_Signal
   is
      W : constant Real_Type'Base := Wc;
      --  Bounded arithmetic: the proportional and derivative terms are
      --  saturated into the signal range before combining, and the
      --  disturbance-cancellation result is saturated again after the
      --  division. No intermediate in this library may exceed
      --  Max_Magnitude, and that is what makes every range check
      --  provable by gnatprove.
      Prop : constant Real_Type'Base :=
        Lim.Saturate (W * W * (V1 - Z1), -Max_Magnitude, Max_Magnitude);
      Deriv : constant Real_Type'Base :=
        Lim.Saturate (2.0 * W * Z2, -Max_Magnitude, Max_Magnitude);
      U0 : constant Real_Type'Base :=
        Lim.Saturate (Prop - Deriv, -Max_Magnitude, Max_Magnitude);
      Raw : constant Real_Type'Base := (U0 - Z3) / B0;
   begin
      return Control_Signal (Lim.Saturate (Raw, -Max_Magnitude, Max_Magnitude));
   end Law;

end ADRC_Ada.Control;
