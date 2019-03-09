*========================================================================================
*
*  Supplementary Table 9
*  Including the Interaction of Peer Misconduct and Peer Group Size 
*
*========================================================================================



cd "$location_cleaned_data"

use "101018 restricted peer 3 periods t-1 quarter new way_any_movement", clear


keep *GUID* had_case_complaint *M2* timeq ///
approx_ls_years year* quarter* Gender* ///so in decades
$business_groups_control ///
 rating_3cat_LM_d_l4 ///
 rating_3cat_d_l4 ///
 rank_police_staff_d  ///
instrument* ///
 many* ///
 prop_peer_co_l1 ///
 proportion_per_l1andl2  proportion_per_l1andl3 ///
num_id number_peer_right had_alle* had_Ac*


 des, full

//1) preparing controls dummies

// years of service
replace approx_ls_years=approx_ls_years/10 //so in decades
gen approx_ls_years2=approx_ls_years*approx_ls_years


label var approx_ls_years "Length of service (10 years)"
label var approx_ls_years2 "Length of service (10 years)^2"

// time controls: year quarter
 
tab year, gen(year_) 
tab quarter, gen(quarter_)  

 
// gender
tab Gender_d, gen(gender_d_)
tab $business_groups_control, gen(terri_poli_) 

tab rating_3cat_LM_d, gen(rating_3cat_LM_d_l4_) 
tab rating_3cat_d_l4,  gen(rating_3cat_d_l4_)
tab rank_police_staff_d, gen(rank_police_staff_d_) 

label var had_case_complaint "Incidence of misconduct=1"
label var had_Action_1   "Occurrence of Formal disciplinary actions following misconduct =1"              
label var had_Action_2   "Occurrence of Management disciplinary actions following misconduct"                
label var had_Action_3   "Occurrence of No disciplinary actions following misconduct"      

 
  
// 2) global for controls
//we will set the baseline category for territorial police as the
//first group and exclude it from the regression to prevent multicollinearity

rename terri_poli_1 base_terri_poli_1

global indep_variables ///
gender_d_2 ///
rank_police_staff_d_* ///
terri_poli_* ///
approx_ls_years ///
approx_ls_years2 ///
rating_3cat_d_l4_* ///
///rating_3cat_LM_d_l4_* /// Include this control and omit "rating_3cat_d_l4_*" for columns 3 and 4 of Supplementary Table 5
year_* ///
quarter_*  



 ivreg2 had_case_complaint  ///
$indep_variables ///
( ///
prop_peer_co_l1 ///
= instrument1 ///
instrument2  ///
)  $restrictions_subset ,gmm2s   first savefirst  small cluster(num_id) 

capture drop used_gmm
gen used_gmm=1 if e(sample)==1

bysort GUID: egen many_period=sum(used_gmm)

  
bysort GUID (used_gmm): gen q_used=_n==1 if used_gmm==1
replace q_used=. if q_used!=1

capture tab many_period if q_used==1 

tab used_gmm
local obsfe =r(N) 

tab q_used
local guidfe =r(N) 

drop q_used


sum number_peer_right if used_gmm==1, detail //15 is 95%
gen  interaction=c.prop_peer_co_l1#c.number_peer_right
gen  interaction_ins1=c.instrument1#c.number_peer_right
gen  interaction_ins2=c.instrument2#c.number_peer_right

//_______________________________________________________________________
//
//  Supplementary Table 9. Peer Effects on the Likelihood of Misconduct - Peer Group Size Effects - Exhaustive Geographic Controls
//_______________________________________________________________________
//
// Supplementary Table 9, COLUMN 1 - GMM

 ivreg2 had_case_complaint c.number_peer_right   ///
$indep_variables ///
( ///
prop_peer_co_l1 c.prop_peer_co_l1#c.number_peer_right  ///
= instrument1 ///
instrument2  c.instrument1#c.number_peer_right c.instrument2#c.number_peer_right ///
)  $restrictions_subset if number_peer_right<=15 ,gmm2s   first savefirst  small cluster(num_id) 

 margins, dydx(prop_peer_co_l1 ) at(number_peer_right=(7)) 
 
 display .5845092 +.0273835 *7

 ivreg2 had_case_complaint c.number_peer_right   ///
$indep_variables ///
( ///
prop_peer_co_l1 interaction  ///
= instrument1 ///
instrument2  interaction_ins1 interaction_ins2 ///
)  $restrictions_subset if number_peer_right<=15 ,gmm2s   first savefirst  small cluster(num_id) 




capture drop used_gmm_int 
capture drop many_period
gen used_gmm_int=1 if e(sample)==1

bysort GUID: egen many_period=sum(used_gmm_int)

capture drop q_used  
bysort GUID (used_gmm_int): gen q_used=_n==1 if used_gmm_int==1
replace q_used=. if q_used!=1

capture tab many_period if q_used==1 //to check how many multiple obs

tab used_gmm_int
local obsfe =r(N) 

