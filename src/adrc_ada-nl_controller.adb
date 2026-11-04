--  SPDX-License-Identifier: Apache-2.0

package body ADRC_Ada.NL_Controller with SPARK_Mode is

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
        (Rate => C.TD_Rate, Filter => C.TD_Filter, Ts => C.Ts);
      Obs_Cfg : constant Obs_Unit.Config :=
        (Beta01 => C.Beta01, Beta02 => C.Beta02, Beta03 => C.Beta03,
         Alpha1 => C.Eso_Alpha1, Alpha2 => C.Eso_Alpha2,
         Width => C.Eso_Width, B0 => C.B0, Ts => C.Ts);
      Law_Cfg : constant Law_Unit.Config :=
        (Beta1 => C.Beta1, Beta2 => C.Beta2,
         Alpha1 => C.Ctl_Alpha1, Alpha2 => C.Ctl_Alpha2,
         Width => C.Ctl_Width, B0 => C.B0);
      V1, V2 : Signal;
   begin
      Diff_Unit.Step (Diff_Cfg, S.Diff, Ref, V1, V2);
      Obs_Unit.Step (Obs_Cfg, S.Obs, Y, S.Last_U);
      U := Law_Unit.Law (Law_Cfg, V1, S.Obs.Z1, V2, S.Obs.Z2, S.Obs.Z3);
      S.Last_U := U;
   end Step;

end ADRC_Ada.NL_Controller;
