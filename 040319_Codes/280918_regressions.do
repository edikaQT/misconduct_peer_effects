
*========================================================================================
*
*                          REGRESSIONS 
*
*========================================================================================
*


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


			
// 3) REGRESSIONS - NO IV	

//_______________________________________________________________________
//
//  Supplementary Table 3. The Estimated Likelihood of Misconduct, Peer Effects
//_______________________________________________________________________

// Column 1: RE - whole sample
// 

xtreg had_case_complaint  ///
prop_peer_co_l1 ///
$indep_variables ///
, re cluster(num_id)

capture drop used_re
gen used_re=1 if e(sample)==1


outreg2 using table_RE_FE.doc,  ctitle("RE cluster") ///
   addstat ( /// 
   "rho", e(rho), "sigma u", e(sigma_u) ///
  ) ///
  ci ///
  addtext( Quarter FEs, YES, Year FEs, YES)  label ///
 bdec(3) alpha(.001, .01, .05, .10) symbol(***, **, *, ~) ///
  keep(prop_peer_co_l1 ///
gender_d_2 ///
rank_police_staff_d_* ///
terri_poli_* ///
 approx_ls_years ///
approx_ls_years2 ///
rating_3cat_d_l4_* ///
) ///
  replace
	 

	
// Column 2: FE - whole sample
			
xtreg had_case_complaint  ///
prop_peer_co_l1 ///
$indep_variables ///
, fe cluster(num_id)

//STATA does not report the correct number of obs and people. FE needs at least 2 obs per person.

capture drop used_fe
gen used_fe=1 if e(sample)==1

bysort GUID (timeq): egen q_used=count(used_fe)

tab q_used used_fe, missing
replace used_fe=. if q_used==1 

drop q_used //how many people included in the regression
bysort GUID (used_fe): gen q_used=_n==1 if used_fe==1
replace q_used=. if q_used!=1

tab used_fe
local obsfe =r(N) 

tab q_used
local guidfe =r(N) 

drop q_used

