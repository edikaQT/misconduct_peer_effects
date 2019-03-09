*========================================================================================
*
*                          PREPARING THE DATA OF PEOPLE WHO CHANGE PEERS IN ORDER TO DO IV REGRESSIONS
*
*======================================================================================
set more off
cd "$location_cleaned_data"
use "081018 CC  WW  SS GEO RATING RANK LM Peer common M2.dta", clear

// HERE WE PREPARE THE DATA OF PEOPLE WHO CHANGE PEERS IN ORDER TO DO IV REGRESSIONS
// Target person: 'Target'

// If 'Target' is in quarter T and we want to know the effects of peers
//    (1) we use peers in T-1 TO AVOID THE REFLECTION PROBLEM
//    (2) BUT IT IS STILL POSSIBLE THAT THERE ARE CORRELATED EFFECTS because
//        the 'Target' and his peers are in the same environment
//        or because they were matched together based on unobservables features
//        SO WE CANNOT USE PEERS IN T-1 BUT WE CAN INSTRUMENT THEM

								


//=====================
// METHOD (what we do here...)
//=====================

//  WHEN TARGET ('T' in the table) MOVES:
//________________________________________________________________________________________________________________________________
// FIGURE 1 in the paper:
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

//  - We restrict the data and we include ONLY target 'T' who moves in t-1 to group 'Line Manager 2'
//    (by move we mean that 100% of their peers in t-1 are NEW. 
//     So none of his peers in t-2 move with him to 'Line Manager 2' in t-1.

//     Of course, his peers in t (A, B and C who were also peers in t-1) are also different 
//     than his peers in t-2 (D, E, F, G, H) because in the data
//     people had the same peers for at least 2 quarters

//  - We find the cases in which another person also move to 'Line Manager 2' from other group. For instance, H.
//  - We instrument the effect of the conduct of peers D, E, F, G, H in t-1 on the conduct of the target 'T' in t.
//  - The instruments are 
//			P1 = Proportion of H's peers with misconduct in t-2 
//			P2 = Proportion of H's peers with misconduct in t-3
//  - We use the peers of H because they have not meet the target 'T' in t-2 and t-3
//  - We do not use D, E, F and G as instruments because they had contact with the target 'T' in t-1 and so there could be correlated effects happening
//  - If there are more than one person like H moving to 'Line Manager 2', we use the average of P1 and the average of P2 as instruments






//  WHEN TARGET DOES NOT MOVE:
//________________________________________________________________________________________________________________________________
//
//
//			Line Manager 1		Line Manager 2		Line Manager 3		Instruments
//									
// t-3		T, A, B, C			D, E, F, G			H, I, J, K			P2 = Proportion of H's peers with misconduct in t-3
//																		
// t-2		T, A, B, C			D, E, F, G			H, I, J, K			P1 = Proportion of H's peers with misconduct in t-2
//																		
// t-1		T, A, B, C, H		D, E, F, G			I, J, K, M											
//								
// t		T, A, B, C, H		D, E, F, G			I, J, K, M		
//									
//________________________________________________________________________________________________________________________________
//
//  - We look at someone who moves to 'Line Manager 1', like H, and using the same strategy than before, we use H's peers in t-3
//    and t-2 as instruments



*DATA FOR WHO CHANGED PEERS
*---------------------------------

clear
set more off
cd "$location_cleaned_data"

//we import the (1) total number of peers in quarters t-1  and
// (2) the total number of peers who worker with the target in both quarters t-1 and t-2, which is a subset of (1)

import delimited "140217 Who changes peerv2_l1andl2.csv", clear
drop v1
codebook number*

gen timeq2=yq(real(substr(timeq, 1,4)),real(substr(timeq, -1,1)))
format timeq2 %tq
tab timeq timeq2
rename timeq timeq_string
rename timeq2 timeq

rename guid GUID
rename number_common number_common_l1andl2
rename number_period number_period_l1andl2

drop timeq_string
sort GUID timeq

