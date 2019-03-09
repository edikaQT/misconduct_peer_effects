*========================================================================================
*
*                          FALSIFICATION
*
*========================================================================================
*
/// Under the concern that our estimation of peer effects might still reflect correlated
/// effects due to unobservable events not accounted by our controls or endogeneity due to
/// disregarded indirect interactions between individual and the peers of peers used in the
/// constructions of our instruments, we perform the following falsification test. Observe below...




//  WHEN TARGET ('T' in the table) MOVES:
//________________________________________________________________________________________________________________________________
//
//			Line Manager 1		Line Manager 2		Line Manager 3		Instruments
//									
// t-3		T, A, B, C			D, E, F, G			H, I, J, K				P2 = Proportion of H's peers with misconduct in t-3									
//									
// t-2		T, A, B, C			D, E, F, G			H, I, J, K				P1 = Proportion of H's peers with misconduct in t-2
//																		
// t-1		A, B, C, L			T, D, E, F, G, H	I, J, K, M											
//									
// t		A, B, C, L			T, D, E, F, G, H	I, J, K, M		
//																	
//________________________________________________________________________________________________________________________________



/// ... that the behaviours of individuals ‘I’, ‘J’ and ‘K’ are expected to
/// influence the conduct of ‘T’ during quarter t-1 through a single and unique channel, ‘H’.
/// However, during quarter t-1 former peers of ‘T’ (i.e., ‘A’, ‘B’ and ‘C’) who remained under the
/// direction of Line Manager 1 and, consequently, had no direct contact with ‘H’ should not be
/// affected by any sort of misconduct of ‘I’, ‘J’ or ‘K’ that took place during quarter − 2 or
/// t − 3. Thus, our falsification test consists on replacing the dependent variable (misconduct of the target in t) 
/// by the proportion of former peers of the target 'T' who receive allegations of misconduct during quarter t.
/// The new dependent variable is then the proportion of A, B and C who received complaints of misconduct in t-1.

/// A, B, c worked along T during quarter t − 2 (the period immediately preceding
/// the movement of 'T' into a new peer group). 

///  The control variables are analogous to those used in Table 4. They include the proportion of male peers, the proportions of peers for each rank,
/// business group and performance rating, the average length of service and the usual year and seasonal controls.

cd "$location_cleaned_data"

 
 use  "101018 DATA UPDATED WITH PEERS L1ANDXX.dta", clear
 
 des rating*, full
 bysort num_id (timeq): gen rating_3cat_d_l4=L4.rating_3cat_d


keep *GUID* had_case_complaint *M2* timeq approx_ls_years year* quarter* Gender*  ///
 level3_territorial_police_v2 ///
 level4_territorial_police_v2 ///
 rating_3cat_LM_d ///
 rating_3cat_d_l4 ///
 rank_police_staff_d ///
 prop_peer_co_l1 ///
num_id number_peer_right had_alle* had_Ac*
 des, full


// (1) who was LM1 in t-2?
 bysort GUID (timeq): gen old_LM=LinemanagerGUIDRef_right[_n-2]
// (2) how many employees had LM1 in t-2?
// (3) for each person who had LM1 as line manager in t-2, count how many peers he had in t-2: (2)-1
 
bysort old_LM timeq: gen old_number_peer_right=_N
replace old_number_peer_right=. if missing(old_LM) 
replace old_number_peer_right=old_number_peer_right-1

// (4) for each person who had LM1 as line manager in t-2, count how many peers had a report of misconduct in t
// (5) then get the proportion of (4)/(3) 
bysort old_LM timeq: egen old_number_peer_complaint=sum(had_case_complaint)
replace old_number_peer_complaint=. if missing(old_LM) 
replace old_number_peer_complaint=old_number_peer_complaint-had_case_complaint

gen old_proportion_peer_com= old_number_peer_complaint/old_number_peer_r
label var old_proportion_peer_com "Proportion of former peers in t-2 with misconduct in t"

xtset num_id timeq
rename level3_territorial_police_v2 l3_terr_poli_v2


//______________________________________________________________________
//
// CREATING CONTROL VARIABLES FOR THE FALSIFICATION TEST (these are proportions)
//______________________________________________________________________
//