outreg2 using table_RE_FE.doc, append ctitle("FE cluster") ///
addstat ("Observations, quarter X person",`obsfe', "Number of people", `guidfe') ///
addtext( Quarter FEs, YES, Year FEs, YES)  label ///
 bdec(3) alpha(.001, .01, .05, .10) symbol(***, **, *, ~) ///
  keep(prop_peer_co_l1 ///
gender_d_2 ///
rank_police_staff_d_* ///
terri_poli_* ///
 approx_ls_years ///
approx_ls_years2 ///
rating_3cat_d_l4_* ///
) ci


// Column 3: RE - Individuals with incidence of Misconduct


xtreg had_case_complaint  ///
$indep_variables ///
prop_peer_co_l1 ///
if  many_complaints>0 ///
, re cluster(num_id)

outreg2 using table_RE_FE.doc,  ctitle("RE cluster") ///
   addstat ( /// 
   "rho", e(rho), "sigma u", e(sigma_u) ///
  ) ///
addtext( Quarter FEs, YES, Year FEs, YES, Antecedents of Misconduct in 2012q2 to 2015q1, Yes)  label ///
 bdec(3) alpha(.001, .01, .05, .10) symbol(***, **, *, ~) ///
     append ///
	   keep(prop_peer_co_l1 ///
gender_d_2 ///
rank_police_staff_d_* ///
terri_poli_* ///
 approx_ls_years ///
approx_ls_years2 ///
rating_3cat_* ///
)  ci

	
// Column 4: FE - Individuals with incidence of Misconduct
			
xtreg had_case_complaint  ///
$indep_variables ///
prop_peer_co_l1 ///
if  many_complaints>0 ///
, fe cluster(num_id)

drop used_fe
gen used_fe=1 if e(sample)==1

capture drop q_used

bysort GUID (timeq): egen q_used=count(used_fe)

tab q_used used_fe, missing
replace used_fe=. if q_used==1


drop q_used
bysort GUID (used_fe): gen q_used=_n==1 if used_fe==1
replace q_used=. if q_used!=1

tab used_fe
local obsfe =r(N) 

tab q_used
local guidfe =r(N) 

drop q_used

outreg2 using table_RE_FE.doc, append ctitle("FE cluster") ///
addstat ("Observations, quarter X person",`obsfe', "Number of people", `guidfe') ///
addtext( Quarter FEs, YES, Year FEs, YES, Antecedents of Misconduct in 2012q2 to 2015q1, Yes)  label ///
 bdec(3) alpha(.001, .01, .05, .10) symbol(***, **, *, ~)  ///
   keep(prop_peer_co_l1 ///
gender_d_2 ///
rank_police_staff_d_* ///
terri_poli_* ///
 approx_ls_years ///
approx_ls_years2 ///
rating_3cat_* ///
///year_* ///
///quarter_*  ///
) ci



//_______________________________________________________________________
//
//  Table 2. The Estimated Likelihood of Misconduct, Peer Effects
//_______________________________________________________________________
//

	
	
// Column 1: GMM
			
	  
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

scalar pvalue_sargan=e(jp) 
outreg2 using table_IV.doc, append ctitle("GMM 2s cluster") ///
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
    keep(prop_peer_co_l1 ///
gender_d_2 ///
rank_police_staff_d_* ///
terri_poli_* ///
 approx_ls_years ///
approx_ls_years2 ///
rating_3cat_* ///
year_* ///
quarter_*  ///
) 
 

codebook GUID if used_gmm==1 


// Supplementary Table 4: First Stage GMM Results 
// -----------------------------------------------

capture drop used_gmm
gen used_gmm=1 if e(sample)==1

bysort GUID (used_gmm): gen q_used=_n==1 if used_gmm==1
replace q_used=. if q_used!=1

tab used_gmm
local obsfe =r(N) 

tab q_used
local guidfe =r(N) 

drop q_used

scalar LM_underidentification=e(idstat)
scalar p_underidentification=e(idp)
scalar F_weak_identification=e(widstat)

est restore _ivreg2_prop_peer_co_l1
ereturn list
outreg2 using first_stage.doc, append ///
ctitle("GMM 2s cluster") ///
ci ///
addstat( ///
"LM test statistic for underidentification (Kleibergen-Paap)", LM_underidentification, ///
"P-value of underidentification LM statistic", p_underidentification, ///
"F statistic for weak identification (Kleibergen-Paap)",F_weak_identification, ///
 "Observations, quarter X person",`obsfe', "Number of people", `guidfe') ///
addtext( Quarter FEs, YES, Year FEs, YES)  label ///
 bdec(3) alpha(.001, .01, .05, .10) symbol(***, **, *, ~) ///
    keep(prop_peer_co_l1 ///
gender_d_2 ///
rank_police_staff_d_* ///
terri_poli_* ///
 approx_ls_years ///
approx_ls_years2 ///
rating_3cat* ///
year_* ///
quarter_*  ///
instrument* ///
) 



// Column 2: IVPROBIT

tsset, clear


ivprobit had_case_complaint  ///
$indep_variables ///
( ///
prop_peer_co_l1 ///
= instrument1 ///
instrument2  ///
)  $restrictions_subset, first vce(cluster num_id)

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



outreg2 using table_IV.doc, append ctitle("IVPROBIT robust") ///
addstat("Wald test of endogeneity, chi2(1)",e(chi2_exog), ///
"Exogeneity test Wald p-value",  e(p_exog)   , ///
 "Observations, quarter X person",`obsfe', ///
 "Number of people", `guidfe') ///
 ci ///
addtext( Quarter FEs, YES, Year FEs, YES)  label ///
 bdec(3) alpha(.001, .01, .05, .10) symbol(***, **, *, ~) ///
     keep(prop_peer_co_l1 ///
gender_d_2 ///
rank_police_staff_d_* ///
terri_poli_* ///
 approx_ls_years ///
approx_ls_years2 ///
rating_3cat_* ///
year_* ///
quarter_*  ///
instrume* ) 

 
 
 
 
//_______________________________________________________________________
//
// Supplementary Figure 2: Distribution of number of peers by sample. The top panel includes all quarters. The
// bottom panels restrict the data to those quarters that satisfy our criteria for identification.
// Outliers below the 5-percentile and above the 95-percentile are excluded.
//_______________________________________________________________________
//

sum number_peer_right if used_re==1, detail
sum number_peer_right if used_gmm==1, detail

// Density plots

sum number_peer_right if used_re==1 & number_peer_right>=1 & ///
number_peer_right <=14
codebook GUID if used_re==1 & number_peer_right>=1 & ///
number_peer_right <=14

hist number_peer_right if used_re==1 & number_peer_right>=1 & ///
number_peer_right <=14 , discrete scheme(plotplainblind) xtitle(Number of Peers) ///
saving(first, replace)


sum number_peer_right if used_gmm==1 & number_peer_right>=1 & ///
number_peer_right <=14 
codebook GUID  if used_gmm==1 & number_peer_right>=1 & ///
number_peer_right <=14 

hist number_peer_right if used_gmm==1 & number_peer_right>=1 & ///
number_peer_right <=14 , discrete scheme(plotplainblind) xtitle(Number of Peers) ///
saving(second, replace)

// Frequency distributions
hist number_peer_right if used_re==1 & number_peer_right>=1 & ///
number_peer_right <=14 , discrete scheme(plotplainblind) xtitle(Number of Peers) frequency ///
saving(first, replace) 

hist number_peer_right if used_gmm==1 & number_peer_right>=1 & ///
number_peer_right <=14 , discrete scheme(plotplainblind) xtitle(Number of Peers) frequency ///
saving(second, replace)

//_______________________________________________________________________
//
// Supplementary Table 2. Composition of The Data Used to Estimate Peer Effects
//_______________________________________________________________________
//

des $indep_variables 

estpost sum $indep_variables had_case_complaint had_alle* had_Ac* if used_re==1
			


 esttab . using table_composition.rtf, cells("mean(fmt(2))")  ///
 stats(N) ///
 label ///
 varlabels(`e(labels)') ///eqlabels(`e(labels)') ///
 varwidth(30)  nostar unstack  ///
    noobs nonote nomtitle nonumber ///
	replace drop( ///
	year_* ///
quarter_*)

	
estpost sum $indep_variables had_case_complaint had_alle* had_Ac*  if used_gmm==1
			


 esttab . using table_composition.rtf, cells("mean(fmt(2))")  ///
 stats(N) ///
 label ///
 varlabels(`e(labels)') ///eqlabels(`e(labels)') ///
 varwidth(30)  nostar unstack  ///
    noobs nonote nomtitle nonumber ///
	append drop( ///
	year_* ///
quarter_*)

	
	
	
	


//_______________________________________________________________________
//
// Figure 2. Fitted probability of misconduct at conditional on the proportion of peers exhibiting events of misconduct in t − 1 
//_______________________________________________________________________
//

// ivprobit

tsset, clear


ivprobit had_case_complaint  ///
$indep_variables ///
( ///
prop_peer_co_l1 ///
= instrument1 ///
instrument2  ///
)  $restrictions_subset, first vce(cluster num_id)




version 13.1: margins, predict(pr) at(prop_peer_co_l1=(.0 (.1)0.5 ) ) atmeans
margins, predict(xb) at(prop_peer_co_l1=(.0 (.05)0.5 ) ) atmeans

// save table as matrix
mat tab = r(table)
mat t = tab'

clear
svmat t

// transform logit to probability and display
gen prob3 = normal(t1)
gen problo = normal(t5)
gen probhi = normal(t6)

format %9.3f prob*
list prob* , noobs clean // confidence intervals


gen prop_peer_co_l1=(_n-1)/20
 twoway (rarea probhi problo  prop_peer_co_l1, fcolor(gs15)) ///
(line prob3 prop_peer_co_l1, lcolor(black) lpattern(dash) lwidth(medthick)) ///
, ytitle(Probability of Misconduct in t) xtitle(Proportion of Peers with Misconduct in t-1) legend(off) ///
scheme(plotplain)



//keeping people used in RE regressions

keep if used_re==1
bysort GUID (timeq): gen first_obs=_n==1
keep if first_obs==1
des

keep GUID

sort GUID

 save GUID_used_in_RE.dta, replace
