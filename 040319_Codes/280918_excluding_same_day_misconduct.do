///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//   Finding peers' misconduct that were made in a different day than the misconduct reported for the target police
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////

// This script shows how to compute first and last complaint record of the target police and his peers
 

cd "$location_data"
import delimited "CC_STATA.txt", case(preserve)  clear

describe, fullnames

//Variable names were imported in the wrong position. We need to move the names one column to the right

rename	CaseNumber	Order //'Order': order of rows
rename	CaseRecorded	CaseNumber  //'CaseNumber': case number (string)
rename	AllegSeqNumber	CaseRecorded //'CaseRecorded': date
rename	TypeDescription	AllegSeqNumber //'AllegSeqNumber': record within the 'CaseNumber' 
rename	GUID	TypeDescription
rename	Result	GUID //'GUID': ID for each staff/officer
rename	Action	Result //'Result': Substantiated, No case to answer, etc.
rename	FormalActionSanction	Action //'Action': Formal action, management action, etc.
rename	CaseNo	FormalActionSanction
rename	EmployeeType	CaseNo //'CaseNo': case number (numeric)
rename	DuplicateCount	EmployeeType
rename	CountPerPerson	DuplicateCount
rename	CountPerCase	CountPerPerson //'CountPerPerson': count of cases of a person during the data period (before deleting duplicates)
rename	v14	CountPerCase //'CountPerCase': count of reports/allegation under the same case number (before deleting duplicates)