foreach var of varlist ///
Gender_d ///
rank_police_staff_d ///
rating_3cat_d_l4 ///
l3_terr_poli_v2 ///
 {

// (1) creating dummies for the levels of the controls
tab `var', gen(`var'_lev_)

foreach var_level of varlist `var'_lev_* ///
 {

bysort old_LM timeq: egen old_number_peer_cal= count(`var_level') // (2) counting people (under LM1 in t-2) for each level of the control variables
replace old_number_peer_cal=. if missing(old_LM) 
gen there_is=0
replace there_is=1 if !missing(`var_level') //Note that the target is included in the count of (2) 
replace old_number_peer_cal=old_number_peer_cal-there_is  // (3) counting the number of peers, so (2) - 1
 
 
bysort old_LM timeq: egen old_n_peer=sum(`var_level') // (4) counting how many people from the total (2) have 1 in the dummy for controls
replace old_n_peer=. if missing(old_LM) 
replace old_n_peer=old_n_peer-`var_level'  //(5) how many peers now. So (4)-1

gen f_pr_`var_level'= old_n_peer/old_number_peer_cal // (6) get the proportion of peers (5)/(3)
drop old_n_peer
drop old_number_peer_cal
drop there_is

}
}


///Average length of service (years) // we have not converted into decades yet
bysort old_LM timeq: egen old_n_peer=sum(approx_ls_years)
replace old_n_peer=. if missing(old_LM) 
replace old_n_peer=old_n_peer-approx_ls_years

gen f_pr_approx_ls_years= old_n_peer/old_number_peer_r
drop old_n_peer

gen f_pr_approx_ls_years2=f_pr_approx_ls_years^2

// length of service in decades  now


replace f_pr_approx_ls_years=f_pr_approx_ls_years/10 //so in decades
replace f_pr_approx_ls_years2=f_pr_approx_ls_years^2

label var f_pr_approx_ls_years "Average Length of service (10 years)"
label var f_pr_approx_ls_years2 "Average Length of service (10 years)^2"


label var	f_pr_Gender_d_lev_1	"Prop  Female"
label var	f_pr_Gender_d_lev_2	"Prop Male"
label var	f_pr_rank_police_staff_d_lev_1	"Prop 	rank_police_staff_d==Police Constable"
label var	f_pr_rank_police_staff_d_lev_2	"Prop 	rank_police_staff_d==Police Sergeant"
label var	f_pr_rank_police_staff_d_lev_3	"Prop 	rank_police_staff_d==Inspector "
label var	f_pr_rank_police_staff_d_lev_4	"Prop 	rank_police_staff_d==Chief Inspector,"
label var	f_pr_rank_police_staff_d_lev_5	"Prop 	rank_police_staff_d==Special Constabulary"
label var	f_pr_rank_police_staff_d_lev_6	"Prop 	rank_police_staff_d==Civil "
label var	f_pr_rating_3cat_d_l4_lev_1	"Prop 	rating==Exceptional + Competent (above standard)"
label var	f_pr_rating_3cat_d_l4_lev_2	"Prop 	rating==Competent (at required standard)"
label var	f_pr_rating_3cat_d_l4_lev_3	"Prop 	rating==Competent (development required) + Not yet competent"
label var	f_pr_l3_terr_poli_v2_lev_1	"Prop 	l3_terr_poli_v2==TP - Boroughs East"
label var	f_pr_l3_terr_poli_v2_lev_2	"Prop 	l3_terr_poli_v2==TP - Boroughs North"
label var	f_pr_l3_terr_poli_v2_lev_3	"Prop 	l3_terr_poli_v2==TP - Boroughs South"
label var	f_pr_l3_terr_poli_v2_lev_4	"Prop 	l3_terr_poli_v2==TP - Boroughs West"
label var	f_pr_l3_terr_poli_v2_lev_5	"Prop 	l3_terr_poli_v2==TP - Central"
label var	f_pr_l3_terr_poli_v2_lev_6	"Prop 	l3_terr_poli_v2==TP - Criminal Justice & Crime"
label var	f_pr_l3_terr_poli_v2_lev_7	"Prop 	l3_terr_poli_v2==TP - Westminster"
label var	f_pr_l3_terr_poli_v2_lev_8	"Prop 	l3_terr_poli_v2==Specialist Crime and Operations"
label var	f_pr_l3_terr_poli_v2_lev_9	"Prop 	l3_terr_poli_v2==Specialist Operations"
label var	f_pr_l3_terr_poli_v2_lev_10	"Prop 	l3_terr_poli_v2==Other Business Group"



