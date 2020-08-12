$ontext
This code has been made free to use, however it would be appreciated if acknowledgements were made to the author, Emon Chatterji.
$offtext

$inlinecom { }
Option OPTCR=0;

Set t hours /0*23/
    m months /1*12/
    d days /1*31/
    y1 years /1998*2018/
    y(y1) selected years /2011/
 ;

display t;

Scalars
*        solar panels cost 283, battery 48
         PanelCost Cost of buying and installing 1 kW /283/
         TaxDiscount Benefit that taxes give to incentivize solar panels /0.7/
         BuyBackRate Rate that you can sell solar energy back to the grid for /0.1483/
         GridCost How much it costs to buy energy from the grid /0.1565/
         Efficiency How much energy the solar panels are capable of producing /0.9/
         BatteryCost cost of buying 1kW of a solar battery not including installation /48/
         ChargeRate how fast the battery can charge as a fraction of what kW has been installed /0.6/
         DischargeRate how much energy the battery can put out as a fraction of what kW has been installed /1/
         BatteryEfficiency how efficient the battery is at taking and giving energy /0.9/
;

Parameters
sunkW Demand while the sun is up
sunkWAvg Average demand while the sun is up
Data(m,d,t,*) Availability of solar energy in kW for 1 installed kW and power demand

;

$Call GDXXRW SolarOptimizerData.xlsx  par=Data  RDim=3 CDim=1 rng=Data!A1:BW1500000
$GDXIN  SolarOptimizerData
$LOAD Data
$GDXIN

display data;

sunkWAvg = sum((y,m,d,t)$(Data(m,d,t,y)>0), Data(m,d,t,"HouseDemand"))/sum((y,m,d,t)$(Data(m,d,t,y)>0), 1);

display sunkWAvg;

Variables

Grid(y,m,d,t) Supply of grid power in kW
Cost Total cost of the power in dollars
Solar(y,m,d,t) How much solar is available
SolarInhouse(y,m,d,t) solar used in house
SolarInstalled What kilowattage of solar panels to be installed
SolarExport(y,m,d,t) Unused solar energy in kWh basically export back to grid
SolarReject(y,m,d,t) solar rejected
BatterykW How big of a battery should be installed
BatteryOut(y,m,d,t) How much kWh is going out of the battery and into the house
BatteryIn(y,m,d,t) How much kWh is going into the battery from the solar panels
BatteryLevel(y,m,d,t) How much energy is in the battery at any given time
;

Positive Variables

Grid, Solar, SolarExport, SolarInhouse, SolarReject, BatterykW, BatteryIn, BatteryOut, BatteryLevel;

Integer Variable SolarInstalled;

Equations

FindCost  Calculates the cost of the entire year's energy usage
GridUse(y,m,d,t)  Determines how much energy comes from the grid every hour
FindUnusedSolar(y,m,d,t)  Finds the amount of solar energy that has not been used so it can be sold back to the grid
FindUnusedSolar1(y,m,d,t)  Finds the amount of solar energy that has not been used so it can be sold back to the grid

ExportCap(y)  Sets a capacity on how much solar energy can be exported
SolarProductionCap(y) Sets solar export to whatever the in-house solar consumption is
BatteryLevelSetter(y,m,d,t) Sets how much charge is in the battery for the first hour of the first day

BatteryLevelSetter1(y,m,d,t) Sets how much charge is in the battery for all other 8736 hours

BatteryInstalled(y,m,d,t) Battery level cannot be higher than whatever has been installed
BatteryChargingRate(y,m,d,t) How much energy the battery can take in at once
BatteryDischargingRate(y,m,d,t) How much energy the battery can give out at once
;

FindCost.. Cost =e= sum((y,m,d,t), (Grid(y,m,d,t)*GridCost - (SolarExport(y,m,d,t)*BuyBackRate)))
                     + (SolarInstalled)*(PanelCost*TaxDiscount)*card(y) +BatteryCost*BatterykW*card(y)
                     + Sum((y,m,d,t), SolarReject(y,m,d,t)*0.001);

GridUse(y,m,d,t).. (Solarinhouse(y,m,d,t))+Grid(y,m,d,t)+BatteryOut(y,m,d,t)*BatteryEfficiency =e= Data(m,d,t,"HouseDemand");

FindUnusedSolar1(y,m,d,t).. Solar(y,m,d,t) =l= Data(m,d,t,y)*SolarInstalled*Efficiency/1000;

FindUnusedSolar(y,m,d,t).. SolarExport(y,m,d,t) + BatteryIn(y,m,d,t) + SolarReject(y,m,d,t) +Solarinhouse(y,m,d,t) =E=  Solar(y,m,d,t);

ExportCap(y).. Sum((m,d,t), SolarExport(y,m,d,t)) =l= Sum((m,d,t), Data(m,d,t,"HouseDemand"));

SolarProductionCap(y).. Sum((m,d,t), SolarExport(y,m,d,t)) =l= Sum((m,d,t), Solarinhouse(y,m,d,t));

