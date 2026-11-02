--  SPDX-License-Identifier: Apache-2.0

package body ADRC_Ada.TD with SPARK_Mode is

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
      R : constant Real_Type'Base := C.Rate;
      T : constant Real_Type'Base := C.Ts;
      E : constant Real_Type'Base := Ref - S.V1;
      --  Bounded arithmetic: every product term is saturated into the
      --  signal range before combining. No intermediate in this library
      --  may exceed Max_Magnitude, and that is what makes every range
      --  check provable by gnatprove.
      Accel_D : constant Real_Type'Base :=
        Lim.Saturate (R * R * E, -Max_Magnitude, Max_Magnitude);
      Accel_Damp : constant Real_Type'Base :=
        Lim.Saturate (2.0 * R * S.V2, -Max_Magnitude, Max_Magnitude);
      Accel : constant Real_Type'Base :=
        Lim.Saturate (Accel_D - Accel_Damp, -Max_Magnitude, Max_Magnitude);
      New_V1 : constant Real_Type'Base :=
        Lim.Saturate (S.V1 + T * S.V2, -Max_Magnitude, Max_Magnitude);
      New_V2 : constant Real_Type'Base :=
        Lim.Saturate (S.V2 + T * Accel, -Max_Magnitude, Max_Magnitude);
   begin
      S.V1 := Signal (New_V1);
      S.V2 := Signal (New_V2);
      V1   := S.V1;
      V2   := S.V2;
   end Step;

end ADRC_Ada.TD;