keep GUID timeq old_proportion_peer_com f_pr_*
sort GUID timeq

tempfile old_LM
save `old_LM', replace




use "101018 restricted peer 3 periods and quarter t-1 no including for any movement", clear

tab timeq
// selecting only people who moved
keep if  proportion_per_l1andl2==0 & ///
  proportion_per_l1andl3==0 
keep if subset==1  


tab timeq
sum inst*
sum prop_peer_co_l1


// lenght of service in decades now
replace approx_ls_years=approx_ls_years/10 
gen approx_ls_years2=approx_ls_years*approx_ls_years
 
label var approx_ls_years "Length of service (10 years)"
label var approx_ls_years2 "Length of service (10 years)^2"
 
// other control dummies: 
  
tab year, gen(year_) 
tab quarter, gen(quarter_)  

tab Gender_d, gen(gender_d_)
tab level3_territorial_police_v2, gen(terri_poli_) 
tab rating_3cat_LM_d, gen(rating_3cat_LM_d_) 
tab rating_3cat_d_l4,  gen(rating_3cat_d_l4_)
tab rank_police_staff_d, gen(rank_police_staff_d_) 

sort GUID timeq
drop _merge
merge GUID timeq using ///
`old_LM'

tab _merge



// we will start the regressions with the controls starting with "f_pr"
// then we add the variables starting with "j_pr" (the rating)
rename f_pr_rating_3cat_d_l4_lev_1	j_pr_rating_3cat_d_l4_lev_1
rename f_pr_rating_3cat_d_l4_lev_2	j_pr_rating_3cat_d_l4_lev_2
rename f_pr_rating_3cat_d_l4_lev_3	j_pr_rating_3cat_d_l4_lev_3


rename f_pr_l3_terr_poli_v2_lev_1 fff_pr_l3_terr_poli_v2_lev_1

// We rename the variable because we want to set 'Boroughs East'
// as the reference (as in Table 2) and we only include  variables starting in 'f_pr' in the regressions for Table 3.

rename f_pr_Gender_d_lev_1 fff_pr_Gender_d_lev_1_female 
// above we have the proportion of females. We rename the variable (changing the first letters) because we will include 
// variables starting in 'f_pr' in the regressions and we will include the proportion of males
// in the regression, rather than the proportion of females.
des *end*, full

keep if _merge==3


//______________________________________________________________________
//
// global controls for the standard GMM model (column 4, Table 5)
//______________________________________________________________________

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
		

			
//___________________________________________________________________________________________________
//	
//      Table 5. Estimated Likelihood of Misconduct, Peer Effects: Falsification Test
//      -----------------------------------------------------------------------------
//____________________________________________________________________________________________________
	


des f_pr*, full  

//______________________________________________________________________
//
// (1) DV= Prop. of former peers in t-2 with cases of misconduct in t
//______________________________________________________________________


 ivreg2 old_proportion_peer_com  ///
f_pr* ///
( ///
prop_peer_co_l1 ///
= instrument1 ///
instrument2  ///
) ///
,gmm2s   first small ///
robust 

capture drop used_xx
gen used_xx=1 if e(sample)==1
bysort GUID (used_xx): gen q_used=_n==1 if used_xx==1
replace q_used=. if q_used!=1

tab used_xx
local obsfe =r(N) 

tab q_used
local guidfe =r(N) 
drop q_used


