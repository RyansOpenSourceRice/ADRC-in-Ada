--  SPDX-License-Identifier: Apache-2.0

package body ADRC_Ada.NL_ESO with SPARK_Mode is

   procedure Reset (S : out State) is
   begin
      S.Z1 := 0.0;
      S.Z2 := 0.0;
      S.Z3 := 0.0;
   end Reset;

   procedure Step (C : Config; S : in out State; Y : Signal; U : Control_Signal) is
      T : constant Real_Type'Base := C.Ts;
      --  The error is saturated before the fal calls: Fal's pre keeps
      --  the exponentiation inputs inside the bounded-arithmetic
      --  discipline.
      E : constant Signal :=
        Signal (Lim.Saturate (Y - S.Z1, -Max_Magnitude, Max_Magnitude));
      --  Bounded arithmetic: every gain product is saturated into the
      --  signal range before combining. The fal corrections are
      --  saturated inside Fal itself; no intermediate in this library
      --  may exceed Max_Magnitude, and that is what makes every range
      --  check provable by gnatprove.
      P1 : constant Real_Type'Base :=
        Lim.Saturate (C.Beta01 * E, -Max_Magnitude, Max_Magnitude);
      Corr2 : constant Real_Type'Base :=
        Fal_Unit.Fal (E, C.Alpha1, C.Width);
      Corr3 : constant Real_Type'Base :=
        Fal_Unit.Fal (E, C.Alpha2, C.Width);
      P2 : constant Real_Type'Base :=
        Lim.Saturate (C.Beta02 * Corr2, -Max_Magnitude, Max_Magnitude);
      P3 : constant Real_Type'Base :=
        Lim.Saturate (C.Beta03 * Corr3, -Max_Magnitude, Max_Magnitude);
      BU : constant Real_Type'Base :=
        Lim.Saturate (C.B0 * U, -Max_Magnitude, Max_Magnitude);
      Corr1 : constant Real_Type'Base :=
        Lim.Saturate (T * (S.Z2 + P1), -Max_Magnitude, Max_Magnitude);
      Sum2 : constant Real_Type'Base :=
        Lim.Saturate (S.Z3 + P2 + BU, -Max_Magnitude, Max_Magnitude);
      Corr2_Int : constant Real_Type'Base :=
        Lim.Saturate (T * Sum2, -Max_Magnitude, Max_Magnitude);
      Corr3_Int : constant Real_Type'Base :=
        Lim.Saturate (T * P3, -Max_Magnitude, Max_Magnitude);
      Z1_New : constant Real_Type'Base :=
        Lim.Saturate (S.Z1 + Corr1, -Max_Magnitude, Max_Magnitude);
      Z2_New : constant Real_Type'Base :=
        Lim.Saturate (S.Z2 + Corr2_Int, -Max_Magnitude, Max_Magnitude);
      Z3_New : constant Real_Type'Base :=
        Lim.Saturate (S.Z3 + Corr3_Int, -Max_Magnitude, Max_Magnitude);
   begin
      S.Z1 := State_Value (Z1_New);
      S.Z2 := State_Value (Z2_New);
      S.Z3 := State_Value (Z3_New);
   end Step;

end ADRC_Ada.NL_ESO;
