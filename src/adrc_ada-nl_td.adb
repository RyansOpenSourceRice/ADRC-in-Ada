--  SPDX-License-Identifier: Apache-2.0

with Ada.Numerics.Generic_Elementary_Functions;

package body ADRC_Ada.NL_TD with SPARK_Mode is

   package Elem is new Ada.Numerics.Generic_Elementary_Functions (Real_Type);

   function Fhan
     (E1, E2 : Signal; Rate : Bandwidth; H0 : Sample_Time) return Signal
   is
      R : constant Real_Type'Base := Rate;
      H : constant Real_Type'Base := H0;
      --  The synthesis parameters stay unsaturated: both factors carry
      --  strictly positive subtypes, so D is provably positive by
      --  interval arithmetic, which is what the final division needs.
      D : constant Real_Type'Base := R * H;
      D0 : constant Real_Type'Base := H * D;
      --  Every term below stays inside the interval bounds by
      --  construction (bounded inputs, bounded windows); the one
      --  exception is the square root, whose elementary-function
      --  result is an assumption until Saturate re-establishes the
      --  bound.
      Y : constant Real_Type'Base := E1 + H * E2;
      Abs_Y : constant Real_Type'Base := abs Y;
      Sign_Y : constant Real_Type'Base :=
        (if Y >= 0.0 then 1.0 else -1.0);
      DD : constant Real_Type'Base := D * D;
      RY : constant Real_Type'Base := R * Abs_Y;
      Rad : constant Real_Type'Base := 8.0 * RY;
      Sum : constant Real_Type'Base := DD + Rad;
      A0 : constant Real_Type'Base :=
        Lim.Saturate (Elem.Sqrt (Sum), -Max_Magnitude, Max_Magnitude);
      --  The synthesized acceleration: outside the d0 region, the
      --  square-root branch; inside it, the linear branch Y/H.
      Root_Term : constant Real_Type'Base := 0.5 * (A0 - D) * Sign_Y;
      Linear_Term : constant Real_Type'Base := Y / H;
      A : constant Real_Type'Base :=
        (if abs Y > D0 then E2 + Root_Term else E2 + Linear_Term);
      Sign_A : constant Real_Type'Base :=
        (if A >= 0.0 then 1.0 else -1.0);
   begin
      --  Branch structure mirrors the synthesis law so each post
      --  argument stays a small interval fact: on the saturated branch
      --  the magnitude is exactly R; on the linear branch the
      --  synthesis output is clamped to +/- R by construction, which
      --  is what the post condition restates.
      if abs A > D then
         return Signal (-R * Sign_A);
      else
         return
           Signal (Lim.Saturate (-R * (A / D), -Rate, Rate));
      end if;
   end Fhan;

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
      T : constant Real_Type'Base := C.Ts;
      E : constant Real_Type'Base :=
        Lim.Saturate (S.V1 - Ref, -Max_Magnitude, Max_Magnitude);
      Accel : constant Real_Type'Base := Fhan (E, S.V2, C.Rate, C.Filter);
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

end ADRC_Ada.NL_TD;
