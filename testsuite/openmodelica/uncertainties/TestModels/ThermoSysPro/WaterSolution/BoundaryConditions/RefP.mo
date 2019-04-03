within ThermoSysPro.WaterSolution.BoundaryConditions;
model RefP "Fixed pressure reference"
  parameter ThermoSysPro.Units.AbsolutePressure P0=100000.0 "Fixed fluid pressure";
  annotation(Diagram(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Ellipse(extent={{-40,40},{40,-40}}, fillPattern=FillPattern.Solid, lineColor={0,0,255}, fillColor={223,159,159}),Line(points={{0,100},{0,40}}, color={0,0,255}),Line(points={{20,60},{0,40},{-20,60}}, color={0,0,255}),Line(points={{-90,0},{-40,0}}, color={0,0,255}),Line(points={{40,0},{90,0}}, color={0,0,255}),Text(lineColor={0,0,255}, extent={{-28,30},{28,-26}}, fillColor={0,0,255}, textString="P")}), Icon(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Ellipse(extent={{-40,40},{40,-40}}, fillPattern=FillPattern.Solid, lineColor={0,0,255}, fillColor={223,159,159}),Line(points={{0,100},{0,40}}, color={0,0,255}),Line(points={{20,60},{0,40},{-20,60}}, color={0,0,255}),Line(points={{-90,0},{-40,0}}, color={0,0,255}),Line(points={{40,0},{90,0}}, color={0,0,255}),Text(lineColor={0,0,255}, extent={{-28,30},{28,-26}}, fillColor={0,0,255}, textString="P")}), Documentation(info="<html>
<p><b>Copyright &copy; EDF 2002 - 2010</b></p>
</HTML>
<html>
<p><b>ThermoSysPro Version 2.0</b></p>
</HTML>
", revisions="<html>
<u><p><b>Authors</u> : </p></b>
<ul style='margin-top:0cm' type=disc>
<li>
    Beno�t Bride</li>
<li>
    Daniel Bouskela</li>
</html>
"), DymolaStoredErrors);
  Connectors.WaterSolutionInlet C1 annotation(Placement(transformation(x=-100.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=-100.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  Connectors.WaterSolutionOutlet C2 annotation(Placement(transformation(x=100.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=100.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.InstrumentationAndControl.Connectors.InputReal IPressure annotation(Placement(transformation(x=0.0, y=110.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false, rotation=-270.0), iconTransformation(x=0.0, y=110.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false, rotation=-270.0)));
equation
  if cardinality(IPressure) == 0 then
    IPressure.signal=P0;
  end if;
  C1.P=C2.P;
  C1.T=C2.T;
  C1.Q=C2.Q;
  C1.Xh2o=C2.Xh2o;
  C1.P=IPressure.signal;
end RefP;