tab q_used
local guidfe =r(N) 



scalar pvalue_sargan=e(jp) 
outreg2 using table_interaction.doc, replace ctitle("GMM 2s cluster") ///
///stats(coef se) ///
ci ///
addstat( ///
"LM test statistic for underidentification (Kleibergen-Paap)", e(idstat), ///
"P-value of underidentification LM statistic", e(idp), ///
"F statistic for weak identification (Kleibergen-Paap)",e(widstat), ///
"Hansen Statistic",e(j),"Degrees freedom of Hansen Statistic",e(jdf), ///
 "P-value Hansen Statistic ",pvalue_sargan, ///
 "Observations, quarter X person",`obsfe', "Number of people", `guidfe') ///
addtext( Quarter FEs, YES, Year FEs, YES)  label ///
 bdec(3) alpha(.001, .01, .05, .10) symbol(***, **, *, ~) ///
    keep(prop_peer_co_l1* ///
	interaction* ///
gender_d_2 ///
rank_police_staff_d_* ///
 approx_ls_years ///
approx_ls_years2 ///
rating_3cat_* *inte* /// 
number* ///
) 
 
// Supplementary Table 10.  Peer Group Size Effects -  First Stage GMM Results 

tab used_gmm_int
local obsfe =r(N) 

tab q_used
local guidfe =r(N) 


scalar LM_underidentification=e(idstat)
scalar p_underidentification=e(idp)
scalar F_weak_identification=e(widstat)

est restore _ivreg2_prop_peer_co_l1
ereturn list
outreg2 using first_stage_interaction.doc, replace ///
 ///
ctitle("GMM 2s cluster") ///
ci ///
addstat( ///
"LM test statistic for underidentification (Kleibergen-Paap)", LM_underidentification, ///
"P-value of underidentification LM statistic", p_underidentification, ///
"F statistic for weak identification (Kleibergen-Paap)",F_weak_identification, ///
/// "P value Hansen Statistic ",pvalue_sargan, ///
 "Observations, quarter X person",`obsfe', "Number of people", `guidfe')  ///
addtext( Quarter FEs, YES, Year FEs, YES)  label ///
 bdec(3) alpha(.001, .01, .05, .10) symbol(***, **, *, ~) ///
    keep(prop_peer_co_l1 ///
gender_d_2 ///
rank_police_staff_d_* ///
 approx_ls_years ///
approx_ls_years2 ///
rating_3cat* instrument* *inte* ///
number* ///
) 

est restore _ivreg2_interaction
ereturn list
outreg2 using first_stage_interaction.doc, append ///
ctitle("GMM 2s cluster") ///
ci ///
addstat( ///
"LM test statistic for underidentification (Kleibergen-Paap)", LM_underidentification, ///
"P-value of underidentification LM statistic", p_underidentification, ///
"F statistic for weak identification (Kleibergen-Paap)",F_weak_identification, ///
/// "P value Hansen Statistic ",pvalue_sargan, ///
 "Observations, quarter X person",`obsfe', "Number of people", `guidfe') ///
addtext( Quarter FEs, YES, Year FEs, YES)  label ///
 bdec(3) alpha(.001, .01, .05, .10) symbol(***, **, *, ~) ///
    keep(prop_peer_co_l1 ///
gender_d_2 ///
rank_police_staff_d_* ///
 approx_ls_years ///
approx_ls_years2 ///
rating_3cat* instrument* *inte* ///
number* ///
) 

// Supplementary Table 9, COLUMN 2 - IVPROBIT

tsset, clear


ivprobit had_case_complaint  c.number_peer_right   ///
$indep_variables ///
( ///
prop_peer_co_l1 interaction  ///
= instrument1 ///
instrument2  interaction_ins1 interaction_ins2 ///
)  $restrictions_subset if number_peer_right<=15, first vce(cluster num_id)

capture drop used_ivprobit
gen used_ivprobit=1 if e(sample)==1

capture drop q_used

bysort GUID (used_iv): gen q_used=_n==1 if used_iv==1
replace q_used=. if q_used!=1

tab used_iv
local obsfe =r(N) 

tab q_used
local guidfe =r(N) 

drop q_used



outreg2 using table_interaction.doc, append ctitle("IVPROBIT robust") ///
addstat("Wald test of endogeneity, chi2(1)",e(chi2_exog), ///
"Exogeneity test Wald p-value",  e(p_exog)   , ///
 "Observations, quarter X person",`obsfe', ///
 "Number of people", `guidfe') ///
 ci ///
addtext( Quarter FEs, YES, Year FEs, YES)  label ///
 bdec(3) alpha(.001, .01, .05, .10) symbol(***, **, *, ~) ///
    keep(prop_peer_co_l1* ///
	interaction* ///
gender_d_2 ///
rank_police_staff_d_* ///
 approx_ls_years ///
approx_ls_years2 ///
rating_3cat_* *inte* /// 
number* ///
) 

 

 
 
