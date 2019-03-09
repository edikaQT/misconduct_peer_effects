*========================================================================================
*
*  Supplementary Table 11. Likelihood of Switching Line Manager - Whole Data - Exhaustive Geographic Controls 
*
*========================================================================================


global business_groups_control level4_territorial_police_v2

cd "$location_cleaned_data"

use "101018 restricted peer 3 periods t-1 quarter new way_any_movement", clear


keep *GUID* had_case_complaint* *M2* timeq ///
approx_ls_years year* quarter* Gender* ///so in decades
$business_groups_control ///
 ///rating_3cat_LM_d ///
 rating_3cat_LM_d_l4 ///
 rating_3cat_d_l4 ///
 rank_police_staff_d  ///
instrument* ///
 many* ///
 prop_peer_co_l1 ///
 proportion_per_l1andl2  proportion_per_l1andl3 ///
num_id number_peer_right had_alle* had_Ac*


 des, full

//1) preparting controls dummies

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
year_* ///
quarter_*  


			
// 3) REGRESSIONS - NO IV	


// RE - whole sample
// 

xtreg had_case_complaint  ///
prop_peer_co_l1 ///
$indep_variables ///
, re cluster(num_id)

capture drop used_re
gen used_re=1 if e(sample)==1
  
  
  
// 2) global for controls

global indep_variables ///
gender_d_2 ///
rank_police_staff_d_* ///
terri_poli_* ///
approx_ls_years ///
approx_ls_years2 ///
year_* 


			
// REGRESSIONS - EXPLAINING CHANGE IN LM	

des *LM*, full

gen timeh=hofd(dofq(timeq))
format timeh %th
tab timeq timeh

collapse (sum) had_case_complaint (last) used_re $indep_variables rating_3cat_d_l4_* LinemanagerGUIDRef_right, by(GUID num_id timeh)

xtset num_id timeh
bysort GUID (timeh): gen lag_LM=LinemanagerGUIDRef_right[_n-1]


gen change_LM=0
replace change_LM=1 if ///
 LinemanagerGUIDRef_right!=lag_LM  & ///
!missing(lag_LM) & !missing(LinemanagerGUIDRef_right)


replace had_case_complaint=1 if had_case_complaint>0 & !missing(had_case_complaint)
bysort GUID (timeh): gen lag_had_case_complaint=had_case_complaint[_n-1]

des *rat*

keep if used_re==1

/// Column 1
xtreg change_LM ///
lag_had_case_complaint ///
 ///
, re cluster(num_id)

outreg2 using table_move.doc,  ctitle("RE cluster") ///
   addstat ( /// 
   "rho", e(rho), "sigma u", e(sigma_u) ///
  ) ///
  ci ///
  addtext( Year FEs, NO, Geographic FEs, NO)  label ///
 bdec(3) alpha(.001, .01, .05, .10) symbol(***, **, *, ~) ///
  drop(  ///
year_* ///
quarter_*  ///
terri_poli_* ///
) ///
  replace
	 
/// Column 2

xtreg change_LM ///
rating_3cat_d_l4_* ///
, re cluster(num_id)

outreg2 using table_move.doc,  ctitle("RE cluster") ///
   addstat ( /// 
   "rho", e(rho), "sigma u", e(sigma_u) ///
  ) ///
  ci ///
  addtext( Quarter FEs, NO, Year FEs, NO, Geographic FEs, NO)  label ///
 bdec(3) alpha(.001, .01, .05, .10) symbol(***, **, *, ~) ///
  drop(  ///
year_* ///
quarter_*  ///
terri_poli_* ///
) ///
  append

/// Column 3
 
 
xtreg change_LM ///
$indep_variables ///
, re cluster(num_id)

outreg2 using table_move.doc,  ctitle("RE cluster") ///
   addstat ( /// 
   "rho", e(rho), "sigma u", e(sigma_u) ///
  ) ///
  ci ///
  addtext( Year FEs, YES, Geographic FEs, YES)  label ///
 bdec(3) alpha(.001, .01, .05, .10) symbol(***, **, *, ~) ///
  drop(  ///
year_* ///
quarter_*  ///
terri_poli_* ///
) ///
  append

