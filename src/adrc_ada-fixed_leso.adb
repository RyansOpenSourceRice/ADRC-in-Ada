--  SPDX-License-Identifier: Apache-2.0

package body ADRC_Ada.Fixed_LESO with SPARK_Mode is

   procedure Reset (S : out State) is
   begin
      S.Z1 := 0.0;
      S.Z2 := 0.0;
      S.Z3 := 0.0;
   end Reset;

   procedure Step (C : Config; S : in out State; Y : Signal; U : Control_Signal) is
      Wo : constant Signal := C.Wo;
      T  : constant Signal := C.Ts;
      E  : constant Signal := Lim.S_Sub (Y, S.Z1);
      --  Bounded fixed-point arithmetic: the error, the bandwidth-
      --  parameterized gains, and every product term are saturated
      --  into the signal range through the exact-universal helpers of
      --  the limits unit. The 3 wo and 3 wo^2 gains are expressed as
      --  sums and products of saturated terms so the interfaces stay
      --  free of floating point.
      Beta1 : constant Signal := Lim.S_Add (Lim.S_Add (Wo, Wo), Wo);
      Beta2 : constant Signal := Lim.S_Mul (Beta1, Wo);
      Beta3 : constant Signal := Lim.S_Mul (Lim.S_Mul (Wo, Wo), Wo);
      P1 : constant Signal := Lim.S_Mul (Beta1, E);
      P2 : constant Signal := Lim.S_Mul (Beta2, E);
      P3 : constant Signal := Lim.S_Mul (Beta3, E);
      BU : constant Signal := Lim.S_Mul (C.B0, U);
      Sum1 : constant Signal := Lim.S_Add (S.Z2, P1);
      Corr1 : constant Signal := Lim.S_Mul (T, Sum1);
      Sum2 : constant Signal := Lim.S_Add (Lim.S_Add (S.Z3, P2), BU);
      Corr2 : constant Signal := Lim.S_Mul (T, Sum2);
      Corr3 : constant Signal := Lim.S_Mul (T, P3);
      Z1_New : constant Signal := Lim.S_Add (S.Z1, Corr1);
      Z2_New : constant Signal := Lim.S_Add (S.Z2, Corr2);
      Z3_New : constant Signal := Lim.S_Add (S.Z3, Corr3);
   begin
      S.Z1 := Z1_New;
      S.Z2 := Z2_New;
      S.Z3 := Z3_New;
   end Step;

end ADRC_Ada.Fixed_LESO;