tempfile Who_changes_peerv2_l1andl2
save `Who_changes_peerv2_l1andl2', replace

//we import the (1) total number of peers in quarters t-1 and 
// (2) the total number of peers who worked with the target in both quarters t-1 and t-3, which is a subset of (1)

import delimited "140217 Who changes peerv2_l1andl3.csv", clear
drop v1
codebook number*

gen timeq2=yq(real(substr(timeq, 1,4)),real(substr(timeq, -1,1)))
format timeq2 %tq
tab timeq timeq2
rename timeq timeq_string
rename timeq2 timeq

rename guid GUID
rename number_common number_common_l1andl3
rename number_period number_period_l1andl3

drop timeq_string
sort GUID timeq

tempfile Who_changes_peerv2_l1andl3
save `Who_changes_peerv2_l1andl3'



merge GUID timeq using ///
`Who_changes_peerv2_l1andl2'

tab timeq _merge, missing
tab number_common_l1andl2 _merge, missing

drop _merge
sort GUID timeq



cd "$location_cleaned_data"

merge GUID timeq using ///
"081018 CC  WW  SS GEO RATING RANK LM Peer common M2.dta" 

tab timeq _merge



//DROPPING VALUES THAT WERE ONLY IN THE R DATA (THAT ARE FILLED ONLY WITH 0)
des number*, fullnames
tab number_period_l1andl2 if _merge==1
tab number_common_l1andl2 if _merge==1
tab number_period_l1andl3 if _merge==1
tab number_common_l1andl3 if _merge==1


drop if _merge==1
codebook distance
//REPLACING WITH MISSING VALUES THOSE QUARTERS FOR WHICH WE DO NOT HAVE DATA TO EVALUATE IF THERE WERE PEERS
//recall label var distance "timeq-StartPolice_qt (quarter)"


replace number_common_l1andl2=. if distance<2 
//if start date is in 2013q1, then:
//    in 2013q1 distance=0, 
//    in 2013q2 distance=1, 
//    in 2013q3 distance=2
//since we want to know the peers in t-1 and  t-2, 
//    in 2013q1 we do not know the group of peers for both 2012q4 2012q3
//    in 2013q2 we do not know the group of peers for both 2012q4 2013q1
//    in 2013q3 we DO     know the group of peers for both 2013q1 2013q2 <<< when the distance= 2

replace number_period_l1andl2=. if distance<2

replace number_common_l1andl3=. if distance<3
replace number_period_l1andl3=. if distance<3


tab distance	_merge 

//REPLACING WITH MISSING THOSE QUARTERS FOR WHICH WE DO NOT HAVE A LINE MANAGER IN  t-1



bysort GUID (timeq): gen had_LM_in_l1=1 if !missing(LinemanagerGUIDRef_right[_n-1])


replace number_period_l1andl2=. if missing(had_LM_in_l1)
replace number_period_l1andl3=. if missing(had_LM_in_l1)


replace number_common_l1andl2=. if missing(had_LM_in_l1)
replace number_common_l1andl3=. if missing(had_LM_in_l1)







tab des only_one_guy, missing


label var number_period_l1andl2 "number of peers in l1, excludes obs periods before 2011q4" //excludes selfcount
label var number_common_l1andl2 "number of peers that worked with employee in q1 & q2"


label var number_period_l1andl3 "number of peers in l1, excludes obs periods before 2012q1" //excludes selfcount
label var number_common_l1andl3 "number of peers that worked with employee in q1 & q3"



local period "l1andl2 l1andl3"

local n : word count `period'

 forvalues i = 1/`n' {
  local a : word `i' of `period'

gen proportion_`a'=number_common_`a'/number_period_`a'
tab proportion_`a', missing
tab number_period_`a' if proportion_`a'==1



