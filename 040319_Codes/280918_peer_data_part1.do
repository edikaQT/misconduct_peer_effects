
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
//                                 COMPUTE THE DUMMIES FOR MISCONDUCT OF PEERS AND OTHER VARIABLES
//                                 =================================================================================================
//
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
//
// use "091018 results loop peers with num complaintM2.dta", clear
// save "081018 CC  WW  SS GEO RATING RANK LM Peer common M2.dta", replace
//
// --- creating dummies for peerS' misconduct and for peers receiving any specific sanction
// --- creating an approximation of the length of service 
// --- adding variables for the performance/rating and the police rank
//
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

cd "$location_cleaned_data"

use "091018 results loop peers with num complaintM2.dta", clear
label var num_peer_complaint_M2 "Number of PEERS in quarter that had complaint, method M2"

sort GUID timeq

merge GUID timeq using ///
 "081018  CC  WW  SS GEO RATING RANK LM Peer common - t2.dta"
 

replace num_peer_complaint_M1=num_complaint_group_no_self if had_case_complaint==0
tab num_complaint_group_no_self if missing(Line)
tab num_complaint_group_no_self num_peer_complaint_M1, missing
tab had_case_complaint, missing
list GUID subset Action_* Line timeq num_complaint_group_no_self num_peer_complaint_M1 had_case_complaint if ///
!missing(num_complaint_group_no_self) & missing(num_peer_complaint_M1)
*THE OBS THAT DID NOT MATCH WERE OUT OF THE SUBSET (RETIRED ACTION OR UPP)


bysort had_case_complaint: tab num_peer_complaint_M1 had_peer_complaint_M1, missing
replace had_peer_complaint_M1=1 if num_peer_complaint_M1 >0 & !missing(num_peer_complaint_M1 )
tab num_peer_complaint_M1 had_peer_complaint_M1, missing

replace had_peer_complaint_M1=0 if num_peer_complaint_M1 ==0 & !missing(num_peer_complaint_M1 )
tab num_peer_complaint_M1 had_peer_complaint_M1, missing
tab had_peer_complaint_M1 if missing(Line)

tab num_peer_complaint_M2 had_peer_complaint_M2, missing
tab had_peer_complaint_M2 if missing(Line)



bysort had_case_complaint: tab  _merge had_peer_complaint_M2 if subset==1 & !missing(Line), missing

//by construction, when the target GUID had no complaint in a quarter, we have a missing in the number of peers with complaints in a different date than the target GUID
//we correct that below
tab had_case_complaint had_peer_complaint_M1 if missing(had_peer_complaint_M2) & !missing(Line)

replace had_peer_complaint_M2=had_peer_complaint_M1 if missing(had_peer_complaint_M2) & !missing(Line)
bysort had_case_complaint: tab  _merge had_peer_complaint_M2 if subset==1 & !missing(Line), missing

des num*, fullnames

// creating dummies for peer complaint and for peer receiving any specific sanction

// complaint M2
// =============
bysort had_case_complaint: tab num_peer_complaint_M2 had_peer_complaint_M2, missing
replace had_peer_complaint_M2=1 if num_peer_complaint_M2 >0 & !missing(num_peer_complaint_M2 )
replace num_peer_complaint_M2=num_peer_complaint_M1 if had_case_complaint==0
tab num_peer_complaint_M1 if missing(Line)
tab num_peer_complaint_M1 num_peer_complaint_M2 if subset==1, missing

replace had_peer_complaint_M2=1 if num_peer_complaint_M2 >0 & !missing(num_peer_complaint_M2 )
replace had_peer_complaint_M2=0 if num_peer_complaint_M2 ==0 & !missing(num_peer_complaint_M2 )
tab num_peer_complaint_M2 had_peer_complaint_M2, missing

tab num_peer_complaint_M1 num_peer_complaint_M2 if subset==1, missing




// action1
// ==========
bysort had_case_complaint: tab num_peer_action1_M2 if subset==1 & !missing(Line), missing
replace num_peer_action1_M2=num_action1_group_no_self if had_case_complaint==0
tab num_action1_group_no_self if missing(Line)
tab num_action1_group_no_self num_peer_action1_M2 if subset==1, missing

replace had_peer_action1_M2=1 if num_peer_action1_M2 >0 & !missing(num_peer_action1_M2 )
replace had_peer_action1_M2=0 if num_peer_action1_M2 ==0 & !missing(num_peer_action1_M2 )
tab num_peer_action1_M2 had_peer_action1_M2, missing


// action2
// ===========
bysort had_case_complaint: tab num_peer_action2_M2 if subset==1 & !missing(Line), missing
replace num_peer_action2_M2=num_action2_group_no_self if had_case_complaint==0
tab num_action2_group_no_self if missing(Line)
tab num_action2_group_no_self num_peer_action2_M2 if subset==1, missing

replace had_peer_action2_M2=1 if num_peer_action2_M2 >0 & !missing(num_peer_action2_M2 )
replace had_peer_action2_M2=0 if num_peer_action2_M2 ==0 & !missing(num_peer_action2_M2 )
tab num_peer_action2_M2 had_peer_action2_M2, missing