// Deleting labels
foreach var of varlist _all {
	label var `var' ""
}

gen CaseNumber2=substr(CaseNumber,7,10)
destring CaseNumber2, replace

sort CaseNumber2 Order

//Note: Allegations are not always sequentially numbered. So not all allegations have a sequence starting from 1
bysort CaseNumber2 (Order): gen case_n=_n //Creating the order of allegation within the case
   
gen AllegSeqNumber2=AllegSeqNumber

sort CaseNo Order
//Verifiying the duplicate counts
bysort CaseNumber CaseRecorded AllegSeqNumber GUID: gen GUID_CR_All_CN=_N
tab GUID_CR_All_CN

tab DuplicateCount GUID_CR_All, missing //they are exactly the samve

//keeping the first record of the duplicates	 
	 
unab vlist : CaseNumber CaseRecorded AllegSeqNumber TypeDescription Result Action FormalActionSanction EmployeeType GUID
     sort `vlist'
     quietly by `vlist':  gen dup = cond(_N==1,0,_n)
	 tab dup GUID_CR_All_CN
drop if dup>1
drop dup
unab vlist : CaseNumber CaseRecorded AllegSeqNumber GUID

     sort `vlist'
     quietly by `vlist':  gen dup = cond(_N==1,0,_n)
tab dup //no duplicates
drop dup

//saving a temporary file with misconduct records without duplicates
tempfile 270117_raw_cc_no_duplicates
save `270117_raw_cc_no_duplicates', replace



// formating dates
gen my1 = date(CaseRecorded, "YMD")
drop CaseRecorded
format my1 %td
rename my1 CaseRecorded
gen timeq=qofd(CaseRecorded)
format timeq %tq
tab timeq

bysort GUID timeq (CaseRecorded Order): gen n=_n
bysort GUID timeq (CaseRecorded Order): gen n_end=_n==_N

bysort GUID timeq (CaseRecorded Order): gen first_complaint_date_acu=CaseRecorded if n==1
bysort GUID timeq (CaseRecorded Order): gen last_complaint_date_acu=CaseRecorded if n==_N
bysort GUID timeq: gen many=_N

gen firstc=first
gen lastc=last

//dates for first and last records of complaints
format first* last* %td
bysort GUID timeq (CaseRecorded Order): replace firstc = firstc[_n-1] if firstc >= . 
gsort GUID timeq -Order
by GUID timeq: replace lastc = lastc[_n-1] if lastc >= . 

sort GUID timeq (CaseRecorded Order)

//keeping one obs per person
keep GUID CaseR timeq firstc lastc many n
keep if n==1


drop CaseR
sort GUID timeq
list  if firstc!= lastc in 1/100


cd "$location_cleaned_data"

merge GUID timeq using ///
 "081018 CC  WW  SS GEO RATING RANK LM Peer common.dta"

des, fullnames
label var firstc "first complaint of GUID in quarter"
label var lastc "last complaint of GUID in quarter"

tab timeq _merge
drop if _merge==1 //dropping 2010 and 2011q1 obs  that were excluded from the big data


// creating a dummy for any record of misconduct in the quarter
gen had_case_complaint=0
replace had_case_complaint=1 if sum_unique_caseNo>0 & !missing(sum_unique_caseNo)
tab _merge had_case_complaint, missing

tab had_case_complain if missing( firstc)
tab had_case_complain if !missing( firstc) & had_case_complain==0 //no observations  

// counts of sanctions received in the quarter
tab Action_1 // Formal Action
tab Action_2 // Management Action
tab Action_3 // No Action
tab Action_4 // Retired/Resigned //few obs
tab Action_5 // UPP //few obs
tab Action_6 // Unknown Action


tab subset, missing
replace subset=0 if Action_4>=1 & !missing(Action_4)
replace subset=0 if Action_5>=1 & !missing(Action_5)

label var subset_complaints "EmployeeType_wf Civil Staff, Civil Staff (Police Community Support Officer), Police, Special Constabulary). Exluding Retired and UPP"

// creating dummies
gen has_action1=0
replace has_action1=1 if Action_1>=1 & !missing(Action_1)
gen has_action2=0
replace has_action2=1 if Action_2>=1 & !missing(Action_2)
gen has_action3=0
replace has_action3=1 if Action_3>=1 & !missing(Action_3)
gen has_action6=0
replace has_action6=1 if Action_6>=1 & !missing(Action_6)

	  

 // Number of PEERS in quarter
 //---------------------------
 
bysort LinemanagerGUIDRef_right timeq: gen number_peer_right=_N
replace number_peer_right=. if missing(LinemanagerGUIDRef_right) 
replace number_peer_right=number_peer_right-1
tab num_people_quarter_same_manager number_peer_right if number_peer_right<15

label var number_peer_right "Number of PEERS in quarter, it does not matter whether they have rank or not"




drop _merge
sort Line timeq

tempfile 270117_data_actions
save `270117_data_actions', replace




collapse (sum) had_case_complain has_action1 ///
 has_action2  has_action3 has_action6 ///
 (lastnm) number_peer_right ///
 , by(LinemanagerGUIDRef_right timeq)
 
 
drop if missing(LinemanagerGUIDRef_right)


rename had_case_complain num_complaint_group_right
rename has_action1 number_action1_group_right
rename has_action2 number_action2_group_right
rename has_action3 number_action3_group_right
rename has_action6 number_action6_group_right
rename number_peer_right number_peer_right_check

sort LinemanagerGUIDRef_right timeq


sort Line timeq
merge LinemanagerGUIDRef_right timeq using ///
`270117_data_actions'

tab timeq _merge


des number_*, fullnames
tab number_peer_right* if number_peer_right<10, missing
list if number_peer_right!=number_peer_right_check
drop number_peer_right_check

label var num_complaint_group_right "number of people under same LM who had complaints in quarter (includes self)"
label var number_action1_group_right "number of people under same LM who had Formal Action  in quarter (includes self)"
label var number_action2_group_right "number of people under same LM who had Management Action in quarter (includes self)"
label var number_action3_group_right "number of people under same LM who had No Action in quarter (includes self)"
label var number_action6_group_right "number of people under same LM who had Unknown Action  in quarter (includes self)"


gen num_complaint_group_no_self= num_complaint_group_right -had_case_complain if !missing(num_complaint_group_right)
label var  num_complaint_group_no_self "number of PEERS with complaints in quarter"

tab num_complaint_group_no_self, missing //

tab num_complaint_group_right num_complaint_group_no_self if num_complaint_group_right<10
// note that we do not have a perfect diagonal because in 'num_complaint_group_no_self'  the target police might or might not have complaints


gen num_action1_group_no_self_right= ///
number_action1_group_right-has_action1
rename number_action1_group_right number_action1_group_right

tab num_action1_group_no_self*, missing

gen num_action2_group_no_self_right= ///
number_action2_group_right-has_action2

tab num_action2_group_no_self*, missing

gen num_action3_group_no_self_right= ///
number_action3_group_right-has_action3

tab num_action3_group_no_self*, missing

gen num_action6_group_no_self_right= ///
number_action6_group_right-has_action6

tab num_action6_group_no_self*, missing


label var  num_action1_group_no_self  "number of PEERS with Formal Action  in quarter (including same case)"
label var  num_action2_group_no_self  "number of PEERS with Management Action  in quarter (including same case)"
label var  num_action3_group_no_self  "number of PEERS with No Action  in quarter (including same case)"
label var  num_action6_group_no_self  "number of PEERS with Unknowm Action in quarter (including same case)"


// NOTE THAT COMPLAINTS RECEIVED BY THE GROUP COULD BE ABOUT THE SAME CASE
// WE WANT TO KNOW HOW MANY PEOPLE HAVE BEEN INVOLVED IN MISCONDUCT IN QUARTER T (EXCLUDING THE CASES IN WHICH THE TARGET GUID
// WAS ALSO INVOLVED
 

 
drop _merge
sort GUID timeq

save "081018  CC  WW  SS GEO RATING RANK LM Peer common - t2.dta", replace

keep  GUID ///                       
timeq     ///                  
had_case_complain ///
LinemanagerGUIDRef_right ///
lastc ///
firstc ///
num_complaint_group_right ///
number_action1_group_right ///
number_action2_group_right ///
number_action3_group_right ///
number_action6_group_right ///
number_peer_right ///
num_complaint_group_no_self ///
num_action1_group_no_self_right ///
num_action2_group_no_self_right ///
num_action3_group_no_self_right ///
num_action6_group_no_self_right 

sort GUID timeq

tempfile 270117_data_actions_group
save `270117_data_actions_group', replace



 clear
 
  use `270117_raw_cc_no_duplicates', clear

gen my1 = date(CaseRecorded, "YMD")
drop CaseRecorded
format my1 %td
rename my1 CaseRecorded
gen timeq=qofd(CaseRecorded)
format timeq %tq
tab timeq

tab Action, missing
replace Action="Unknown Action" if missing(Action)

 sort GUID timeq
merge GUID timeq using ///
 `270117_data_actions_group'

 tab timeq _merge 
 drop if _merge==1
 
 tab had_case _merge, missing

 
 keep if _merge==3
 drop if Action=="Retired/Resigned" | Action=="UPP"
 drop if missing(Line)

tab Action number_action1_group_right, missing
tab Action number_action2_group_right, missing
tab Action number_action3_group_right, missing
tab Action number_action6_group_right, missing

tab Action, missing
gen Action_d="Formal_Action" if Action=="Formal Action"
replace Action_d="Management_Action" if Action=="Management Action"
replace Action_d="No_Action" if Action=="No Action"
replace Action_d= "Unknown_Action" if Action=="Unknown Action"

tab Action Action_d, missing


rename num_complaint_group_no_self number_peers_with_complaint
tab number_peers_with_complaint

//====================================================================

//  NUMBER OF PEERS WITH COMPLAINTS IN A QUARTER:
// -----------------------------------------------
//  METHOD 1: INCLUDES ANY PEER
//  METHOD 2: INCLUDES PEERS WHO HAD COMPLAINTS IN A DIFFERENT DATE THAN THE TARGET INDIVIDUAL
//  We will compute method 2 in the following lines

//====================================================================


sort LinemanagerGUIDRef_right timeq GUID

egen group=group(LinemanagerGUIDRef_right timeq)
gen no_me=CaseRecorded
format no_me %td


bysort group GUID: gen in_group=_n==1
bysort group: gen order_GUID=sum(in_group)

tab order_GUID
gen c_order_GUID=order_GUID
// order_GUID identifies the person in the group, e.g., 2 means the second person of a group (LM timeq), 
// So it does not mean the second record, or records in the same day or records in different days
drop in_group


//====================================================================
//How many people had complainst in diff dates than target GUID in quarter? (Method 2)
//====================================================================
// Example 
//---------
// If target GUID had 7 peers (1, 2, 4, ... and 7), and some had complaints in DAY1 or DAY2 or DAY3 or DAY4 as listed below.
// If target GUID has a complaint in DAY1 and DAY2

//Day      Peers with complaint in diff day						
//1        (Peers 5  6  7         had complaints in day 1)		
//2		  (Peers 2  4  5  6      had complaints in day 2)
//3        (Peers 1  2  3  4      had complaints in day 3) <<<<<<<<<<<<<<<<
//4        (Peers 1  3  7         had complaints in day 4) <<<<<<<<<<<<<<<<

//how many people had complainst in different dates than target GUID in the quarter? 
//1  2  3  4  7, so 5 people
//
//the following loop counts the number of peers who had complaints in different dates
//====================================================================

set more off


replace no_me=CaseRecorded
replace c_order_GUID=order_GUID
gen no_me_c=no_me
format no_me_c %td


gen is_peer=.
gen to_count_peer=.
gen count_peer2=.

cd "$location_cleaned_data"

save "091018 for loop.dta", replace

//-------------------------------------------------------------------------------------------------
//   NUMBER OF PEERS WITH COMPLAINTS DIVIDED BY THE ACTION TYPE RECEIVED (Method 2)
//-------------------------------------------------------------------------------------------------
//   EXPLANATION OF LOOP
//-------------------------------------------------------------------------------------------------
//--For a group X ot LM timeq:
//--'no_me' has all the dates of complaints FOR GROUP X, the remaining obs are missing .
//--'no_mec' is a copy of 'no_me'

//--Imagine that the target GUID is 2
//--For the target GUID 2:
//--'no_mec' has missing (.) for all peers of 2 (e.g., 3, 4, 5).
//--It only has non-missing values for the dates of misconduct of 2.

//--Then 'no_me'== missing if 'no_me'== 'no_mec' (so it gets missing if it is equal to complaint dates of 2)
//---- so these are so far the dates of the group that are different of 2.
//---- we will only keep the dates of peers who get certain type of action, "formal action" for example. 

//---- then we count the GUIDs in 'no_me'. This count is the number of peers who get 
//---- "formal action" on a date different than any complaint the target GUID 2 received
//-------------------------------------------------------------------------------------------------

cd "$location_cleaned_data"

use "091018 for loop.dta", clear

tab Action_d, missing

local list_actions `" "No_Action" "Management_Action" "Formal_Action" "Unknown_Action""'



foreach v of local list_actions{
sort LinemanagerGUIDRef_right timeq GUID

su group, meanonly

forvalues j=1/`r(max)' {
	replace no_me=. if group!=  `j'

	replace no_me_c=no_me
	replace c_order_GUID=. if missing(no_me)
	  
	levelsof c_order_GUID, local(levels) 	 
		 foreach l of local levels {
		 *so for each person in group
		 replace no_me_c=. if c_order_GUID!=`l'
		 *replace no_me_c=. if c_order_GUID!=2
				
					levelsof no_me_c, local(levels_date) 
						foreach lev of local levels_date {
							replace no_me=. if no_me==`lev'
				
						}
		 replace no_me=. if Action_d!= "`v'"

	  
		  replace is_peer=1 if !missing(no_me) //is peer of GUID order 2
		  
		  bysort is_peer c_order_GUID: replace to_count_peer=_n==1 if !missing(is_peer)
		   
		 egen count_peer=sum(to_count_peer)
		 
		 *replace count_peer2=count_peer if c_order_GUID== 2
		 replace count_peer2=count_peer if c_order_GUID== `l' //so shows the count of the peers of GUID order 2
		  
		  drop count_peer
		  replace no_me=CaseRecorded
		  replace no_me=. if group!= `j'
		  replace no_me_c=no_me
		  replace is_peer=.
		  replace to_count_peer=.
			}
			*end of loop of each person
			
	replace no_me=CaseRecorded
	replace c_order_GUID=order_GUID
	replace no_me_c=no_me
	replace is_peer=.
	replace to_count_peer=.

}
gen count_peer2_`v'=count_peer2
}


tab Action, missing



gen num_peer_complaint_M1= number_peers_with_complaint
gen had_peer_complaint_M1=1 if number_peers_with_complaint>0
replace had_peer_complaint_M1=0 if missing(had_peer_complaint_M1)

gen num_peer_action1_M2=count_peer2_Formal_Action
gen had_peer_action1_M2=1 if num_peer_action1_M2>0
replace had_peer_action1_M2=0 if missing(had_peer_action1_M2)

gen num_peer_action2_M2=count_peer2_Management_Action
gen had_peer_action2_M2=1 if num_peer_action2_M2>0
replace had_peer_action2_M2=0 if missing(had_peer_action2_M2)

gen num_peer_action3_M2=count_peer2_No_Action
gen had_peer_action3_M2=1 if num_peer_action3_M2>0
replace had_peer_action3_M2=0 if missing(had_peer_action3_M2)

gen num_peer_action4_M2=count_peer2_Unknown_Action
gen had_peer_action4_M2=1 if num_peer_action4_M2>0
replace had_peer_action4_M2=0 if missing(had_peer_action4_M2)


gen had_peer_complaint_M2=1 if ///
had_peer_action1_M2==1 | had_peer_action2_M2==1 | had_peer_action3_M2==1 ///
| had_peer_action4_M2==1 

replace had_peer_complaint_M2=0 if missing(had_peer_complaint_M2) & !missing(Line)

tab num_peer_action4_M2

drop n_peers_with_complaint_diffdate


cd "$location_cleaned_data"

save "091018 for loop_results.dta"





//-------------------------------------------------------------------------------------------------
//   NUMBER OF PEERS WITH COMPLAINTS (no division by sanction received, just the general count) (method 2)
//-------------------------------------------------------------------------------------------------
//   EXPLANATION OF LOOP
//-------------------------------------------------------------------------------------------------
//---- Same procedure than the earlier loop but we count the number of peers who have any record of complaint   ///
//      on a date different than any complaint the target GUID received
//-------------------------------------------------------------------------------------------------

use "091018 for loop.dta", clear



gen Any_Action_d="Yes"
local list_actions `""Yes""'

