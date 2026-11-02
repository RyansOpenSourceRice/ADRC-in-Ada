--  SPDX-License-Identifier: Apache-2.0

package body ADRC_Ada.LESO with SPARK_Mode is

   procedure Reset (S : out State) is
   begin
      S.Z1 := 0.0;
      S.Z2 := 0.0;
      S.Z3 := 0.0;
   end Reset;

   procedure Step (C : Config; S : in out State; Y : Signal; U : Control_Signal) is
      Wo : constant Real_Type'Base := C.Wo;
      T  : constant Real_Type'Base := C.Ts;
      E  : constant Real_Type'Base := Y - S.Z1;
      --  Bounded arithmetic: the error, the bandwidth-parameterized
      --  gains, and every product term are saturated into the signal
      --  range before combining. No intermediate in this library may
      --  exceed Max_Magnitude, and that is what makes every range check
      --  provable by gnatprove.
      BE : constant Real_Type'Base :=
        Lim.Saturate (E, -Max_Magnitude, Max_Magnitude);
      Beta1 : constant Real_Type'Base :=
        Lim.Saturate (3.0 * Wo, -Max_Magnitude, Max_Magnitude);
      Beta2 : constant Real_Type'Base :=
        Lim.Saturate (3.0 * Wo * Wo, -Max_Magnitude, Max_Magnitude);
      Beta3 : constant Real_Type'Base :=
        Lim.Saturate (Wo * Wo * Wo, -Max_Magnitude, Max_Magnitude);
      P1 : constant Real_Type'Base :=
        Lim.Saturate (Beta1 * BE, -Max_Magnitude, Max_Magnitude);
      P2 : constant Real_Type'Base :=
        Lim.Saturate (Beta2 * BE, -Max_Magnitude, Max_Magnitude);
      P3 : constant Real_Type'Base :=
        Lim.Saturate (Beta3 * BE, -Max_Magnitude, Max_Magnitude);
      BU : constant Real_Type'Base :=
        Lim.Saturate (C.B0 * U, -Max_Magnitude, Max_Magnitude);
      Corr1 : constant Real_Type'Base :=
        Lim.Saturate (T * (S.Z2 + P1), -Max_Magnitude, Max_Magnitude);
      Sum2 : constant Real_Type'Base :=
        Lim.Saturate (S.Z3 + P2 + BU, -Max_Magnitude, Max_Magnitude);
      Corr2 : constant Real_Type'Base :=
        Lim.Saturate (T * Sum2, -Max_Magnitude, Max_Magnitude);
      Corr3 : constant Real_Type'Base :=
        Lim.Saturate (T * P3, -Max_Magnitude, Max_Magnitude);
      Z1_New : constant Real_Type'Base :=
        Lim.Saturate (S.Z1 + Corr1, -Max_Magnitude, Max_Magnitude);
      Z2_New : constant Real_Type'Base :=
        Lim.Saturate (S.Z2 + Corr2, -Max_Magnitude, Max_Magnitude);
      Z3_New : constant Real_Type'Base :=
        Lim.Saturate (S.Z3 + Corr3, -Max_Magnitude, Max_Magnitude);
   begin
      S.Z1 := State_Value (Z1_New);
      S.Z2 := State_Value (Z2_New);
      S.Z3 := State_Value (Z3_New);
   end Step;

end ADRC_Ada.LESO;