gen proportion_per_`a'=0 if proportion_`a'==0
replace proportion_per_`a'=10 if proportion_`a'>0 & proportion_`a'<=.10
replace proportion_per_`a'=20 if proportion_`a'>0.1 & proportion_`a'<=.20
replace proportion_per_`a'=30 if proportion_`a'>0.2 & proportion_`a'<=.30
replace proportion_per_`a'=40 if proportion_`a'>0.3 & proportion_`a'<=.40
replace proportion_per_`a'=50 if proportion_`a'>0.4 & proportion_`a'<=.50
replace proportion_per_`a'=60 if proportion_`a'>0.5 & proportion_`a'<=.60
replace proportion_per_`a'=70 if proportion_`a'>0.6 & proportion_`a'<=.70
replace proportion_per_`a'=80 if proportion_`a'>0.7 & proportion_`a'<=.80
replace proportion_per_`a'=90 if proportion_`a'>0.8 & proportion_`a'<=.90

replace proportion_per_`a'=100 if proportion_`a'>0.9 & proportion_`a'<=1

tab proportion_per_`a' timeq, missing
***

label define proportion_p_`a' ///
0 "0% of l1 peers worked with employee in l1 and see name" ///
10 "0-10% of l1 peers worked with employee  in l1 and see name" ///
20 "10-20% of l1 peers worked with employee in  l1 and see name" ///
30 "20-30% of l1 peers worked with employee in  l1 and see name" ///
40 "30-40% of l1 peers worked with employee in  l1 and see name" ///
50 "40-50% of l1 peers worked with employee in  l1 and see name" ///
60 "50-60% of l1 peers worked with employee in  l1 and see name" ///
70 "60-70% of l1 peers worked with employee in  l1 and see name" ///
80 "70-80% of l1 peers worked with employee in  l1 and see name" ///
90 "80-90% of l1 peers worked with employee in  l1 and see name" ///
100 "90-100% of l1 peers worked with employee in  l1 and see name" , replace

label value proportion_per_`a' proportion_p_`a'
 
}


codebook GUID if proportion_per_l1andl2==0 // 37765 people

gen quarter= quarter(dofq(timeq))
gen year= year(dofq(timeq))
tab quarter year
rename approx_length_service_years approx_ls_years
 gen   approx_ls_years_2=  approx_ls_years*approx_ls_years

 
 des *peer*, fullnames
 
 
 keep des* approx_* quarter year ///
 LengthofServiceGroup_d ///
 approx_group_ls ///
  GUID timeq Line* ///
  had* ///
  num* ///
 Action_6  ///
  rating* *rank* ///
mean* ///
num_id ///
proportion_per_* ///
Gender        ///
EmployeeType_wf_3cat_d ///
level3_territorial_police_v2 ///
level4_territorial_police_v2 ///
EmployeeType_wf_3cat_d subset

encode Gender , gen(Gender_d)

tab number_peers_with_complaint num_peer_complaint_M2, missing
tab number_peers_with_complaint num_peer_complaint_M1, missing  //same
drop number_peers_with_complaint


tab number_peer_right num_peer_complaint_M2, missing
tab number_peer_right num_peer_complaint_M1, missing 

tab num_peer_complaint_M1 num_peer_complaint_M2, missing

gen proportion_peer_com= num_peer_complaint_M2/number_peer_right
tab number_peer_right descrip, missing

label var proportion_peer_com "proportion of peer with M2 complaints: num_peer_complaint_M2/num_peer_right"
codebook proportion_peer_co
// recall M2 is the when we consider as a peer misconduct only those reports that occurred in dates in which the target person has no misconduct
// recall M1 considers any report from peers


// ---------------------------------------------
// creating lags of peer misconduct
// ---------------------------------------------

foreach var of varlist ///
had_peer_complaint_M2 ///
number_peer_right ///
{
bysort num_id (timeq): gen `var'_l1=L.`var'
bysort num_id (timeq): gen `var'_l2=L2.`var'
bysort num_id (timeq): gen `var'_l3=L3.`var'
}



xtset num_id timeq
gen prop_peer_co_l1=L.proportion_peer_co
label var prop_peer_co_l1 "proportion of my peers in t-1 with M2 complaints"
gen prop_peer_co_l2=L2.proportion_peer_co
label var prop_peer_co_l2 "proportion of my peers in t-2 with M2 complaints"
gen prop_peer_co_l3=L3.proportion_peer_co
label var prop_peer_co_l3 "proportion of my peers in t-3 with M2 complaints"
gen prop_peer_co_l4=L4.proportion_peer_co
label var prop_peer_co_l4 "proportion of my peers in t-4 with M2 complaints"