foreach v of local list_actions{
sort LinemanagerGUIDRef_right timeq GUID

su group, meanonly

forvalues j=1/`r(max)' {
	replace no_me=. if group!=  `j'

	replace no_me_c=no_me
	replace c_order_GUID=. if missing(no_me)
	  
	levelsof c_order_GUID, local(levels) 	 
		 foreach l of local levels {
		 *so for each person in group
		 replace no_me_c=. if c_order_GUID!=`l'
				
					levelsof no_me_c, local(levels_date) 
						foreach lev of local levels_date {
							replace no_me=. if no_me==`lev'
				
						}
		 replace no_me=. if Any_Action_d!= "`v'"
	  
		 replace is_peer=1 if !missing(no_me) 2
		  
		 bysort is_peer c_order_GUID: replace to_count_peer=_n==1 if !missing(is_peer)
		   
		 egen count_peer=sum(to_count_peer)
		 
		 replace count_peer2=count_peer if c_order_GUID== `l' 
		  
		  drop count_peer
		  replace no_me=CaseRecorded
		  replace no_me=. if group!= `j'
		  replace no_me_c=no_me
		  replace is_peer=.
		  replace to_count_peer=.
			}
			*end of loop of each person 
			
	replace no_me=CaseRecorded
	replace c_order_GUID=order_GUID
	replace no_me_c=no_me
	replace is_peer=.
	replace to_count_peer=.

}
gen count_peer2_`v'=count_peer2
}

cd "$location_cleaned_data"

save "091018 for loop_results_general.dta"

tab Action, missing

gen num_peer_complaint_M1= number_peers_with_complaint
gen had_peer_complaint_M1=1 if number_peers_with_complaint>0
replace had_peer_complaint_M1=0 if missing(had_peer_complaint_M1)

gen num_peer_complaint_M2=count_peer2_Yes 
gen had_peer_complaint_M2=1 if num_peer_complaint_M2>0
replace had_peer_complaint_M2=0 if missing(had_peer_complaint_M2)

rename num_peer_complaint_M2 num_peer_complaint_M2_new
rename had_peer_complaint_M2 had_peer_complaint_M2_mew

tab had_peer_complaint_M2, missing


tab num_peer_complaint_M1 num_peer_complaint_M2, missing
tab had_peer_complaint_M1 had_peer_complaint_M2, missing
tab Action


bysort GUID timeq num_peer_complaint_M2: gen prob=_n==1
bysort GUID timeq: egen sumprob=sum(prob) 
tab sumprob // all 1


keep ///
GUID           ///            
Action         ///                    
CaseRecorded   ///          
timeq          ///          
LinemanagerGUIDRef_right ///
number_peers_with_complaint ///      
num_pee*     ///     
had_peer*

collapse (first)number_peers_with_complaint ///      
num_peer_*     ///     
had_peer_* ///
, by(GUID LinemanagerGUIDRef_right timeq)


sort GUID timeq
tab timeq


rename num_peer_complaint_M1 num_peer_complaint_M1_check
rename had_peer_complaint_M1 had_peer_complaint_M1_check
des, fullnames

sort GUID timeq

cd "$location_cleaned_data"

save "091018 result looop do peers for num complaints M2 collapse.dta"




// Merging the results of the second loop with those from the first loop


use "091018 for loop_results.dta", clear
tab had_peer_complaint_M2, missing


des, fullnames
tab num_peer_complaint_M1, missing
tab had_peer_complaint_M1 had_peer_complaint_M2, missing
tab Action


bysort GUID timeq num_peer_action1_M2: gen prob=_n==1
bysort GUID timeq: egen sumprob=sum(prob) 
tab sumprob
drop prob sumprob



bysort GUID timeq num_peer_action2_M2: gen prob=_n==1
bysort GUID timeq: egen sumprob=sum(prob) 
tab sumprob
drop prob sumprob


bysort GUID timeq num_peer_action3_M2: gen prob=_n==1
bysort GUID timeq: egen sumprob=sum(prob) 
tab sumprob
drop prob sumprob



bysort GUID timeq num_peer_action4_M2: gen prob=_n==1
bysort GUID timeq: egen sumprob=sum(prob) 
tab sumprob
drop prob sumprob


set more off

keep ///
GUID           ///            
Action         ///                    
CaseRecorded   ///          
timeq          ///          
LinemanagerGUIDRef_right ///
number_peers_with_complaint ///      
num_pee*     ///     
had_peer*

collapse (first)number_peers_with_complaint ///      
num_peer_*     ///     
had_peer_* ///
, by(GUID LinemanagerGUIDRef_right timeq)


sort GUID timeq
tab timeq

des, fullnames

tab num_peer_complaint_M1 number_peers_with_complaint, missing
drop number_peers_with_complaint

label var num_peer_complaint_M1 "Number of PEERS in quarter that had complaint, method M1"
label var num_peer_action1_M2 "Number of PEERS in quarter that had Formal Action complaint, method M2"
label var num_peer_action2_M2 "Numner of PEERS in quarter that had Management Action, M2"
label var num_peer_action3_M2 "Numner of PEERS in quarter that had No Action, M2"
label var num_peer_action4_M2 "Numner of PEERS in quarter that had Unkknown Action, M2"
label var had_peer_complaint_M1 "Had at least a PEER with complaint, method M1"
label var had_peer_action1_M2 "Had at least a PEER with Formal Action, M2"
label var had_peer_action2_M2 "Had at least a PEER with Management Action, M2"
label var had_peer_action3_M2 "Had at least a PEER with No Action, M2"
label var had_peer_action4_M2 "Had at least a PEER with Unknown Action, M2"
label var had_peer_complaint_M2 "Had at least a PEER with complaint, method M2 (i.e., different date)"


sort GUID timeq


merge GUID timeq using ///
 "091018 result looop do peers for num complaints M2 collapse.dta"


tab _merge



tab num_peer_complaint_M1_check num_peer_complaint_M1 //perfect diagonal
tab num_peer_complaint_M2_new
tab had_peer_complaint_M1_check
tab had_peer_complaint_M2_mew had_peer_complaint_M2, missing //perfect

drop had_peer_complaint_M1_check num_peer_complaint_M1_check had_peer_complaint_M2_mew
rename num_peer_complaint_M2_new num_peer_complaint_M2

drop _merge
sort GUID timeq

tab num_peer_complaint_M2

cd "$location_cleaned_data"

save "091018 results loop peers with num complaintM2.dta"





