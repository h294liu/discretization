# Ostrich configuration file
ProgramType  PADDS
ModelExecutable ./run_trial.sh
ObjectiveFunction gcop

OstrichWarmStart no

PreserveBestModel ./save_best.sh
PreserveModelOutput yes
OnObsError	-999

BeginFilePairs
./tpl/nc_multiplier.tpl; nc_multiplier.txt
EndFilePairs

#Parameter/DV Specification
BeginParams
#parameter                      init    lwr     upr     txInN  txOst    txOut fmt
k_macropore_mtp                 1.0     lwr     upr     none   none     none  free
k_soil_mtp                      1.0     lwr     upr     none   none     none  free
theta_sat_mtp                   1.0     lwr     upr     none   none     none  free
aquiferBaseflowExp_mtp  1.0     lwr     upr     none   none     none  free
aquiferBaseflowRate_mtp 1.0     lwr     upr     none   none     none  free
qSurfScale_mtp                  1.0     lwr     upr     none   none     none  free
summerLAI_mtp                   1.0     lwr     upr     none   none     none  free
frozenPrecipMultip_mtp          1.0     lwr     upr     none   none     none  free
heightCanopyBottom_mtp          1.0     0.01    upr     none   none     none  free
thickness_mtp                   1.0     0.01    upr     none   none     none  free
routingGammaScale_mtp           1.0     lwr     upr     none   none     none  free
routingGammaShape_mtp           1.0     lwr     upr     none   none     none  free
EndParams

BeginResponseVars
# name    filename               keyword   line   col  token
  KGE      ./trial_stats.txt;   OST_NULL      0     1    ' '
  mmmErr   ./trial_stats.txt;   OST_NULL      5     1    ' '
EndResponseVars 

BeginTiedRespVars
  NegKGE 1 KGE wsum -1.00
EndTiedRespVars

BeginGCOP
  CostFunction NegKGE
  CostFunction mmmErr
  PenaltyFunction APM
EndGCOP

BeginConstraints
# not needed when no constraints, but PenaltyFunction statement above is required
# name     type     penalty    lwr   upr   resp.var
EndConstraints

# Randomsed control added
RandomSeed xxxxxxxxx

BeginPADDSAlg
PerturbationValue      0.2
MaxIterations          10 #50
SelectionMetric        ExactHyperVolumeContribution
EndPADDSAlg
