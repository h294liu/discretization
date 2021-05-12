# Ostrich configuration file
# AWW-feb202: added routing params
# AWW/HL-may2020: added canopy params (bottom/top/thickness)
# AWW-oct2020: added Fcapil
ProgramType  DDS
ModelExecutable ./run_model_calib.sh
ObjectiveFunction gcop

OstrichWarmStart no

PreserveBestModel ./save_best.sh
PreserveModelOutput no
OnObsError	-999

BeginFilePairs    
./tpl/nc_multiplier.2.tpl; nc_multiplier.txt
EndFilePairs

#Parameter/DV Specification
BeginParams
#parameter			init	lwr	upr	txInN  txOst 	txOut fmt  
k_macropore_mtp			1.0	lwr	upr	none   none	none  free
k_soil_mtp			1.0	lwr	upr	none   none	none  free
theta_sat_mtp			1.0	lwr	upr	none   none	none  free
aquiferBaseflowExp_mtp	1.0	lwr	upr	none   none	none  free
aquiferBaseflowRate_mtp	1.0	lwr	upr	none   none	none  free
qSurfScale_mtp			1.0	lwr	upr	none   none	none  free
summerLAI_mtp			1.0	lwr	upr	none   none	none  free	
frozenPrecipMultip_mtp		1.0	lwr	upr	none   none	none  free	
heightCanopyBottom_mtp		1.0	0.01	upr	none   none	none  free
thickness_mtp			1.0	0.01	upr	none   none	none  free
routingGammaScale_mtp		1.0	lwr	upr	none   none	none  free
routingGammaShape_mtp		1.0	lwr	upr	none   none	none  free
Fcapil_mtp			1.0	lwr	upr	none   none	none  free
EndParams

BeginResponseVars
  #name	  filename			      keyword		line	col	token
  KGE      ./trial_stats.txt;	      OST_NULL	         0	1  	 ' '
EndResponseVars 

BeginTiedRespVars
  NegKGE 1 KGE wsum -1.00
EndTiedRespVars

BeginGCOP
  CostFunction NegKGE
  PenaltyFunction APM
EndGCOP

BeginConstraints
# not needed when no constraints, but PenaltyFunction statement above is required
# name     type     penalty    lwr   upr   resp.var
EndConstraints

# Randomsed control added
RandomSeed xxxxxxxxx

BeginDDSAlg
PerturbationValue 0.20
MaxIterations MAXITER
#UseRandomParamValues
UseInitialParamValues
EndDDSAlg

# can attempt this to polish the earlier DDS results (use with WARM start)
#BeginFletchReevesAlg
#ConvergenceVal 1.00E-6
#MaxStalls      3
#MaxIterations  20
#EndFletchReevesAlg
