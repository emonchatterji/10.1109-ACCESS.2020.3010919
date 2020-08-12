$ontext
This code has been made free to use, however it would be appreciated if acknowledgements were made to the author, Emon Chatterji.
$offtext

$inlinecom { }
Option OPTCR=0;

Set t hours /0*23/
    m months /1*12/
    d days /1*31/
    y1 years /1998*2018/
    y(y1) selected years /2001/
    t1(t) hours the supercharge cannot be applied to /1, 2, 3, 4, 22, 23/
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
         EVBottomLimit minimum charge in kWh the vehicle can hold /12/
         EVUpperLimit maximim charge the vehicle can hold /60/
         SuperChargeCost cost of using supercharge /0.6/
         TariffOption defines the pricing scenario: 1 Special Tariff 2 TOU 3 constant /3/
         EVDistance how much energy the EV loses each hour /3/
;

Parameters
sunkW Demand while the sun is up
Tariff(y,m,d,t) Grid Pricing Scenario

$ontext
probability(y) Stochastic probability for each year according to annual solar output /
1998 = 0.046728972,
1999 = 0.037383178,
2000 = 0.065420561,
2001 = 0.037383178,
2002 = 0.065420561,
2003 = 0.009345794,
2004 = 0.037383178,
2005 = 0.046728972,
2006 = 0.065420561,
2007 = 0.065420561,
2008 = 0.046728972,
2009 = 0.037383178,
2010 = 0.037383178,
2011 = 0.037383178,
2012 = 0.065420561,
2013 = 0.046728972,
2014 = 0.065420561,
2015 = 0.046728972,
2016 = 0.037383178,
2017 = 0.065420561,
2018 = 0.037383178
/
$offtext

sunkWAvg Average demand while the sun is up
Data(m,d,t,*) Availability of solar energy in kW for 1 installed kW and power demand

;

$Call GDXXRW SolarOptimizerData.xlsx  par=Data  RDim=3 CDim=1 rng=Data!A1:BW1500000
$GDXIN  SolarOptimizerData
$LOAD Data
$GDXIN

display data;

Tariff(y,m,d,t)$(TariffOption=1)=Data(m,d,t,"SpecialTariff");
Tariff(y,m,d,t)$(TariffOption=2)=Data(m,d,t,"TOU");
Tariff(y,m,d,t)$(TariffOption=3)=GridCost;

sunkWAvg = sum((y,m,d,t)$(Data(m,d,t,y)>0), Data(m,d,t,"HouseDemand"))/sum((y,m,d,t)$(Data(m,d,t,y)>0), 1);

display sunkWAvg;

Variables

SuperCharge(y,m,d,t) hours that the car is being supercharged
chargeMode(y,m,d) allows the model to select a charging pattern (slow or medium speed charging)
EVentering(y,m,d,t) kW entering the EV to allow it to go places
EVstored(y,m,d,t) kWh stored in the EV (cannot be less than 12kWh)
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

Grid, Solar, SolarExport, SolarInhouse, SolarReject, BatterykW, BatteryIn, BatteryOut, BatteryLevel, EVentering, EVstored, SuperCharge;

Binary Variable chargeMode;

Integer Variable SolarInstalled;

SuperCharge.up(y,m,d,t) = 72;
SuperCharge.fx(y,m,d,t1) = 0;
EVentering.fx(y,m,d,t)$(Data(m,d,t,"ChargingHours")=0)=0;

Equations

FindCost  Calculates the cost of the entire year's energy usage
GridUse(y,m,d,t)  Determines how much energy comes from the grid every hour
FindUnusedSolar(y,m,d,t)  Finds the amount of solar energy that has not been used so it can be sold back to the grid
FindUnusedSolar1(y,m,d,t)  Finds the amount of solar energy that has not been used so it can be sold back to the grid

ExportCap(y)  Sets a capacity on how much solar energy can be exported
SolarProductionCap(y) Sets solar export to whatever the in-house solar consumption is
BatteryLevelSetter(y,m,d,t) Sets how much charge is in the battery for the first hour of the first day
*BatteryLevelSetter1a(y,m,d,t) Sets how much charge is in the battery for all other 23 hours of day1

BatteryLevelSetter1(y,m,d,t) Sets how much charge is in the battery for all other 8736 hours

BatteryInstalled(y,m,d,t) Battery level cannot be higher than whatever has been installed
BatteryChargingRate(y,m,d,t) How much energy the battery can take in at once
BatteryDischargingRate(y,m,d,t) How much energy the battery can give out at once