//action3
//==========
bysort had_case_complaint: tab num_peer_action3_M2 if subset==1 & !missing(Line), missing
replace num_peer_action3_M2=num_action3_group_no_self if had_case_complaint==0
tab num_action3_group_no_self if missing(Line)
tab num_action3_group_no_self num_peer_action3_M2 if subset==1, missing

replace had_peer_action3_M2=1 if num_peer_action3_M2 >0 & !missing(num_peer_action3_M2 )
replace had_peer_action3_M2=0 if num_peer_action3_M2 ==0 & !missing(num_peer_action3_M2 )
tab num_peer_action3_M2 had_peer_action3_M2, missing

//action4
//========
bysort had_case_complaint: tab num_peer_action4_M2 if subset==1 & !missing(Line), missing
replace num_peer_action4_M2=num_action6_group_no_self if had_case_complaint==0
tab num_action6_group_no_self if missing(Line)
tab num_action6_group_no_self num_peer_action4_M2 if subset==1, missing

replace had_peer_action4_M2=1 if num_peer_action4_M2 >0 & !missing(num_peer_action4_M2 )
replace had_peer_action4_M2=0 if num_peer_action4_M2 ==0 & !missing(num_peer_action4_M2 )
tab num_peer_action4_M2 had_peer_action4_M2, missing



drop _merge



// CREATING NEW LENGTH OF SERVICE (CONTINUOUS)
//--------------------------------------------


gen distance=timeq-StartPolice_qt

tab distance
set more off


label var distance "timeq-StartPolice_qt (quarter)"

des *tar*, fullnames
tab StartPolice_qt timeq
//recall we constrained the data:
//Keep if StartPolice_qt<=timeq | missing(StartPolice_qt)
 gen StartPolice_qt_approx=StartPolice_qt
 
 
 gen LatestStartPolice_d= date(LatestStartDate, "DMY")
format LatestStartPolice_d %td
drop LatestStartDate
gen LatestStartPolice_qt=qofd(LatestStartPolice_d)
format LatestStartPolice_qt %tq
tab LatestStartPolice_qt LengthofServiceGroup, missing
tab StartPolice_qt LengthofServiceGroup, missing
tab LatestStartPolice_qt LengthofServiceGroup if ///
LatestStartPolice_qt>timeq, missing
tab LatestStartPolice_qt LengthofServiceGroup if ///
LatestStartPolice_qt>timeq & had_case_complaint==1, missing
 

 tab LatestStartPolice_qt LengthofServiceGroup if ///
LatestStartPolice_qt>timeq &  !missing(Line), missing
// Some few people get ratings despite the fact that their latest start date was later than 
//the rating date. 

 tab StartPolice_qt LengthofServiceGroup if ///
StartPolice_qt>timeq &  !missing(Line), missing
//all missing

tab StartPolice_qt if StartPolice_qt>LatestStartPolice_qt, missing
list StartPolice_qt LatestStartPolice_qt if StartPolice_qt>LatestStartPolice_qt ///
&!missing(StartPolice_qt)
//there are some few contradictions when the latest start date is earlier than the start date

tab LengthofServiceGroup_d if timeq<StartPolice_qt & had_case==1, missing
tab StartPolice_qt  if timeq<StartPolice_qt & had_case==1, missing


// DEALING WITH MISSING IN 'StartPolice_qt'
//--------------------------------------------
// We consider the records of complaints after the
// "start date". 

// We want to control for experience. 
// As a proxy, we will use the groups of "Length of service"
// already defined in the data because they are for the wholse sample
// (although they are fixed values),
// Remember that we constrained the data for timeq>=startdate qt
 

replace StartPolice_qt_approx= LatestStartPolice_qt if missing(StartPolice_qt_approx)
format StartPolice_qt_approx %tq
tab StartPolice_qt_approx timeq if timeq<StartPolice_qt_approx, missing


tab StartPolice_qt_approx timeq if timeq<StartPolice_qt_approx &  ///
!missing(Line), missing
//only 1012 obs but all very close


tab StartPolice_qt_approx timeq if timeq<StartPolice_qt_approx &  had_case_complaint==1, missing
//no obs

//The approximation is sort of fine


gen approx_length_service_years=(timeq-StartPolice_qt_approx)/4 

tab approx_length*
replace approx_length_service=0 if approx_length_service<0


gen approx_ls_0_4=1 if approx_length_service>=0 & approx_length_service <5 
gen approx_ls_5_9=1 if approx_length_service>=5 & approx_length_service <10 
gen approx_ls_10_14=1 if approx_length_service>=10 & approx_length_service <15 
gen approx_ls_15_19=1 if approx_length_service>=15 & approx_length_service <20 
gen approx_ls_20_24=1 if approx_length_service>=20 & approx_length_service <25
gen approx_ls_25_29=1 if approx_length_service>=25 & approx_length_service <30
gen approx_ls_30_34=1 if approx_length_service>=30 & approx_length_service <35 
gen approx_ls_35_39=1 if approx_length_service>=35 & approx_length_service <40 
gen approx_ls_40=1 if approx_length_service>=40 & !missing(approx_length_service)

