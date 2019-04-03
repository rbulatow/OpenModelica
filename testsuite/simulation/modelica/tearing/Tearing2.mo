model Tearing2 "Example from Book Continous System Simulation by F. Cellier page 288?"
  Real u0;
  Real u1;
  Real u2;
  Real uL;
  Real uC;
  Real i0;
  Real i1;
  Real i2(start=0);
  Real iL(start=0, fixed=true);
  Real iC;
  Real v0;
  Real v1;
  Real v2;
  parameter Real R1=1;
  parameter Real R2=2;
  parameter Real L=0.5;
  parameter Real C=3;
equation
  u0 = cos(time);
  u0 = v1 - v0;
  u1 = R1*i1;
  u1 = v1 - v2;
  u2 = R2*i2;
  u2 = v2 - v0;
  uL = L*der(iL);
  uL = v2 - v0;
  iC = C*der(uC);
  uC = v1 - v0;
  v0 = 0;
  i0 = i1 + iC;
  i1 = i2 + iL;
end Tearing2;