xtset num_id timeq
 
cd "$location_cleaned_data"


 save "101018 DATA UPDATED WITH PEERS L1ANDXX.dta", replace

//
//_______________________________________________________________________________________
//
// FOR THE CASES IN WHICH THERE WERE MORE THAN ONE NEW PEER MOVING TO THE TARGET GROUP IN T-1 & 
// TARGET DO NOT FACE A COMPLETE SET OF NEW PEERS IN T-1
// (BECAUSE HE HAS NOT MOVED OR BECAUSE HE HAS MOVED WITH SOME PEERS)
// 
//________________________________________________________________________________________


cd "$location_cleaned_data"


 use "101018 DATA UPDATED WITH PEERS L1ANDXX.dta", clear

 
 xtset num_id timeq
tab timeq, missing
// keeping those GUID that move in t-1. So... 
//   (1) peers in t-1 differnt from peers in  t-2 &
//   (2) peers in t-1 differnt from peers in  t-3  
//    in consequience, GUID moves in t-1
//    (recall that peers remain for at least 2 quarters, so new peers in t-1 remain as peers in t)

codebook GUID if  proportion_per_l1andl2==0 & ///
  proportion_per_l1andl3==0 // 

keep if  proportion_per_l1andl2==0 & ///
  proportion_per_l1andl3==0 


codebook GUID //

// keeping the GUID and the quarters t (only those who move in -1)
keep GUID timeq
sort GUID timeq

tempfile GUIDs_who_move_in_t_1
save `GUIDs_who_move_in_t_1'


//-----------------------------------------------------------------------------------------------------
// FINDING WHEN THERE WERE SIMULTANEOUS MOVEMENTS AND WHEN THERE WAS ONLY ONE MOVEMENT TO THE NEW LINE MANAGER 
//-----------------------------------------------------------------------------------------------------

 use "101018 DATA UPDATED WITH PEERS L1ANDXX.dta", clear
 tab had_case_complaint, missing
 des had_case_complaint*
 xtset num_id timeq

//MERGE WITH GUID who moved in t-1

sort GUID timeq
merge GUID timeq using ///
`GUIDs_who_move_in_t_1'


xtset num_id timeq
bysort num_id (timeq): gen merge2=_merge[_n+1]
// if for instance timeq==2013q1 in _merge==3, then target moved in 2012q4
// we create merge2=3 in 2012q4 to flag the quarters of movement

keep if merge2==3 //they move here
// so we keep only the quarters when target moved to a new manager


// NOTES 
// -------
//  - the GUIDs are only those who move in t-1
//  - but the quarter we observe in the data now is now the quarter of movement. To avoid confusion, we can call the quarter
//    of this data 't_mov'
//  - for each people who move now, we have variables for the...
//            ... "proportion of peers in quarter 't_mov'     with M2 complaints"  >>  prop_peer_com
//            ... "proportion of peers in quarter 't_mov - 1' with M2 complaints"  >>  prop_peer_co_l1
//            ... "proportion of peers in quarter 't_mov - 2' with M2 complaints"  >>  prop_peer_co_l2
//  - for each line manager, we have the people who moved in quarter 't_mov' to their group

//  -- we will sum these proportions for each LM

bysort LinemanagerGUIDRef_right timeq: egen  sum_prop=sum( proportion_peer_com)
// so for the LM, we get the sum of the proportions of his current employees moving to his group (the prop they had in current quarter)
replace sum_prop=. if missing(LinemanagerGUIDRef_right)

bysort LinemanagerGUIDRef_right timeq: egen  count_prop=count( proportion_peer_com)
replace count_prop=. if missing(LinemanagerGUIDRef_right)

bysort LinemanagerGUIDRef_right timeq: egen  sum_prop_in_l1=sum( prop_peer_co_l1)
// so for LM, we get the sum of proportions of all his current employees moving to his group (the prop they had in quarter 't_mov - 1')
replace sum_prop_in_l1=. if missing(LinemanagerGUIDRef_right)