scalar pvalue_sargan=e(jp) 
outreg2 using table_falsification.doc, replace ctitle("GMM Robust falsification") ///
addstat( ///
"LM test statistic for underidentification (Kleibergen-Paap)", e(idstat), ///
"P-value of underidentification LM statistic", e(idp), ///
"F statistic for weak identification (Kleibergen-Paap)",e(widstat), ///
///
"Hansen Statistic",e(j),"Degrees freedom of Hansen Statistic",e(jdf), ///
"P value Hansen Statistic ",pvalue_sargan , ///
"Observations, quarter X person",`obsfe', "Number of people", `guidfe') ///
 ///
 ci ///
addtext( Quarter FEs, NO, Year FEs, NO)  label ///
 bdec(3) alpha(.001, .01, .05, .10) symbol(***, **, *, ~)

//______________________________________________________________________
//
// (2) DV= Prop. of former peers in t-2 with cases of misconduct in t
//______________________________________________________________________



 ivreg2 old_proportion_peer_com ///
f_pr_* ///
j_pr* ///
( ///
prop_peer_co_l1 ///
= instrument1 ///
instrument2  ///
) ///
,gmm2s   first small ///
robust 

capture drop used_xx
gen used_xx=1 if e(sample)==1
bysort GUID (used_xx): gen q_used=_n==1 if used_xx==1
replace q_used=. if q_used!=1

tab used_xx
local obsfe =r(N) 

tab q_used
local guidfe =r(N) 
drop q_used


scalar pvalue_sargan=e(jp) 
outreg2 using table_falsification.doc, append ctitle("GMM Robust falsification") ///
addstat( ///
"LM test statistic for underidentification (Kleibergen-Paap)", e(idstat), ///
"P-value of underidentification LM statistic", e(idp), ///
"F statistic for weak identification (Kleibergen-Paap)",e(widstat), ///
///
///
"Hansen Statistic",e(j),"Degrees freedom of Hansen Statistic",e(jdf), ///
"P value Hansen Statistic ",pvalue_sargan , ///
"Observations, quarter X person",`obsfe', "Number of people", `guidfe') ///
 ///
 ci ///
addtext( Quarter FEs, NO, Year FEs, NO)  label ///
 bdec(3) alpha(.001, .01, .05, .10) symbol(***, **, *, ~)

 

//______________________________________________________________________
//
// (3) DV= Prop. of former peers in t-2 with cases of misconduct in t
//______________________________________________________________________

 
 ivreg2 old_proportion_peer_com  ///
  year_* ///
   quarter_*  ///
f_pr_* ///
j_pr* ///
( ///
prop_peer_co_l1 ///
= instrument1 ///
instrument2  ///
) ,gmm2s   first small ///
robust 

capture drop used_xx
gen used_xx=1 if e(sample)==1
bysort GUID (used_xx): gen q_used=_n==1 if used_xx==1
replace q_used=. if q_used!=1

tab used_xx
local obsfe =r(N) 

tab q_used
local guidfe =r(N) 
drop q_used


scalar pvalue_sargan=e(jp) 
outreg2 using table_falsification.doc, append ctitle("GMM Robust falsification") ///
addstat( ///
"LM test statistic for underidentification (Kleibergen-Paap)", e(idstat), ///
"P-value of underidentification LM statistic", e(idp), ///
"F statistic for weak identification (Kleibergen-Paap)",e(widstat), ///
///
///
"Hansen Statistic",e(j),"Degrees freedom of Hansen Statistic",e(jdf), ///
"P value Hansen Statistic ",pvalue_sargan , ///
"Observations, quarter X person",`obsfe', "Number of people", `guidfe') ///
ci ///
addtext( Quarter FEs, YES, Year FEs, YES)  label ///
 bdec(3) alpha(.001, .01, .05, .10) symbol(***, **, *, ~) ///
 

//_____________________________
//
// CHECK: DV= Misconduct in t
//_____________________________

ivreg2 had_case_complaint  ///
$indep_variables ///
( ///
prop_peer_co_l1 ///
= instrument1 ///
instrument2  ///
) ,gmm2s   first small cluster(num_id) 


capture drop used_xx

gen used_xx=1 if e(sample)==1
bysort GUID (used_xx): gen q_used=_n==1 if used_xx==1
replace q_used=. if q_used!=1

tab used_xx
local obsfe =r(N) 

tab q_used
local guidfe =r(N) 

drop q_used




scalar pvalue_sargan=e(jp) 
outreg2 using table_falsification_column4.doc, replace ctitle("GMM CLUSTER") ///
addstat( ///
"LM test statistic for underidentification (Kleibergen-Paap)", e(idstat), ///
"P-value of underidentification LM statistic", e(idp), ///
"F statistic for weak identification (Kleibergen-Paap)",e(widstat), ///
///
"Hansen Statistic",e(j),"Degrees freedom of Hansen Statistic",e(jdf), ///
"P value Hansen Statistic ",pvalue_sargan , ///
"Observations, quarter X person",`obsfe', "Number of people", `guidfe') ///
 ///
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
) 


