--  SPDX-License-Identifier: Apache-2.0

package body ADRC_Ada.NL_Control with SPARK_Mode is

   function Law (C : Config; V1, Z1, V2, Z2, Z3 : Signal) return Control_Signal is
      --  The errors are saturated before the fal calls: Fal's pre
      --  keeps the exponentiation inputs inside the bounded-arithmetic
      --  discipline.
      E1 : constant Signal :=
        Signal (Lim.Saturate (V1 - Z1, -Max_Magnitude, Max_Magnitude));
      E2 : constant Signal :=
        Signal (Lim.Saturate (V2 - Z2, -Max_Magnitude, Max_Magnitude));
      --  Bounded arithmetic: each fal-shaped gain product is saturated
      --  into the signal range before combining, and the disturbance
      --  cancellation result is saturated after the division.
      T1 : constant Real_Type'Base :=
        Lim.Saturate
          (C.Beta1 * Fal_Unit.Fal (E1, C.Alpha1, C.Width),
           -Max_Magnitude, Max_Magnitude);
      T2 : constant Real_Type'Base :=
        Lim.Saturate
          (C.Beta2 * Fal_Unit.Fal (E2, C.Alpha2, C.Width),
           -Max_Magnitude, Max_Magnitude);
      U0 : constant Real_Type'Base :=
        Lim.Saturate (T1 + T2, -Max_Magnitude, Max_Magnitude);
      Raw : constant Real_Type'Base := (U0 - Z3) / C.B0;
   begin
      return
        Control_Signal
          (Lim.Saturate (Raw, -Max_Magnitude, Max_Magnitude));
   end Law;

end ADRC_Ada.NL_Control;