bysort LinemanagerGUIDRef_right timeq: egen  count_prop_in_l1=count( prop_peer_co_l1)
replace count_prop_in_l1=. if missing(LinemanagerGUIDRef_right)

bysort LinemanagerGUIDRef_right timeq: egen  sum_prop_in_l2=sum( prop_peer_co_l2)
//so for LM we get the sum of proportions of all his current employees moving to his group (the prop they had in quarter 't_mov - 2')
replace sum_prop_in_l1=. if missing(LinemanagerGUIDRef_right)

bysort LinemanagerGUIDRef_right timeq: egen  count_prop_in_l2=count( prop_peer_co_l2)
replace count_prop_in_l2=. if missing(LinemanagerGUIDRef_right)


// Note that we do not have proportions for the people that is not part of the subset of employee types included
// (recall we only have records of misconducts for some employee types, the most common ones, police civil staff, special constabulary)

// we create the average of the following variables (which include the peers of the target person): 'prop_peer_com', 'prop_peer_co_l1', 'prop_peer_co_l2'


gen sum_prop_nome=sum_prop- proportion_peer_com
gen average_prop_peer=sum_prop_nome/(count_prop-1)

label var average_prop_peer "for a person, the average of the prop.peer (in current quarter) of their current peers"
// above and in the following variable labels, by 'current peers' we mean current peers moving in 't_mov'
gen sum_prop_nome_in_l1=sum_prop_in_l1- prop_peer_co_l1
gen average_prop_peer_in_l1=sum_prop_nome_in_l1/(count_prop_in_l1-1)

label var average_prop_peer_in_l1 "for a person, the average of the prop.peer (in t-1) of their current peers"

gen sum_prop_nome_in_l2=sum_prop_in_l2- prop_peer_co_l2
gen average_prop_peer_in_l2=sum_prop_nome_in_l2/(count_prop_in_l2-1)

label var average_prop_peer_in_l2 "for a person, the average of the prop.peer (in t-2) of their current peers"

gen used_this=1

drop _merge
keep GUID timeq average* count* sum* prop_pee* proportion_peer_com* LinemanagerGUIDRef_right subset

tab count_prop_in_l1 if sum_prop_nome_in_l1!=0 , missing
tab count_prop_in_l1 if sum_prop_nome_in_l1==0 , missing
tab count_prop_in_l1 if average_prop_peer_in_l1==. & !missing(sum_prop_nome_in_l1)
tab sum_prop_nome_in_l1 if average_prop_peer_in_l1==. & !missing(sum_prop_nome_in_l1), missing
list count_prop	count_prop_in_l1	count_prop_in_l2 subset	LinemanagerGUIDRef_right if ///
count_prop_in_l1!=count_prop_in_l2

// note that 'count_prop' could be > and != to 'count_prop_in_l1' or 'count_prop_in_l2'
// this is because some of the people who moved had missing in their proportions in l1 (i.e., in 't_mov - 1')
// (perhaps they had no peers or perhaps they had peers that were not part of the subset (so they had other 
//  employee type that is not part of the analysis))

// In this data, we only have people who move, so
//  if only ONE GUID MOVE to a new LM, the count=1 and the average=SUM(prop_nome...)/(count-1) = sum(prop_nome...)/0= MISSING 

//  if the sum(prop_nome...)==0, then only the target is the person who moves to the LM
//  so the average is missing when sum(prop_nome...)==0
des average*, full
tab count_prop_in_l1 average_prop_peer_in_l1 if missing(average_prop_peer_in_l1), missing
tab sum_prop_nome_in_l1 if missing(average_prop_peer_in_l1), missing

// ABOVE WE COMPUTED THE INSTRUMENTS FOR THE PEOPLE WHO MOVED AND HAVE OTHER PERSON(S) WHO ALSO MOVED TO THE SAME LM
// NOW WE WILL COMPUTE THE INSTRUMENTS FOR THE PEOPLE WHO STAY BUT HAVE OTHER PERSON WHO MOVED TO HIS LM



tab   count_prop_in_l1 if count_prop==1, missing
tab count_prop if missing(Line), missing //no obs