gen approx_group_ls=1 if approx_ls_0_4==1
replace approx_group_ls=2 if approx_ls_5_9==1
replace approx_group_ls=3 if approx_ls_10_14==1
replace approx_group_ls=4 if approx_ls_15_19==1
replace approx_group_ls=5 if approx_ls_20_24==1
replace approx_group_ls=6 if approx_ls_25_29==1
replace approx_group_ls=7 if approx_ls_30_34==1
replace approx_group_ls=8 if approx_ls_35_39==1
replace approx_group_ls=9 if approx_ls_40==1
drop approx_ls*

label define edad ///
1 "0-4 years" ///
2 "5-9 years" ///
3 "10-14 years" ///
4 "15-19 years" ///
5 "20-24 years" ///
6 "25-29 years" ///
7 "30-34 years" ///
8 "35-39 years" ///
9 "40+ years", replace


label values approx_group_ls edad


 tab approx_group_ls had_case_complain, missing
  tab approx_group_ls LengthofServiceGroup_d, missing

 xtset num_id timeq
 
 
rename alle_type1 had_alle_type1
rename alle_type2 had_alle_type2
rename alle_type3 had_alle_type3
rename alle_type4 had_alle_type4
rename alle_type5 had_alle_type5
rename alle_type6 had_alle_type6
rename has_action1 had_Action_1
rename has_action2 had_Action_2
rename has_action3 had_Action_3


codebook had_peer_action1_M2 ///
had_peer_action2_M2 ///
had_peer_action3_M2 ///
had_peer_action4_M2 ///
had_peer_complaint_M2 ///
had_peer_complaint_M1


tab had_case had_alle_type1, missing


//rantings police
gen rating_4cat_d=rating_5cat_d
replace rating_4cat_d=4 if rating_5cat_d==5

gen rating_4cat_LM_d=rating_5cat_LM_d
replace rating_4cat_LM_d=4 if rating_5cat_LM_d==5 //development required +not yet competent

gen rating_3cat_d=rating_4cat_d
replace rating_3cat_d=2 if rating_4cat_d==1

gen rating_3cat_LM_d=rating_4cat_LM_d
replace rating_3cat_LM_d=2 if rating_4cat_LM_d==1


label list rating_d
label define rating4cat ///
           1 "Exceptional" ///
           2 "Competent (above standard)" ///
           3 "Competent (at required standard)" ///
           4 "Competent (development required) + Not Yet Competent", replace

label define rating3cat ///
           2 "Exceptional + Competent (above standard)" ///
           3 "Competent (at required standard)" ///
           4 "Competent (development required) + Not Yet Competent", replace
		   
label val 	rating_4cat_d* rating_4cat_LM_d* rating4cat	   
label val 	rating_3cat_d* rating_3cat_LM_d* rating3cat	   

tab rating_3cat_d rating_4cat_d
tab rating_3cat_LM_d rating_4cat_LM_d

//ranks police
 tab rank_police_d EmployeeType_wf_3cat_d if subset==1, missing
 //excludes spetial contabulary and civil staff
  
 gen rank_police_ordered_d=1 if rank_police_d==3
 replace rank_police_ordered_d=2 if rank_police_d==5
 replace rank_police_ordered_d=3 if rank_police_d==4
 replace rank_police_ordered_d=4 if rank_police_d==1
 replace rank_police_ordered_d=5 if rank_police_d==6
 replace rank_police_ordered_d=6 if rank_police_d==2
 
label define rank_poli_ordered ///
1 "Police Constable" ///
2 "Police Sergeant" ///
3 "Inspector" ///
4 "Chief Inspector" ///
5 "Superintendent" ///
6 "Chief Superintendent", replace 

label val  rank_police_ordered_d rank_poli_ordered 
 tab rank_police_ordered_d rank_police_d
 
gen rank_police_staff_d=rank_police_ordered_d
replace rank_police_staff_d=4 if rank_police_staff_d==5 |  rank_police_staff_d==6
replace rank_police_staff_d=5 if EmployeeType_wf_3cat_d==3
replace rank_police_staff_d=6 if EmployeeType_wf_3cat_d==1

label define rank_poli_staff ///
1 "Police Constable" ///
2 "Police Sergeant" ///
3 "Inspector" ///
4 "Chief Inspector, Superintendent, Chief Superintendent" /// 
5 "Special Constabulary" ///
6 "Civil Staff", replace 

label values rank_police_staff_d  rank_poli_staff 

tab rank_police_staff_d EmployeeType_wf_3cat_d, missing
tab rank_police_d EmployeeType_wf_3cat_d if subset==1, missing
 
 sort GUID timeq

 save "081018 CC  WW  SS GEO RATING RANK LM Peer common M2.dta", replace