EVBottomLimiter(y,m,d,t) Electric vehicle charge cannot go below 12 kWh
EVUpperLimiter(y,m,d,t) Electric vehicle charge cannot exceed 60 kWh
EVChargeRateSelection(y,m,d,t) What kind of charging pattern the electric vehicle uses
EVChargeAddition(y,m,d,t) Charge entering the EV
EVChargeAdditionHOUR1(y,m,d,t) Charge entering the vehicle on the first hour of the first day
EVChargeAdditionDAY1(y,m,d,t) Charge for the first day
EVDischarge(y,m,d,t) Charge exiting the EV
EVChangeofDay(y,m,d,t) storage status as day changes

;
FindCost.. Cost =e= sum((y,m,d,t), (Grid(y,m,d,t)*Tariff(y,m,d,t) - (SolarExport(y,m,d,t)*BuyBackRate)) +SuperCharge(y,m,d,t)*SuperChargeCost)
                     + (SolarInstalled)*(PanelCost*TaxDiscount)*card(y) +BatteryCost*BatterykW*card(y)
                     + Sum((y,m,d,t), SolarReject(y,m,d,t)*0.001) +sum((y,m,d), ChargeMode(y,m,d)*0.1);

GridUse(y,m,d,t).. (Solarinhouse(y,m,d,t))+Grid(y,m,d,t)+BatteryOut(y,m,d,t)*BatteryEfficiency =e= Data(m,d,t,"HouseDemand") + EVentering(y,m,d,t);

FindUnusedSolar1(y,m,d,t).. Solar(y,m,d,t) =l= Data(m,d,t,y)*SolarInstalled*Efficiency/1000;

FindUnusedSolar(y,m,d,t).. SolarExport(y,m,d,t) + BatteryIn(y,m,d,t) + SolarReject(y,m,d,t) +Solarinhouse(y,m,d,t) =E=  Solar(y,m,d,t);
*l= Sum((m,d,t), Data(y,m,d,t,"DemandkW"))
ExportCap(y).. Sum((m,d,t), SolarExport(y,m,d,t)) =l= 0;

SolarProductionCap(y).. Sum((m,d,t), SolarExport(y,m,d,t)) =l= Sum((m,d,t), Solarinhouse(y,m,d,t));

BatteryLevelSetter(y,m,d,t)$(ord(t)=1 and ord(d)=1).. BatteryLevel(y,m,d,t) =e= BatteryIn(y,m,d,t) - BatteryOut(y,m,d,t);

*BatteryLevelSetter1a(y,m,d,t)$(ord(d)=1 and ord(t)>1).. BatteryLevel(y,m,d,t) =e= BatteryLevel(y,m,d,t-1) + BatteryIn(y,m,d,t) - BatteryOut(y,m,d,t);

BatteryLevelSetter1(y,m,d,t)$(ord(d) ge 1).. BatteryLevel(y,m,d,t) =e= BatteryLevel(y,m,d,t-1) + BatteryIn(y,m,d,t) - BatteryOut(y,m,d,t);

BatteryInstalled(y,m,d,t).. BatteryLevel(y,m,d,t) =l= BatterykW*4;
BatteryChargingRate(y,m,d,t).. BatteryIn(y,m,d,t) =l= BatterykW*chargeRate;
BatteryDischargingRate(y,m,d,t).. BatteryOut(y,m,d,t) =l= BatterykW*dischargeRate;


EVBottomLimiter(y,m,d,t).. EVstored(y,m,d,t) =g= EVBottomLimit;
EVUpperLimiter(y,m,d,t).. EVstored(y,m,d,t) =l= EVUpperLimit;

EVChargeRateSelection(y,m,d,t)$(Data(m,d,t,"ChargingHours")=1 and Data(m,d,t,"HouseDemand")).. EVentering(y,m,d,t) =l= 1.65*(1-chargeMode(y,m,d)) + 6.6*(chargeMode(y,m,d));
EVChargeAddition(y,m,d,t)$((Data(m,d,t,"ChargingHours")=1 and ord(d)>1) and ord(t)>1 and Data(m,d,t,"HouseDemand") and ord(m)>1).. EVstored(y,m,d,t) =e= EVstored(y,m,d,t-1) + EVentering(y,m,d,t) + SuperCharge(y,m,d,t);
EVChargeAdditionHOUR1(y,m,d,t)$(Data(m,d,t,"ChargingHours")=1 and ord(t)=1 and ord(d)=1 and ord(m)=1).. EVstored(y,m,d,t) =e= EVentering(y,m,d,t) + EVBottomLimit;
EVChargeAdditionDAY1(y,m,d,t)$(Data(m,d,t,"ChargingHours")=1 and ord(t)>1 and ord(d) ge 1 and ord(m)=1).. EVstored(y,m,d,t) =e= EVentering(y,m,d,t) + EVstored(y,m,d,t-1) + SuperCharge(y,m,d,t);