bysort Line timeq: gen many_movement=_N

tab many_movement
tab count_prop
// recall sum_prop_in_l1:
// for LM receiving only one new employee, sum_prop_in_l1 has the sum of proportions of this one
// employee moving to his group (the prop they had in quarter 't_mov - 1')
// recall proportion_peer_com is the "proportion of peer with M2 complaints: num_peer_complaint_M2/num_peer_right"

replace sum_prop_in_l1=. if missing(LinemanagerGUIDRef_right)

gen average_prop_peer_in_l1_for =sum_prop_in_l1/count_prop_in_l1 
gen average_prop_peer_in_l2_for =sum_prop_in_l2/count_prop_in_l2 
gen average_prop_peer_for =sum_prop/count_prop

sum average_prop_peer_in_l1_for  if count_prop_in_l1==0
sum average_prop_peer_in_l2_for  if count_prop_in_l2==0


replace average_prop_peer_in_l1_for =. if count_prop_in_l1==0
replace average_prop_peer_in_l2_for =. if count_prop_in_l2==0



//average_prop_peer_for
//...for a LM receiving any "new" employee (here "new" means a employee that has not meet any of the LM employees in 't_mov-1' & 't_mon-2'
// we get the average_prop_peer_in_for including any "new" peer   
// (Note that we are not discounting the 'count_prop_in..." by one, as before, because we will work on the cases in which 
// the target HAS NOT MOVED TO A COMPLETE SET OF NEW PEERS, so he is not part of the counts included in the 
// 'average_prop_peer...". Not moving to a complete set of new peers means either (1) his LM is the same or 
// (2) some of his old peers are still working with him. 

// In any of these cases, because the 'average_prop_peer..." are used to build instruments, we cannot use the target
// as an instrument to see his effect on 'H', for instance.
// Note that so far we were talking about 'H' old peers (I, J and K) as instruments for the effect of T's peers in t-1, 
// see below in Table "WHEN TARGET MOVES - CASE 1". But we can think on the other way around and imagine that the target is 'H' now.
// Observe that 'T' old peers (A, B and C) can be used as instruments  of the effect of H' peers in t-1. 
// We have consider these possibilities in our analysis, so far.
// 
// But WHEN 'T' DOES NOT MOVE, we are excluding the possibility that the 'T' can be used as an instrument for the 
// effect of H's peers in t-1. 'T' cannot be used to build an instrument because his peers in t-2 and t-3 (A, B and C)
// have a direct effect on 'H' in t-1.

// The same situation happens in the table "WHEN TARGET MOVES - CASE 2": T's peers in t-2 and t-3 cannot be used as instruments
// for the effect of 'H's peers in t-1. Because T's peers in t-2 and t-1 includes 'A', and 'A' has a direct contact with 'H' in t-1
// for these reason the target is not used to build an instrument. 


//  WHEN TARGET ('T' in the table) MOVES:
//  =========
//   CASE 1
//  =========
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


//  WHEN TARGET ('T' in the table) MOVES:
//  =========
//   CASE 2
//  =========
//________________________________________________________________________________________________________________________________
//
//			Line Manager 1		Line Manager 2			Line Manager 3		Instruments
//									
// t-3		T, A, B, C			D, E, F, G				H, I, J, K			P2 = Proportion of H's peers with misconduct in t-3									
//									
// t-2		T, A, B, C			D, E, F, G				H, I, J, K			P1 = Proportion of H's peers with misconduct in t-2
//																		
// t-1		B, C, L				T, A, D, E, F, G, H		I, J, K, M											
//									
// t		B, C, L				T, A, D, E, F, G, H		I, J, K, M		
//																	
//________________________________________________________________________________________________________________________________



//  WHEN TARGET DOES NOT MOVE:
//________________________________________________________________________________________________________________________________
//
//
//			Line Manager 1		Line Manager 2		Line Manager 3		Instruments
//									
// t-3		T, A, B, C			D, E, F, G			H, I, J, K			P2 = Proportion of H's peers with misconduct in t-3
//																		
// t-2		T, A, B, C			D, E, F, G			H, I, J, K			P1 = Proportion of H's peers with misconduct in t-2
//																		
// t-1		T, A, B, C, H		D, E, F, G			I, J, K, M											
//								
// t		T, A, B, C, H		D, E, F, G			I, J, K, M		
//									
//________________________________________________________________________________________________________________________________
//