BatteryLevelSetter(y,m,d,t)$(ord(t)=1 and ord(d)=1).. BatteryLevel(y,m,d,t) =e= BatteryIn(y,m,d,t) - BatteryOut(y,m,d,t);

BatteryLevelSetter1(y,m,d,t)$(ord(d) ge 1).. BatteryLevel(y,m,d,t) =e= BatteryLevel(y,m,d,t-1) + BatteryIn(y,m,d,t) - BatteryOut(y,m,d,t);

BatteryInstalled(y,m,d,t).. BatteryLevel(y,m,d,t) =l= BatterykW*4;
BatteryChargingRate(y,m,d,t).. BatteryIn(y,m,d,t) =l= BatterykW*chargeRate;
BatteryDischargingRate(y,m,d,t).. BatteryOut(y,m,d,t) =l= BatterykW*dischargeRate;

Model SolarOptimizer /
FindCost
GridUse
FindUnusedSolar
FindUnusedSolar1
*ExportCap
SolarProductionCap
BatteryLevelSetter
BatteryLevelSetter1
BatteryInstalled
BatteryChargingRate
BatteryDischargingRate
/;

SolarOptimizer.optfile=1;

Solve SolarOptimizer using MIP minimizing Cost;

display Grid.l, Solar.l, Batterylevel.l, BatteryOut.l, Cost.l, SolarInstalled.l, BatterykW.l;

Parameters Summary(y,*,*), TotalGridkWh(y), TotalSolarkWh(y), TotalSolarkWh1(y), TotalSolarReject(y), TotalDemandkWh(y), SolarExport1(y), Output(y,m,d,t,*), CostOfSolar(y);


TotalGridkWh(y) = Sum((m,d,t), Grid.l(y,m,d,t));
TotalSolarkWh(y) = Sum((m,d,t), Solarinhouse.l(y,m,d,t));
TotalSolarkWh1(y) = Sum((m,d,t), Solar.l(y,m,d,t) - Data(m,d,t,y)*SolarInstalled.l*Efficiency);
TotalDemandkWh(y) = Sum((m,d,t), Data(m,d,t,"HouseDemand"));
SolarExport1(y) = Sum((m,d,t), SolarExport.l(y,m,d,t));
CostOfSolar(y) = (SolarInstalled.l*PanelCost*TaxDiscount)/(sum((m,d,t), Solar.l(y,m,d,t)+SolarExport.l(y,m,d,t)));

Summary(y,"Annual Cost in $","Value")=sum((m,d,t), Grid.l(y,m,d,t)*GridCost - (SolarExport.l(y,m,d,t)*BuyBackRate))
                    + SolarInstalled.l*(PanelCost*TaxDiscount)+BatteryCost*BatterykW.l
                     + Sum((m,d,t), SolarReject.l(y,m,d,t)*0.001);

Summary(y,"Solar installed in kW", "Value")=SolarInstalled.l;
Summary(y,"Battery installed in kWh", "Value")=BatterykW.l;

Summary(y,"Total Grid Supply in kWh", "Value")=TotalGridkWh(y);
Summary(y,"Total Solar Usage in-house in kWh", "Value")=TotalSolarkWh(y);
Summary(y,"Total Solar Rejected in kWh", "Value")=Sum((m,d,t), SolarReject.l(y,m,d,t))+1e-6;
Summary(y,"Total Solar Resource in kWh", "Value")=Sum((m,d,t), Solar.l(y,m,d,t));

Summary(y,"Total battery output in kWh after efficiency loss", "Value") = Sum((m,d,t),+BatteryOut.l(y,m,d,t)*BatteryEfficiency) ;
Summary(y,"Total battery output in kWh BEFORE efficiency loss", "Value") = Sum((m,d,t),+BatteryOut.l(y,m,d,t)) ;

Summary(y,"Total battery input in kWh", "Value") = Sum((m,d,t),+BatteryIn.l(y,m,d,t)) ;

Summary(y,"Total Solar Export in kWh", "Value")=SolarExport1(y);
Summary(y,"Total Demand in kWh", "Value")=TotalDemandkWh(y);
Summary(y,"Total Solar Rejected in kWh", "Value")=Sum((m,d,t),SolarReject.l(y,m,d,t));

Summary(y,"Ratio of cost of solar installation over solar production", "Value")=CostOfSolar(y);

Output(y,m,d,t,"Grid") = Grid.l(y,m,d,t);
Output(y,m,d,t,"Solar") = SolarInhouse.l(y,m,d,t);


display TotalGridkWh, TotalSolarkWh,TotalSolarkWh1, TotalDemandkWh, SolarExport1, Output;


EXECUTE_UNLOAD 'Summary', Summary, Grid.l, Solar.l, Cost.l, SolarExport.l, SolarInstalled.l, Output;
EXECUTE 'GDXXRW Summary.gdx par=Summary rng=Summary!A5 par=Output rng=HourlyUseFromAll!A5 var=Grid rng=GridSupply!A5 var=Solar rng=Solar-Consumed_Inhouse!A5  var=SolarExport rng=Solar_export!A5 o=SolarOptimizer.xlsx ';



