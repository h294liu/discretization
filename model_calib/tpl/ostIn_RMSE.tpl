# Ostrich configuration file
ProgramType  DDS
ModelExecutable ./run_model.sh
ObjectiveFunction gcop

OstrichWarmStart no

PreserveBestModel ./save_best.sh
PreserveModelOutput no
OnObsError	-999

BeginFilePairs    
dummy.tpl; dummy.txt
nc_multiplier.tpl; nc_multiplier.txt
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
_heightCanopyTop_ip_		0.045226	0.0001	1	none   none	none  free
routingGammaScale_mtp			1.0	lwr	upr	none   none	none  free
routingGammaShape_mtp			1.0	lwr	upr	none   none	none  free
EndParams
# Note: _heightCanopyTop_ip_ initial 0.045226 ensures heightCanopyTop=1.

BeginTiedParams
	# 2-parameter linear 
    # Top = Bottom + Top_ip*(20–Bottom) = 0.1*Bottom_mtp + Top_ip*(20–0.1*Bottom_mtp)
    # Top = -0.1*Bottom_mtp*Top_ip + 20*Top_ip + 0.1*Bottom_mtp + 0
	heightCanopyTop_value 2 heightCanopyBottom_mtp _heightCanopyTop_ip_ linear -0.1 20.0 0.1 0.0 free
EndTiedParams

BeginResponseVars
  #name	  filename			      keyword		line	col	token
  RMSE      ./Diagnostics.txt;	      OST_NULL	         1	1  	 ' '
EndResponseVars 

BeginGCOP
  CostFunction RMSE
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
MaxIterations 100
#UseRandomParamValues
UseInitialParamValues
EndDDSAlg

# can attempt this to polish the earlier DDS results (use with WARM start)
#BeginFletchReevesAlg
#ConvergenceVal 1.00E-6
#MaxStalls      3
#MaxIterations  20
#EndFletchReevesAlg