//   IMPORTANT: recall that the computation of 'proportion_peer_com' and lagged values includes ALL PEERS, 
//              not only the ones ho moved. 
label var average_prop_peer_for  "for a LM with at least a new employee in current quarter, average of his employees prop.peer (in t) "



label var average_prop_peer_in_l1_for "for a LM with at least a new employee in current quarter, average of his employees prop.peer (in t-1) "

label var average_prop_peer_in_l2_for "for a LM with at least a new employee in current quarter, average of his employees prop.peer (in t-2) "

capture drop any_movement
gen any_movement=1
des avera*, full
sum avera*

// average_prop_peer                 for a person, the average of the prop.peer (in current quarter) of their current
// average_prop_peer_in_l1
// average_prop_peer_in_l2
// average_prop_peer_in_l1_for       for a person who was the only moving in current quarter, his prop.peer  (in t-1)
// average_prop_peer_in_l2_for
// average_prop_peer_for





tempfile restricted_peer_quarter_t_1
save `restricted_peer_quarter_t_1'



keep GUID LinemanagerGUIDRef_right timeq average*for  count* 
drop if missing(average_prop_peer_in_l1_for) & ///
missing(average_prop_peer_in_l2_for) & ///
missing(average_prop_peer_for)
		
rename GUID I_moved


sort LinemanagerGUIDRef_right timeq
cd "$location_cleaned_data"

save "101018 restricted peer 3 periods and quarter t-1 including for any movement", replace

des
use `restricted_peer_quarter_t_1'
des
keep GUID timeq  average_prop_peer  average_prop_peer_in_l1 average_prop_peer_in_l2

sort GUID timeq

save "101018 restricted peer 3 periods and quarter t-1_copy", replace

sum ave*



use "101018 restricted peer 3 periods and quarter t-1_copy", clear //this data was done in the analysis of just one movement

sum ave* 

use "101018 restricted peer 3 periods and quarter t-1 including for any movement", clear
tab timeq, missing

//We should have the same average for same LM timeq

bysort Line timeq average_prop_peer_in_l1_for: gen one_count=_n==1
bysort Line timeq (average_prop_peer_in_l1_for): egen many_count=sum(one_count)
tab many_count //1

drop one_count many_count

bysort Line timeq average_prop_peer_in_l2_for: gen one_count=_n==1
bysort Line timeq (average_prop_peer_in_l2_for): egen many_count=sum(one_count)
tab many_count //1

drop one_count many_count

bysort Line timeq: gen many_count=_N
tab many_count //1

drop I_moved many_count
duplicates drop
gen LM_has_new=1
sort LinemanagerGUIDRef_right timeq

save "101018 restricted peer 3 periods and quarter t-1 including for any movement LM", replace

// ----------------------------------------------------
// PREPARING CONTROLS AND VARIABLES FOR REGRESSIONS
// ----------------------------------------------------



cd "$location_cleaned_data"

 use "101018 DATA UPDATED WITH PEERS L1ANDXX.dta", clear
 tab had_case_complaint, missing
 des had_case_complaint*


  bysort num_id (timeq): egen many_complaints=sum(had_case_complaint)

tab many_complaints, missing

//1) PREPARING CONTROLS IN DATA

bysort num_id (timeq): gen LinemanagerGUIDRef_right_l1=LinemanagerGUIDRef_right[_n-1] 
bysort num_id (timeq): gen LinemanagerGUIDRef_right_l2=LinemanagerGUIDRef_right[_n-2] 
bysort num_id (timeq): gen LinemanagerGUIDRef_right_l3=LinemanagerGUIDRef_right[_n-3] 

// lagged values

