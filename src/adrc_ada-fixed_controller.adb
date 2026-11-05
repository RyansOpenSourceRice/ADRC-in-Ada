--  SPDX-License-Identifier: Apache-2.0

package body ADRC_Ada.Fixed_Controller with SPARK_Mode is

   procedure Reset (S : out State; Ref : Signal) is
   begin
      Diff_Unit.Reset (S.Diff, Ref);
      Obs_Unit.Reset (S.Obs);
      S.Last_U := 0.0;
   end Reset;

   procedure Step
     (C   : Config;
      S   : in out State;
      Ref : Signal;
      Y   : Signal;
      U   : out Control_Signal)
   is
      Diff_Cfg : constant Diff_Unit.Config :=
        (Rate => C.TD_Bandwidth, Ts => C.Ts);
      Obs_Cfg : constant Obs_Unit.Config :=
        (Wo => C.Wo, B0 => C.B0, Ts => C.Ts);
      V1, V2 : Signal;
   begin
      Diff_Unit.Step (Diff_Cfg, S.Diff, Ref, V1, V2);
      Obs_Unit.Step (Obs_Cfg, S.Obs, Y, S.Last_U);
      U := Law_Unit.Law (C.Wc, V1, S.Obs.Z1, S.Obs.Z2, S.Obs.Z3, C.B0);
      S.Last_U := U;
   end Step;

end ADRC_Ada.Fixed_Controller;
