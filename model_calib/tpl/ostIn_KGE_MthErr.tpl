# Ostrich configuration file
ProgramType  PADDS
ModelExecutable ./run_trials.sh
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
# Note: _heightCanopyTop_ip_ initial 0.045226 ensures heightCanopyTop=1.
EndParams

BeginTiedParams
	# 2-parameter linear 
    # Top = Bottom + Top_ip*(20–Bottom) = 0.1*Bottom_mtp + Top_ip*(20–0.1*Bottom_mtp)
    # Top = -0.1*Bottom_mtp*Top_ip + 20*Top_ip + 0.1*Bottom_mtp + 0
	heightCanopyTop_value 2 heightCanopyBottom_mtp _heightCanopyTop_ip_ linear -0.1 20.0 0.1 0.0 free
EndTiedParams

BeginResponseVars
  #name	  filename			      keyword		line	col	token
  KGE      ./Diagnostics.txt;	      OST_NULL	         0	1  	 ' '
  MthE     ./Diagnostics.txt;	      OST_NULL	         2	1  	 ' '
EndResponseVars 

BeginTiedRespVars
  NegKGE 1 KGE wsum -1.00
EndTiedRespVars

BeginGCOP
  CostFunction NegKGE
  CostFunction MthE
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