foreach var of varlist ///
had_case_complaint ///
rating_4cat_d   ///    
rating_3cat_d   ///  but with rating of 3 cat                  
rating_4cat_LM_d ///
rating_3cat_LM_d {
bysort num_id (timeq): gen `var'_l1=L1.`var'
bysort num_id (timeq): gen `var'_l2=L2.`var'
bysort num_id (timeq): gen `var'_l3=L3.`var'
bysort num_id (timeq): gen `var'_l4=L4.`var'
}



label val 	rating_4cat_d* rating_4cat_LM_d* rating4cat	   
label val 	rating_3cat_d* rating_3cat_LM_d* rating3cat	   



//2) MERGING WITH INSTRUMENTS (FOR PEOPLE WHO MOVED AND NEW PEERS WHO MOVED SIMULTANEOUSLY TO LM2 IN OUR EXAMPLE)
sort GUID timeq
merge GUID timeq using ///
"101018 restricted peer 3 periods and quarter t-1_copy"

 xtset num_id timeq

 bysort num_id (timeq): gen instrument1=L.average_prop_peer_in_l1
 bysort num_id (timeq): gen instrument2=L.average_prop_peer_in_l2 

 sort GUID timeq
save "101018 restricted peer 3 periods and quarter t-1 no including for any movement", replace
use "101018 restricted peer 3 periods and quarter t-1 no including for any movement", clear

//3) NOW MERGING WITH PEOPLE WHO STAYED BUT PEERS MOVED
//  (recall we know who moved alone to a new LM. The target is the one who stayed but received the new peer
//   the target is not the new peer (so we replace the average_prop_peer_in...for as missing when GUID==I_moved)

drop _merge
sort LinemanagerGUIDRef_right timeq
merge LinemanagerGUIDRef_right timeq using ///
 "101018 restricted peer 3 periods and quarter t-1 including for any movement LM"

 codebook GUID if  proportion_per_l1andl2==0 & ///
  proportion_per_l1andl3==0 

 gen I_moved_last_quarter=1 if  proportion_per_l1andl2==0 & ///
  proportion_per_l1andl3==0 

  tab I_moved_last_quarter, missing
xtset num_id timeq
bysort num_id (timeq): gen I_moved_this_quarter=I_moved_last_quarter[_n+1]
 
 tab I_moved_this_quarter LM_has_new, missing
 
 sum(average_prop_peer_in_l1_for) if LM_has_new!=1 //0 obs, ok
 sum(average_prop_peer_in_l2_for) if LM_has_new!=1 //0 obs, ok
 sum(average_prop_peer_for) if LM_has_new!=1 //0 obs, ok

 codebook average_prop_peer_in_l1_for if LM_has_new==1 
 codebook average_prop_peer_in_l2_for if LM_has_new==1 
 codebook average_prop_peer_for if LM_has_new==1 

 
 
 
 replace average_prop_peer_in_l1_for=. if I_moved_this_quarter==1
 replace average_prop_peer_in_l2_for=. if I_moved_this_quarter==1
 replace average_prop_peer_for=. if I_moved_this_quarter==1

tab instrument1 if !missing(average_prop_peer_in_l1_for)
tab instrument2 if !missing(average_prop_peer_in_l1_for) 
tab instrument1 if !missing(average_prop_peer_in_l2_for)
tab instrument2 if !missing(average_prop_peer_in_l2_for) 
tab instrument1 if !missing(average_prop_peer_for)
tab instrument2 if !missing(average_prop_peer_for) 

 xtset num_id timeq

 bysort num_id (timeq): gen instrument1for=L.average_prop_peer_in_l1_for
 bysort num_id (timeq): gen instrument2for=L.average_prop_peer_in_l2_for 

list if !missing(instrument1for) & !missing(instrument1)
list if !missing(instrument2for) & !missing(instrument2)

replace instrument1=instrument1for if missing(instrument1)
replace instrument2=instrument2for if missing(instrument2)



keep if subset==1
cd "$location_cleaned_data"

save "101018 restricted peer 3 periods t-1 quarter new way_any_movement", replace
// we called it new way because we added the cases in which the target remains and a new peer(s) comes
use "101018 restricted peer 3 periods t-1 quarter new way_any_movement", clear
