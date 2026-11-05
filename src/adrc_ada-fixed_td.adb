--  SPDX-License-Identifier: Apache-2.0

package body ADRC_Ada.Fixed_TD with SPARK_Mode is

   procedure Reset (S : out State; Ref : Signal) is
   begin
      S.V1 := Ref;
      S.V2 := 0.0;
   end Reset;

   procedure Step
     (C   : Config;
      S   : in out State;
      Ref : Signal;
      V1, V2 : out Signal)
   is
      R : constant Signal := C.Rate;
      T : constant Signal := C.Ts;
      E : constant Signal := Lim.S_Sub (Ref, S.V1);
      --  Bounded fixed-point arithmetic: every product and sum is
      --  saturated into the signal range through the exact-universal
      --  helpers of the limits unit. Literal factors are expressed as
      --  sums of products so the interfaces stay free of floating
      --  point: 2 * R * V2 is a sum of two saturated products, which
      --  matches the floating-point clamp at every input.
      Accel_D : constant Signal := Lim.S_Mul (Lim.S_Mul (R, R), E);
      Accel_Damp : constant Signal :=
        Lim.S_Add (Lim.S_Mul (R, S.V2), Lim.S_Mul (R, S.V2));
      Accel : constant Signal := Lim.S_Sub (Accel_D, Accel_Damp);
      New_V1 : constant Signal := Lim.S_Add (S.V1, Lim.S_Mul (T, S.V2));
      New_V2 : constant Signal := Lim.S_Add (S.V2, Lim.S_Mul (T, Accel));
   begin
      S.V1 := New_V1;
      S.V2 := New_V2;
      V1   := S.V1;
      V2   := S.V2;
   end Step;

end ADRC_Ada.Fixed_TD;
