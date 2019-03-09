/////////////////////////////////////////////////////////////////////////////////////////
// TYPES OF ALLEGATIONS
/////////////////////////////////////////////////////////////////////////////////////////

cd "$location_cleaned_data"

use "210117 CC  WW  SS GEO RATING RANK LM.dta", clear //


tab timeq //from 2011q2


//========================================
// ALLEGATIONS
//========================================


*Failirues in duty
*------------------
*TypeDes_1                       TypeDesc-Breach Code A PACE
*TypeDes_2                       TypeDesc-Breach Code B PACE
*TypeDes_3                       TypeDesc-Breach Code C PACE
*TypeDes_4                       TypeDesc-Breach Code D PACE
*TypeDes_5                       TypeDesc-Breach Code E PACE
*TypeDes_13                      TypeDesc-Multiple or unspecified breaches of
*TypeDes_8                       TypeDesc-Improper disclosure of information
*TypeDes_14                      TypeDesc-Oppressive conduct or harassment
*TypeDes_16                      TypeDesc-Other assault
*TypeDes_17                      TypeDesc-Other irregularity in procedure
*TypeDes_18                      TypeDesc-Other neglect or failure in duty


*Malpractice
*-------------

*TypeDes_6                       TypeDesc-Corrupt practice
*TypeDes_12                      TypeDesc-Mishandling of property
*TypeDes_10                      TypeDesc-Irregularity in evidence/perjury

*discriminicatory behaviour
*-------------------------------
*TypeDes_7                       TypeDesc-Discriminatory Behaviour
*TypeDes_11                      TypeDesc-Lack of fairness and impartiality


*Incivility
*----------------
*TypeDes_9                       TypeDesc-Incivility, impoliteness


*Other
*--------
*TypeDes_15                      TypeDesc-Other

*Oppressice behaviour
*----------------------
*TypeDes_19                      TypeDesc-Other sexual conduct
*TypeDes_20                      TypeDesc-Serious non-sexual assault
*TypeDes_21                      TypeDesc-Sexual assault
*TypeDes_23                      TypeDesc-Unlawful/unnecessary arrest

*Traffic irregularity
*--------------------------
*TypeDes_22                      TypeDesc-Traffic irregularity


gen failures_in_duty=0
replace failures_in_duty=1 if ///
(TypeDes_1>0 & !missing(TypeDes_1) ) | ///
(TypeDes_2>0 & !missing(TypeDes_2) ) | ///
(TypeDes_3>0 & !missing(TypeDes_3) ) | ///
(TypeDes_4>0 & !missing(TypeDes_4) ) | ///
(TypeDes_5>0 & !missing(TypeDes_5) ) | ///
(TypeDes_13>0 & !missing(TypeDes_13) ) | ///
(TypeDes_8>0 & !missing(TypeDes_8) ) | ///
(TypeDes_14>0 & !missing(TypeDes_14) ) | ///
(TypeDes_16>0 & !missing(TypeDes_16) ) | ///
(TypeDes_17>0 & !missing(TypeDes_17) ) | ///
(TypeDes_18>0 & !missing(TypeDes_18) )

gen malpractice=0
replace malpractice=1 if ///
(TypeDes_6>0 & !missing(TypeDes_6) ) | ///
(TypeDes_12>0 & !missing(TypeDes_12) ) | ///
(TypeDes_10>0 & !missing(TypeDes_10) ) 


gen discriminatory_behaviour=0
replace discriminatory_behaviour=1 if ///
(TypeDes_7>0 & !missing(TypeDes_7) ) | ///
(TypeDes_11>0 & !missing(TypeDes_11) )

gen opressive_behav=0
replace opressive_behav=1 if ///
(TypeDes_19>0 & !missing(TypeDes_19) ) | ///
(TypeDes_20>0 & !missing(TypeDes_20) ) | ///
(TypeDes_21>0 & !missing(TypeDes_21) ) | ///
(TypeDes_23>0 & !missing(TypeDes_23) )

gen traffic=0
replace traffic=1 if ///
(TypeDes_22>0 & !missing(TypeDes_22) )

tab traffic
gen incivility=0
replace incivility=1 if ///
(TypeDes_9>0 & !missing(TypeDes_9) )

tab incivility

gen other_and_trafic =0
replace other_and_trafic=1 if ///
(TypeDes_22>0 & !missing(TypeDes_22) ) | ///
(TypeDes_15>0 & !missing(TypeDes_15) )
tab other_and_trafic traffic

tab other_and_trafic TypeDes_15


  gen alle_type1=failures_in_duty 
  gen alle_type2=malpractice
  gen alle_type3=discriminatory_behaviour 
  gen alle_type4=opressive_behav 
  gen alle_type5=incivility 
  gen alle_type6=other_and_trafic
 drop failures_in_duty malpractice discriminatory_behaviour ///
 opressive_behav incivility other_and_trafic

  
  label var alle_type1 "Failures in duty"
  label var alle_type2 "Malpractice"
  label var alle_type3 "Discriminatory behaviour"
  label var alle_type4 "Opressive_behaviour" 
  label var alle_type5 "Incivility" 
  label var alle_type6 "Other allegations (including trafic allegations"
  
  

foreach var of varlist level* {
des `var'
tab `var'
}


sort GUID timeq

cd "$location_cleaned_data"
save  "081018 CC  WW  SS GEO RATING RANK LM Peer common.dta", replace 
// We will use this dataset to later compute the peers who had complaints on a different date than the target individual