EVDischarge(y,m,d,t)$(Data(m,d,t,"ChargingHours")=0 and Data(m,d,t,"HouseDemand") and ord(t)>1).. EVstored(y,m,d,t) =e= EVstored(y,m,d,t-1) - EVDistance;

EVChangeofDay(y,m,d,t)$(ord(d)>1)..  EVstored(y,m,d,"1") =e= EVstored(y,m,d-1,"23");


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
EVBottomLimiter
EVUpperLimiter
EVChargeRateSelection
EVChargeAddition
EVChargeAdditionHOUR1
EVChargeAdditionDAY1
EVDischarge
EVChangeofDay
/;

SolarOptimizer.optfile=1;

Solve SolarOptimizer using RMIP minimizing Cost;

display Grid.l, Solar.l, Batterylevel.l, BatteryOut.l, Cost.l, SolarInstalled.l, BatterykW.l, chargeMode.l;

Parameters Summary(y,*,*), TotalGridkWh(y), TotalSolarkWh(y), TotalSolarkWh1(y), TotalSolarReject(y), TotalDemandkWh(y), SolarExport1(y), Output(y,m,d,t,*), CostOfSolar(y), HoursFastCharged, EVDemand(t);

HoursFastCharged = Sum((y,m,d,t),EVEntering.l(y,m,d,t)*ChargeMode.l(y,m,d));
TotalGridkWh(y) = Sum((m,d,t), Grid.l(y,m,d,t));
TotalSolarkWh(y) = Sum((m,d,t), Solarinhouse.l(y,m,d,t));
TotalSolarkWh1(y) = Sum((m,d,t), Solar.l(y,m,d,t) - Data(m,d,t,y)*SolarInstalled.l*Efficiency);
TotalDemandkWh(y) = Sum((m,d,t), Data(m,d,t,"HouseDemand"));
SolarExport1(y) = Sum((m,d,t), SolarExport.l(y,m,d,t));
CostOfSolar(y) = (SolarInstalled.l*PanelCost*TaxDiscount)/(sum((m,d,t), Solar.l(y,m,d,t)+SolarExport.l(y,m,d,t)));
EVDemand(t) = Sum((y,m,d),1e-6+ EVentering.l(y,m,d,t))/(card(y)*card(m)*card(d));

Summary(y,"Annual Cost in $","Value")=sum((m,d,t), Grid.l(y,m,d,t)*Tariff(y,m,d,t) - (SolarExport.l(y,m,d,t)*BuyBackRate +SuperCharge.l(y,m,d,t)*SuperChargeCost))
                    + SolarInstalled.l*(PanelCost*TaxDiscount)+BatteryCost*BatterykW.l
                     + Sum((m,d,t), SolarReject.l(y,m,d,t)*0.001)+sum((m,d), ChargeMode.l(y,m,d)*0.1);

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


display TotalGridkWh, TotalSolarkWh,TotalSolarkWh1, TotalDemandkWh, SolarExport1, Output, EVStored.l,HoursFastCharged, EVDemand;


EXECUTE_UNLOAD 'Summary', Summary, Grid.l, Solar.l, Cost.l, SolarExport.l, SolarInstalled.l, Output, EVEntering.l, EVStored.l, ChargeMode.l, SuperCharge.l, EVDemand;
EXECUTE 'GDXXRW Summary.gdx par=Summary rng=Summary!A5 par=Output rng=HourlyUseFromAll!A5 var=Grid rng=GridSupply!A5 var=Solar rng=Solar-Consumed_Inhouse!A5  var=SolarExport rng=Solar_export!A5 var=EVEntering rng=EVEntering!A5 var=EVStored rng=EVStored!A5 var=ChargeMode rng=ChargeMode!A5 var=SuperCharge rng=SuperCharge!A5 par=EVDemand rng=DemandIncludingEV!A5 o=SolarOptimizer.xlsx ';



