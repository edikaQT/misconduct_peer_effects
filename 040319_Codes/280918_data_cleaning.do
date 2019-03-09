

/////////////////////////////////////////////////////////////////////////////////////////
//
//                                 DATA CLEANING
//                                 ==============
//
//  --- IMPORTING COMPLAINS //2010q2 to 2015q1
//  --- IMPORTING DEMOGRAPHICS FOR WORKFORCE (2015)
//  --- IMPORTING SICKNESS DATA 
//      (sickness data has information about the ethnicity of the workforce and
//      records of illness of the individuals. It
//      comes from a dataset used in other of our projects. We are using it here only to
//      add information about the ethnicity of the individuals in our final dataset)
//  --- MERGING MISCONDUCT RECORDS, WORKFORCE DEMOGRAPHICS AND SICKNESS RECORDS
//      Creating variable for business group and geographic location
//  --- IMPORTING LINE MANAGERS DATA
//  --- IMPORTING PERFORMANCE REVIEWS (PDRs  with ratings)
//  --- MERGING WW CC SS GEOGRAPHY DATA WITH EMPLOYEE PERFORMANCE DATA
//  --- MERGING WW CC SS GEOGRAPHY PERFORMANCE DATA WITH LINE MANAGER DATA
//  --- ADDING OTHER VARIABLES
//      rating_6cat_d (rating 6 categories)
//      EmployeeType_wf_3cat_d (employee type 3 categories)
//      rank_police_d (rank for police up to Chief Superintendent. Commander, all Commissioner, and special Sergeant omitted)
//      LengthofServiceGroup_d (years of service)
// 
//      We are also adding variables for the performance rating of the staff (and their line managers) and the ranking in the peer group based on this performance
//      However these variables for performance ranking are only created for reference purposes since they do not provide much relevant information
//      because ratings are usually 2 or 3 (in an scale 1-5) and shows little variation among peers.
//      Although the rankings of performance do not provide much relevant information, a non-missing value for the ranking
//      help us to recognise those individuals that have both (1) a line manager in the quarter and (2) a performance score in the quarter

//  --- PREPARING A DATASET THAT WILL BE USED IN R TO IDENTIFY WHO CHANGED PEERS
//=========================================

//========================================
//  IMPORTING COMPLAINTS
//=========================================


clear
set more off

cd "$location_data"
import delimited "CC_STATA.txt", case(preserve) 

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

//Complaints and conduct data details:
//-------------------------------------
//Each 'CaseNumber' can contain multiple allegations counted by 'AllegSeqNumber'.
//Each 'CaseNumber' X 'AllegSeqNumber' can contain multiple officers / staff but mostly just contains one person.
//In these records, there are repetitions of rows. The 'DuplicateCount' indicates the number of times a row is duplicated.

//Extracting the case number from the string variable and verifying it matches the case number from the numeric variable
gen CaseNumber2=substr(CaseNumber,7,10)
destring CaseNumber2, replace

sort CaseNumber2 Order
list if CaseNumber2!=CaseNo //the string and numeric variables are the same

//Note: Allegations are not always sequentially numbered. So not all allegations have a sequence starting from 1
bysort CaseNumber2 (Order): gen case_n=_n //Creating the order of allegation within the case


 list CaseNumber GUID AllegSeqNumber case_n  in 1/40
 list CaseNumber CaseRecorded GUID AllegSeqNumber case_n if case_n!= AllegSeqNumber in 1/40
 list CaseNumber  AllegSeqNumber case_n if CaseNumber=="Case - 15"

   
gen AllegSeqNumber2=AllegSeqNumber

sort CaseNo Order

list CaseNo CountPerCase CountPerPerson CaseRecorded  GUID in 1/20 
//'case record', 'count of cases reported on a given CaseNo' and 'count of cases of a person during the data period"


//Looking at the relation between 'Actions' and 'FormalActionSanctions'
tab FormalAct Action, missing
tab FormalAct Action
//Formal actions involve mostly 'Written Warnings' 


//Verifiying the duplicate counts
bysort CaseNumber CaseRecorded AllegSeqNumber GUID: gen GUID_CR_All_CN=_N
tab GUID_CR_All_CN

tab DuplicateCount GUID_CR_All, missing //they are exactly the same

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

//DATES

//months
gen my1 = date(CaseRecorded, "YMD")
drop CaseRecorded
format my1 %td
rename my1 CaseRecorded
gen month=mofd(CaseRecorded)
format month %tmMonth_CCYY
rename month my
 
//quarters
gen timed = dofm(my) //timed is only a temporal variable because it always start in the first day of each month
gen timeq = qofd(timed)
format timeq %tq
drop timed
tab my timeq
 
tab TypeDescription, gen (TypeDes_) //dummies for the type of misconduct

encode TypeDescription, gen(TypeD_c)
label list TypeD_c


label var TypeDes_1 "Breach Code A PACE"
label var TypeDes_2 "Breach Code B PACE"
label var TypeDes_3 "Breach Code C PACE"
label var TypeDes_4 "Breach Code D PACE"
label var TypeDes_5 "Breach Code E PACE"
label var TypeDes_6 "Corrupt practice"
label var TypeDes_7 "Discriminatory Behaviour"
label var TypeDes_8 "Improper disclosure of information"
label var TypeDes_9 "Incivility, impoliteness and intolerance"
label var TypeDes_10 "Irregularity in evidence/perjury"
label var TypeDes_11 "Lack of fairness and impartiality"
label var TypeDes_12 "Mishandling of property"
label var TypeDes_13 "Multiple or unspecified breaches of PACE"
label var TypeDes_14 "Oppressive conduct or harassment"
label var TypeDes_15 "Other"
label var TypeDes_16 "Other assault"
label var TypeDes_17 "Other irregularity in procedure"
label var TypeDes_18 "Other neglect or failure in duty"
label var TypeDes_19 "Other sexual conduct"
label var TypeDes_20 "Serious non-sexual assault"
label var TypeDes_21 "Sexual assault"
label var TypeDes_22 "Traffic irregularity"
label var TypeDes_23 "Unlawful/unnecessary arrest or detention"

drop TypeD_c

replace Action="Unknown Action" if missing(Action)

tab Action, gen (Action_)
//dummies for the santions
label var Action_1 "Formal Action"
label var Action_2 "Management Action"
label var Action_3 "No Action"
label var Action_4 "Retired/Resigned"
label var Action_5 "UPP"
label var Action_6 "Unknown Action"



bysort GUID timeq CaseNo: gen unique_caseNo=(_n==_N)
tab unique_caseNo, missing //identifies a unique case in quarter for each person

bysort GUID timeq: egen sum_unique_caseNo=sum(unique_caseNo)
tab sum_unique_caseNo //how many 'cases' a person has in a quarter

list GUID timeq CaseNo CaseRecorded  AllegSeqNumber TypeDescription  sum_unique_caseNo unique_caseNo in 1/20
//recall a person can have a case involving many different allegations on the same date

list Dup* GUID timeq CaseNo CaseRecorded  AllegSeqNumber TypeDescription  sum_unique_caseNo unique_caseNo if ///
GUID=="0003066c-1d14-40ea-8bc0-2b0d44059991"

sort CaseNo GUID AllegSeqNumber  
sort CaseNo  AllegSeqNumber  

list Dup* GUID timeq CaseNo CaseRecorded  AllegSeqNumber TypeDescription  sum_unique_caseNo unique_caseNo if ///
 CaseNo==18839  //2267 
//Recall that each 'CaseNumber' X 'AllegSeqNumber' can contain multiple officers / staff but mostly just contains one person.
//Recall 'AllegSeqNumber' within a 'CaseNumber' do not necessarily have the sequence of numbers complete



// We will count the (1) number of allegations per person by quarter,
// (2) the number of cases per person by quarter
// (3) the number of allegations for each type of misconduct
 sort GUID timeq
 collapse (count) AllegSeqNumber (mean) sum_unique_caseNo (sum) ///
TypeDes_1	///
TypeDes_2	///
TypeDes_3	///
TypeDes_4	///
TypeDes_5	///
TypeDes_6	///
TypeDes_7	///
TypeDes_8	///
TypeDes_9	///
TypeDes_10	///
TypeDes_11	///
TypeDes_12	///
TypeDes_13	///
TypeDes_14	///
TypeDes_15	///
TypeDes_16	///
TypeDes_17	///
TypeDes_18	///
TypeDes_19	///
TypeDes_20	///
TypeDes_21	///
TypeDes_22	///
TypeDes_23	///
Action_1	///
Action_2	///
Action_3	///
Action_4	///
Action_5	///
Action_6 ,  by(GUID EmployeeType timeq)


 label var sum_unique "How many CASES a person has in a quarter"
tab sum_unique_caseNo


sort GUID timeq
cd "$location_cleaned_data"

save "210117 CC qt.dta", replace
//The identifiers above are GUID X timeq


//========================================
//  IMPORTING DEMOGRAPHICS FOR WORKFORCE (2015)
//=========================================

cd "$location_data"

clear
import delimited "workforce_STATA.txt", case(preserve) 

//Variable names were imported in the wrong position. We need to move the names one column to the right

rename	GUID	Order
rename	Link	GUID
rename	BusinessGroupLevel2	Link
rename	Level3Organisation	BusinessGroupLevel2
rename	OrganisationLevel4	Level3Organisation
rename	EmployeeType	OrganisationLevel4
rename	NEWEmployeeType	EmployeeType
rename	PersonType	NEWEmployeeType
rename	PositionRankBand	PersonType
rename	RankBandStatus	PositionRankBand
rename	SubstantiveRankBand	RankBandStatus
rename	WDURank	SubstantiveRankBand
rename	WDURank2	WDURank
rename	RankBandSubcode	WDURank2
rename	YearsinCurrentRankBand	RankBandSubcode
rename	Position	YearsinCurrentRankBand
rename	LocalOcu	Position
rename	CentralFunction	LocalOcu
rename	UniformNonUniformIndicator	CentralFunction
rename	FundedNonFunded	UniformNonUniformIndicator
rename	JobRole	FundedNonFunded
rename	PositionId	JobRole
rename	AssignmentCostCentre	PositionId
rename	PositionCostCentre	AssignmentCostCentre
rename	OPMCode	PositionCostCentre
rename	OPMCategory	OPMCode
rename	HMICCode	OPMCategory
rename	HMICGrouping	HMICCode
rename	LocationCode	HMICGrouping
rename	AssignmentStatus	LocationCode
rename	AssignmentCategory	AssignmentStatus
rename	FTE	AssignmentCategory
rename	HeadCount	FTE
rename	WorkingHours	HeadCount
rename	MannerofJoining	WorkingHours
rename	LocationAllowance	MannerofJoining
rename	ShiftDisturbanceAllowance	LocationAllowance
rename	LineManagerGUID	ShiftDisturbanceAllowance
rename	LineManagerRankBand	LineManagerGUID
rename	LineManagerBOCU	LineManagerRankBand
rename	LatestStartDate	LineManagerBOCU
rename	ContractEndDate	LatestStartDate
rename	StartPoliceDate	ContractEndDate
rename	LengthofService	StartPoliceDate
rename	LengthofServiceGroup	LengthofService
rename	Gender	LengthofServiceGroup
rename	Segment	Gender
rename	Service	Segment
rename	SubService	Service
rename	ShoulderNumber	SubService
rename	v51	ShoulderNumber

//Deleting labels
foreach var of varlist _all {
	label var `var' ""
}

//Finding duplicated GUIs
sort GUID
by GUID: gen count_GUID=_N
tab count_GUID, missing
//There are no duplicates


tab AssignmentStatus
// More than 90% are in active assigment
tab EmployeeType NEWEmployeeType, missing
list EmployeeType NEWEmployeeType if EmployeeType!= NEWEmployeeType 
//Both variables generally agree. EmployeeType has more information and distinguishes 'Seconded to MPS (Police)' from 'Police'
tab LengthofService LengthofServiceGroup

gen group=1

cd "$location_cleaned_data"

save "210217 Workforce group.dta", replace


//We have data my.dta that contains a column "my" showing the months of the data
cd "$location_data"

use "my.dta", clear

gen timed = dofm(my) //timed is only a temporal variable because it always start in the first day of each month
gen timeq = qofd(timed)
format timeq %tq
bysort timeq: gen keep=_n==1
keep if keep==1
keep group timeq

sort group
cd "$location_cleaned_data"

joinby group using "210217 Workforce group.dta"

//quarter in which police or staff started working
gen StartPolice_d= date(StartPoliceDate, "DMY")
format StartPolice_d %td
drop StartPoliceDate
gen StartPolice_qt=qofd(StartPolice_d)
format StartPolice_qt %tq
tab StartPolice_qt LengthofServiceGroup, missing

// we keep the records from the starting date or when the date is unknown

keep if StartPolice_qt<=timeq | missing(StartPolice_qt)
rename EmployeeType EmployeeType_wf

sort GUID timeq
merge GUID timeq using "210117 CC qt.dta"

tab _merge timeq
tab _merge
list GUID timeq StartPolice_qt LengthofService LengthofServiceGroup if _merge==2

drop if _merge==2
drop _merge

tab EmployeeType_wf EmployeeType, missing
tab EmployeeType_wf NEW, missing

//CC data has only data for individuals that are Civil and Civil (Police) Police and Special Consta
								  
gen subset_complaints=0
replace subset_complaints=1  if EmployeeType_wf=="Civil Staff" | EmployeeType_wf=="Civil Staff (Police Community Support Officer)" | ///
EmployeeType_wf=="Police" | EmployeeType_wf=="Special Constabulary"

//So we do not use:
//Agency Staff,  Civil Staff (Casual), Contingent Worker, Seconded to MPS (Civil),   Seconded to MPS (Police) and Volunteer

//We will use the variables Employeetype or NewEmploeetype that came from workforce data

// creating a numeric ID for GUID
sort GUID
by GUID : gen first = _n == 1
gen num_id = sum(first)
drop first

unab vlist : num_id timeq
     sort `vlist'
     quietly by `vlist':  gen dup = cond(_N==1,0,_n)
tab dup
// we have checked that there are no duplicated IDs


xtset num_id timeq
tab EmployeeType_wf sum_unique_caseNo, missing

//labelling allegation types
label var TypeDes_1 "Breach Code A PACE"
label var TypeDes_2 "Breach Code B PACE"
label var TypeDes_3 "Breach Code C PACE"
label var TypeDes_4 "Breach Code D PACE"
label var TypeDes_5 "Breach Code E PACE"
label var TypeDes_6 "Corrupt practice"
label var TypeDes_7 "Discriminatory Behaviour"
label var TypeDes_8 "Improper disclosure of information"
label var TypeDes_9 "Incivility, impoliteness and intolerance"
label var TypeDes_10 "Irregularity in evidence/perjury"
label var TypeDes_11 "Lack of fairness and impartiality"
label var TypeDes_12 "Mishandling of property"
label var TypeDes_13 "Multiple or unspecified breaches of PACE"
label var TypeDes_14 "Oppressive conduct or harassment"
label var TypeDes_15 "Other"
label var TypeDes_16 "Other assault"
label var TypeDes_17 "Other irregularity in procedure"
label var TypeDes_18 "Other neglect or failure in duty"
label var TypeDes_19 "Other sexual conduct"
label var TypeDes_20 "Serious non-sexual assault"
label var TypeDes_21 "Sexual assault"
label var TypeDes_22 "Traffic irregularity"
label var TypeDes_23 "Unlawful/unnecessary arrest or detention"

//labelling sanctions
label var Action_1 "Formal Action"
label var Action_2 "Management Action"
label var Action_3 "No Action"
label var Action_4 "Retired/Resigned"
label var Action_5 "UPP"
label var Action_6 "Unknown Action"

sort GUID timeq
cd "$location_cleaned_data"
save "210117 CC  WW qt.dta", replace
	

//=======================================================================
//  IMPORTING SICKNESS DATA 
//  (sickness data has information about the ethnicity of the workforce and
//  records of illness of the individuals. 
//  It comes from a dataset used in other of our projects. We are calling it here to
//  add information about the ethnicity of the individuals in our final dataset)
//=======================================================================

cd "$location_sickness_data"

use "210117 SS.dta", clear

sort GUID timeq

//=======================================================================
//  MERGING MISCONDUCT RECORDS, WORKFORCE DEMOGRAPHICS AND SICKNESS RECORDS
//=======================================================================

cd "$location_cleaned_data"
merge GUID timeq using "210117 CC  WW qt.dta"
save "210117 CC  WW  SSqt.dta", replace

use "210117 CC  WW  SSqt.dta", clear

 tab _merge
 
 codebook GUID if _merge==1 //1141 people for guid x  quarters in data ss
 codebook GUID if _merge==2 //50786 people for guid x quarters in data ww
 codebook GUID if _merge==3 //36061 people for guid x quarters in both
 



//SS DATA HAS REPORTS OF SICKNESS FOR PEOPLE. ON CERTAIN QUARTERS, THESE REPORTS
//OCCURRED BEFORE THE "START WORKING DATE" SHOWED IN WW DATA.
//WE DELETE ALL THESE OBSERVATIONS AND CONSIDER THE OBSERVATIONS FROM 
//THE START WORKING DATE SHOWED IN WW

drop if _merge==1
label var subset_complaints "EmployeeType_wf Civil Staff, Civil Staff (Police Community Support Officer), Police, Special Constabulary"


tab Gender*, missing

//keep Gender from ww data
drop dup Gender_sickness 
label var Gender "gender from ww data"
label var StartPolice_qt "start police quarter from ww"
label var StartPolice_d "start police day from ww"
tab Age_start LengthofServiceGroup, missing
des	
		
tab Ethnicity, missing
//Ethnicity comes from SS data (it has missing values)

bysort GUID Ethnicity: gen a_ethnicity=_n==1
replace a_ethnicity=. if missing(Ethnicity)
capture drop many_ethnicity
bysort GUID: egen many_ethnicity=sum(a_ethnicity)
tab many_ethnicity
gsort GUID Ethnicity
by GUID :  carryforward Ethnicity, replace

gsort GUID -Ethnicity
by GUID :  carryforward Ethnicity, replace

drop many_ethnicity a_ethnicity
list GUID Ethnicity timeq in 1/40
		
			
tab num_reports_sickness, missing
replace num_reports_sickness=0 if 	missing(num_reports_sickness)
tab num_reports_sickness, missing

des nature*, fullnames	//illness types		
drop reason_

replace num_days_lost=0 if missing(num_days_lost) //days lost due to sickness
label var	num_id	"ID no string"
label var	num_reports_sickness	"Number of reports of sickness in a quarter"		

label var num_days_lost "Number of days lost (no original WDL)"
label var EmpTypeSSick_ "Employee type when police started illness for reported illness of the quarter"
tab EmployeeType_wf EmpTypeSSick_, missing //no missing of wf employee type
label define EmployeeType_sick ///
1 "Civil Staff" ///
2 "Civil Staff (Police Community Support Officer)" ///
3 "Police" 
label values EmpTypeSSick_ EmployeeType_sick 
// For our analysis we use the employee type registered in the WW data. Since the employee type from the other datasets 
// lacks records for all the workforce

//===================================================================
// Creating variable for business group and geographic location
//===================================================================

tab Level3Organisation
encode Level3Organisation, gen (n_level3)
encode OrganisationLevel4 , gen (n_level4)
encode BusinessGroupLevel2 , gen (n_level2)	
label var n_level3 "level 3 organization"
label var n_level4 "level 4 organization"
label var n_level2 "level 2 organization"
tab n_level2
		
//level2:		
// 1  Career Transition
// 2  Deputy Commissioners Portfolio
// 3  Directorate of Resources
// 4  Met HQ
// 5  National Functions
// 6  Shared Support Services
// 7  Specialist Crime and Operations
// 8  Specialist Operations
// 9  Territorial Policing (this level is important, and we will look at it in level 3)

//level 3:
//it has 36 categories
//6 categories correspond to TP: 4 boroughs and TP criminal justice, and TP Central (i.e., 9 in level2)

//level 4:
//it has 101 categories
//when level2 is TP (9), it has all TP showing the name of the boroughs (and SIGLAS) and other TP bussiness operations


		
tab n_level3, sort
tab n_level4 if n_level2==9  , sort
tab n_level3 if n_level2==9  , sort

tab n_level4 if n_level3>30
tab n_level2 if n_level3>30
		
// territorial police

tab n_level3 EmployeeType if n_level3>30
tab n_level4 n_level3 if n_level3>30
tab n_level4 n_level3 if n_level2==9 
tab n_level2 n_level3

		
codebook n_level2		


//creating dummies ONLY for territorial police and showing the boroughs

encode OrganisationLevel4 if n_level2==9, gen (level4_territorial_police)
encode Level3Organisation if n_level2==9, gen (level3_territorial_police)

tab level4_territorial_police, missing
tab level4_territorial_police, missing nolabel
		
tab level3_territorial_police, missing
tab level3_territorial_police, missing nolabel

bysort level3_territorial_police: tab level4_territorial_police
bysort level3_territorial_police: tab level4_territorial_police

//we will exclude this when portraying the results in the map. but we will inclyde them in the regression

gen level3_territorial_police_v2=level3_territorial_police
tab level3_territorial_police_v2 
tab level3_territorial_police level4_territorial_police if ///
level4_territorial_police==2 | n_level2==7, missing

tab level3_territorial_police n_level2 , missing
tab  level3_territorial_police
replace level3_territorial_police_v2=7 if level4_territorial_police==2 //we are distinguishing CW - Westminster HQ in a different category

label var level3_territorial_police_v2 "level3, includes territorial police + other bussiness groups, but Westminister is another category"
//In level4_territorial_police, 2 means "CW - Westminster HQ"


tab level3_territorial_police_v2, missing
replace level3_territorial_police_v2=8 if n_level2==7
	  
//In level 2: 
//   TP is 9, 
//   Special  operations is 8
//   Special crime operations is 7
// These 3 categories are the most relevant in number of observations
// I am namining the rest (1 to 6) other business groups in level3_territorial_police_v2
	  
replace level3_territorial_police_v2=9 if n_level2==8
replace level3_territorial_police_v2=10 if n_level2<=6
	  
label define level3_territorial_police ///
           1 "TP - Boroughs East" ///
           2 "TP - Boroughs North" ///
           3 "TP - Boroughs South" ///
           4 "TP - Boroughs West" ///
           5 "TP - Central" ///
           6 "TP - Criminal Justice & Crime" ///
		   7 "TP - Westminster" ///
		   8 "Specialist Crime and Operations" ///
		   9 "Specialist Operations" ///
		   10 "Other Business Group", modify

label values level3_territorial_police_v2 level3_territorial_police
tab level3_territorial_police_v2, missing	  
	  
	  
//level3_territorial_police_v2 has (1) territorial police by area and (2) other medium size groups 

gen level4_territorial_police_v2=level4_territorial_police
tab level4_territorial_police_v2, missing
replace level4_territorial_police_v2=40 if level3_territorial_police_v2==8
replace level4_territorial_police_v2=41 if level3_territorial_police_v2==9
replace level4_territorial_police_v2=42 if level3_territorial_police_v2==10


label define borough_l4 ///
1	"BS - Kensington & Chelsea Borough"	///
2	"CW - Westminster HQ"	///
3	"EK - Camden Borough"	///
4	"FH - Hammersmith & Fulham Borough"	///
5	"GD - Hackney Borough"	///
6	"HT - Tower Hamlets Borough"	///
7	"JC - Waltham Forest Borough"	///
8	"JI - Redbridge Borough"	///
9	"KD - Havering Borough"	///
10	"KF - Newham Borough"	///
11	"KG - Barking & Dagenham Borough"	///
12	"LX - Lambeth Borough"	///
13	"MD - Southwark Borough"	///
14	"Met Detention"	///
15	"Met Prosecutions"	///
16	"NI - Islington Borough"	///
17	"PL - Lewisham Borough"	///
18	"PY - Bromley Borough"	///
19	"QA - Harrow Borough"	///
20	"QK - Brent Borough"	///
21	"RG - Greenwich Borough"	///
22	"RO - Royal Parks OCU"	///
23	"RTPC - Roads and Transport Policing Com"	///
24	"RY - Bexley Borough"	///
25	"SX - Barnet Borough"	///
26	"TP - Capability and Support"	///
27	"TP Crime Recording Investigation Bureau"	///
28	"TPHQ ACPO and Support Command"	///
29	"TW - Richmond upon Thames Borough"	///
30	"TX - Hounslow Borough"	///
31	"VK - Kingston upon Thames Borough"	///
32	"VW - Merton Borough"	///
33	"WW - Wandsworth Borough"	///
34	"XB - Ealing Borough"	///
35	"XH - Hillingdon Borough"	///
36	"YE - Enfield Borough"	///
37	"YR - Haringey Borough"	///
38	"ZD - Croydon Borough"	///
39	"ZT - Sutton Borough"	///
40 "Specialist Crime and Operations" ///
41 "Specialist Operations" ///
42 "Other Business Group", modify
	  
label values level4_territorial_police_v2 borough_l4

tab level4_territorial_police_v2 Gender, missing
label var level4_territorial_police_v2 "territorial policing in level 4 + other groups"
tab level4_territorial_police_v2 EmployeeType_wf, missing


save "210117 CC  WW  SSqt and geography.dta", replace

//=======================================================================
//  IMPORTING LINE MANAGERS DATA
//=======================================================================

cd "$location_performance_data"
clear

import delimited "Loughborough_Line_Managers_ANON_June_2011.csv", varnames(1) case(preserve) 
gen file01_06_2011=1
rename EmployeeType EmployeeTypeJune2011
rename GUIDRefLineManagerEmployeeNumber GUIDRefLineM_June2011
sort GUIDRefEmployeeNo

tempfile june_2011
save `june_2011'

clear
import delimited "Loughborough_Line_Managers_ANON_June_2012.csv", varnames(1) case(preserve) 
gen file01_06_2012=1
rename EmployeeType EmployeeTypeJune2012
rename GUIDRefLineManagerEmployeeNumber GUIDRefLineM_June2012
sort GUIDRefEmployeeNo

tempfile june_2012
save `june_2012'

clear
import delimited "Loughborough_Line_Managers_ANON_June_2013.csv", varnames(1) case(preserve) 
gen file01_06_2013=1
rename EmployeeType EmployeeTypeJune2013
rename GUIDRefLineManagerEmployeeNumber GUIDRefLineM_June2013
sort GUIDRefEmployeeNo

tempfile june_2013
save `june_2013'

clear
import delimited "Loughborough_Line_Managers_ANON_June_2014.csv", varnames(1) case(preserve) 
gen file01_06_2014=1
rename EmployeeType EmployeeTypeJune2014
rename GUIDRefLineManagerEmployeeNumber GUIDRefLineM_June2014
sort GUIDRefEmployeeNo

tempfile june_2014
save `june_2014'

clear
import delimited "Loughborough_Line_Managers_ANON_June_2015.csv", varnames(1) case(preserve) 
gen file01_06_2015=1
rename NEWEmployeeType EmployeeTypeJune2015
rename GUIDRefLineManagerEmployeeNumber GUIDRefLineM_June2015
sort GUIDRefEmployeeNo

tempfile june_2015
save `june_2015'





clear
import delimited "Loughborough_Line_Managers_ANON_December_2011.csv", varnames(1) case(preserve) 
gen file01_12_2011=1
rename EmployeeType EmployeeTypeDecember2011
rename GUIDRefLineManagerEmployeeNumber GUIDRefLineM_December2011
sort GUIDRefEmployeeNo

tempfile december_2011
save `december_2011'



clear
import delimited "Loughborough_Line_Managers_ANON_December_2012.csv", varnames(1) case(preserve) 
gen file01_12_2012=1
rename EmployeeType EmployeeTypeDecember2012
rename GUIDRefLineManagerEmployeeNumber GUIDRefLineM_December2012
sort GUIDRefEmployeeNo

tempfile december_2012
save `december_2012'

clear
import delimited "Loughborough_Line_Managers_ANON_December_2013.csv", varnames(1) case(preserve) 
gen file01_12_2013=1
rename EmployeeType EmployeeTypeDecember2013
rename GUIDRefLineManagerEmployeeNumber GUIDRefLineM_December2013
sort GUIDRefEmployeeNo

tempfile december_2013
save `december_2013'

clear
import delimited "Loughborough_Line_Managers_ANON_December_2014.csv", varnames(1) case(preserve) 
gen file01_12_2014=1
rename EmployeeType EmployeeTypeDecember2014
rename GUIDRefLineManagerEmployeeNumber GUIDRefLineM_December2014
sort GUIDRefEmployeeNo

tempfile december_2014
save `december_2014'


//========================================
// IMPORTING PERFORMANCE REVIEWS (PDRs  with ratings)
//========================================

clear
import delimited "CM_026_Substantive_PDR_extra_2011_12_ANON.csv", varnames(1) case(preserve) 
gen file2011_2012=1
rename	BusinessGroup		BusinessGroup11_12
rename	Organisation		Organisation11_12
rename	Completed		Completed11_12
rename	EmployeeType		EmployeeType11_12
rename	RankBand		RankBand11_12
rename	LocalOCU		LocalOCU11_12
rename	CentralFunction		CentralFunction11_12
rename	PDRYear		PDRYear11_12
rename	OperationalEffectiveness		OperationalEffectiveness11_12
rename OrganisationalInfluence OrganisationalInfluence11_12
rename ResourceManagement ResourceManagement11_12
rename	OverallRating		OverallRating11_12
rename	LinemanagerGUIDRef		LinemanagerGUIDRef11_12
*GUIDref
sort GUIDref

tempfile year_11_12
save `year_11_12'

clear
import delimited "CM_026_Substantive_PDR_extra_2012_13_ANON.csv", varnames(1) case(preserve) 
gen file2012_2013=1
rename	BusinessGroup		BusinessGroup12_13
rename	Organisation		Organisation12_13
rename	Completed		Completed12_13
rename	EmployeeType		EmployeeType12_13
rename	RankBand		RankBand12_13
rename	LocalOCU		LocalOCU12_13
rename	CentralFunction		CentralFunction12_13
rename	PDRYear		PDRYear12_13
rename	OperationalEffectiveness		OperationalEffectiveness12_13
rename OrganisationalInfluence OrganisationalInfluence12_13
rename ResourceManagement ResourceManagement12_13
rename	OverallRating		OverallRating12_13		
rename	LinemanagerGUIDRef		LinemanagerGUIDRef12_13
*GUIDref
sort GUIDref

tempfile year_12_13
save `year_12_13'


clear
import delimited "CM_026_Substantive_PDR_extra_2013_14_ANON.csv", varnames(1) case(preserve) 
gen file2013_2014=1
rename	BusinessGroup		BusinessGroup13_14
rename	Organisation		Organisation13_14
rename	Completed		Completed13_14
rename	EmployeeType		EmployeeType13_14
rename	RankBand		RankBand13_14
rename	LocalOCU		LocalOCU13_14
rename	CentralFunction		CentralFunction13_14
rename	PDRYear		PDRYear13_14
rename	OperationalEffectiveness		OperationalEffectiveness13_14
rename OrganisationalInfluence OrganisationalInfluence13_14
rename ResourceManagement ResourceManagement13_14
rename	OverallRating		OverallRating13_14		
rename	LinemanagerGUIDRef		LinemanagerGUIDRef13_14
*GUIDref
sort GUIDref

tempfile year_13_14
save `year_13_14'

clear
import delimited "CM_026_Substantive_PDR_extra_2014_15_ANON.csv", varnames(1) case(preserve) 
gen file2014_2015=1
rename	BusinessGroup		BusinessGroup14_15
rename	Organisation		Organisation14_15
rename	Completed		Completed14_15
rename	EmployeeType		EmployeeType14_15
rename	RankBand		RankBand14_15
rename	LocalOCU		LocalOCU14_15
rename	CentralFunction		CentralFunction14_15
rename	PDRYear		PDRYear14_15
rename	OperationalEffectiveness		OperationalEffectiveness14_15
rename OrganisationalInfluence OrganisationalInfluence14_15
rename ResourceManagement ResourceManagement14_15
rename	OverallRating		OverallRating14_15		
rename	LinemanagerGUIDRef		LinemanagerGUIDRef14_15
*GUIDref
sort GUIDref

tempfile year_14_15
save `year_14_15'



merge GUIDref using `year_13_14'
rename _merge merge14_15to13_14
sort GUIDref
merge GUIDref using `year_12_13'
rename _merge merge14_15to13_14to12_13
sort GUIDref
merge GUIDref using `year_11_12'
rename _merge merge14_15to13_14to12_13to11_12

tempfile year_11_to_15
save `year_11_to_15'



//MERGING

use `year_11_to_15', clear

rename GUIDref GUIDRefEmployeeNo
sort GUIDRefEmployeeNo

merge GUIDRefEmployeeNo using `december_2011'
drop _merge
sort GUIDRefEmployeeNo

merge GUIDRefEmployeeNo using `december_2012'
drop _merge
sort GUIDRefEmployeeNo

merge GUIDRefEmployeeNo using `december_2013'
drop _merge

sort GUIDRefEmployeeNo

merge GUIDRefEmployeeNo using `december_2014'
drop _merge

sort GUIDRefEmployeeNo

merge GUIDRefEmployeeNo using `june_2011'
drop _merge
sort GUIDRefEmployeeNo

merge GUIDRefEmployeeNo using  `june_2012'
drop _merge
sort GUIDRefEmployeeNo

merge GUIDRefEmployeeNo using `june_2013'
drop _merge
sort GUIDRefEmployeeNo

merge GUIDRefEmployeeNo using `june_2014'
drop _merge
sort GUIDRefEmployeeNo

merge GUIDRefEmployeeNo using `june_2015'
drop _merge

tempfile all_2011_2015_june_december
save `all_2011_2015_june_december', replace

drop EmployeeNo LineManagerEmployeeNumber v4 v5

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/// WE USE ONLY THE SCORES FROM THE PERFORMANCE DATA("...Substantive_PDR_201X_1X_ANON..." files). 
/// WE DO NOT USE THE LINE MANAGERS LISTED IN THE PERFORMANCE FILES BECAUSE
/// THOSE LINE MANAGERS ARE THE CURRENT LINE MANAGERS AND THEY ARE NOT THE LINEMANAGERS BY THE TIME OF THE
/// PERFORMANCE REVIEWS. THE METROPOLITAN POLICE (MET) POLICE HAS CLARIFIED THIS POINT AFTER WE SAW SOME INCONSISTENCIES IN THE DATA
///
/// WE USE THE LINEMANAGERS FROM THE "...Line_Managers_ANON(june/december)..." FILES, AS SUGGESTED BY THE MET.
///--------------------------------------------------------------------------------------------------------------
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////// 
set more off
des *GUID*, fullnames
///Only the line managers files from June or December datasets are accurate. The other inaccurate records of line managers will be deleted
///(wrong LM: e.g., LinemanagerGUIDRef14_15)

keep EmployeeType* OperationalEffectiveness* OrganisationalInfluence* ResourceManagement* OverallRating* GUIDRefE*
sort GUIDRefEmployeeNo
by GUIDRefEmployeeNo: gen contar=_n
tab contar


list GUIDRefEmployeeNo if contar==2
///dropping dupplicated observations
drop if contar==2

drop EmployeeTypeDecember2011 EmployeeTypeDecember2012 EmployeeTypeDecember2013 EmployeeTypeDecember2014 EmployeeTypeJune2011 EmployeeTypeJune2012 EmployeeTypeJune2013 EmployeeTypeJune2014 EmployeeTypeJune2015

///creating annual ratings dataset
reshape long ///
EmployeeType ///
OperationalEffectiveness ///
OrganisationalInfluence ///
ResourceManagement ///
OverallRating, i(GUIDRefEmployeeNo) j(year_range, string)

rename EmployeeType EmployeeType_new_data
label var EmployeeType_new_data "Employee type from anual PDRs"
replace year_range="2011" if year_range=="11_12"
replace year_range="2012" if year_range=="12_13"
replace year_range="2013" if year_range=="13_14"
replace year_range="2014" if year_range=="14_15"

rename GUIDRefEmployeeNo GUID
sort GUID
destring year_range, replace
format year_range %ty
sort GUID year_range

set more off
tempfile rating_by_year
save `rating_by_year'



///=================================================================
///  MERGING WW CC SS GEOGRAPHY DATA WITH EMPLOYEE PERFORMANCE DATA
///=================================================================


cd "$location_cleaned_data"

use "210117 CC  WW  SSqt and geography.dta", clear

tab  timeq if timeq>=205 & timeq<=208 //from 2011q2
gen year_range="2011" if timeq>=205 & timeq<=208
replace year_range="2012" if timeq>=209 & timeq<=212
replace year_range="2013" if timeq>=213 & timeq<=216
replace year_range="2014" if timeq>=217 & timeq<=220
replace year_range="2010" if timeq>=201 & timeq<=204

destring year_range, replace
format year_range %ty
sort GUID year_range


// MET informed that the records of ratings correspond to period march to march
// We are merging the data considering that the records correspond to q2 q3 q4 and q1 next year


tab timeq year_range, missing

tab _merge
drop _merge
sort GUID year_range timeq
merge GUID year_range using ///
`rating_by_year'

tab  timeq _merge, missing

tab year_range if _merge==2


// Example of a person who did not match (_merge==2). Records unmatched were those years before the 'start date' of work
// for consistency, we eliminate those observations
list GUID timeq StartPolice_qt _merge year* if GUID=="42aee098-8de4-4175-92c9-69fad3e34e7a"

keep if _merge==3


tab EmployeeType_wf  EmpTypeSSick_  if subset==1, missing
tab EmployeeType_wf  EmpTypeSSick_  , missing


encode OverallRating, gen(rating_d)

codebook rating_d

//  Label
//         1  1 - Exceptional
//         2  2 - Competent (above standard)
//         3  3 - Competent (at required standard)
//         4  4 - Competent (development  required)
//         5  5 - Not Yet Competent
//         6  Not Applicable
        .  

save "210117 CC  WW  SS GEO RATING.dta", replace


//===========================================================================
//  MERGING WW CC SS GEOGRAPHY PERFORMANCE DATA WITH LINE MANAGER DATA
//===========================================================================
use `all_2011_2015_june_december', clear //line manager data and performance data. We retain the line manager data


keep GUI*
sort GUIDRefEmployeeNo
by GUIDRefEmployeeNo: gen contar=_n
tab contar
drop if contar==2 //dropping dupplicates

reshape long GUIDRefLineM_, i(GUIDRefEmployeeNo) j(MonthYear_range, string)
drop contar
gen timeh=""
replace timeh="2011h2" if MonthYear_range=="December2011"
replace timeh="2012h2" if MonthYear_range=="December2012"
replace timeh="2013h2" if MonthYear_range=="December2013"
replace timeh="2014h2" if MonthYear_range=="December2014"
replace timeh="2011h1" if MonthYear_range=="June2011"
replace timeh="2012h1" if MonthYear_range=="June2012"
replace timeh="2013h1" if MonthYear_range=="June2013"
replace timeh="2014h1" if MonthYear_range=="June2014"
replace timeh="2015h1" if MonthYear_range=="June2015"

gen timeh2=halfyearly(timeh, "YH")
format timeh2 %th
drop timeh
rename timeh2 timeh

tab MonthYear_range timeh
rename GUIDRefEmployeeNo GUID

sort GUID timeh

tempfile all_2011_2015_june_december_v2
save `all_2011_2015_june_december_v2'


cd "$location_cleaned_data"

use "210117 CC  WW  SS GEO RATING.dta", clear
tab timeq, missing
list GUID LineM* in 1/30 
drop LineM* 
// We drop the line managers that come from the WW data (2015). 
// We instead use the line managers data from 'all_2011_2015_june_december_v2' that registers the changes in line managers

// time variable (semestral)

gen date=dofq(timeq)
gen timeh=hofd(date)
format timeh %th
drop date 
tab timeq timeh, missing

sort GUID timeh
tab _merge
drop _merge
merge GUID timeh using `all_2011_2015_june_december_v2'

tab timeq _merge , missing
tab timeh _merge, missing


tab StartPolice_d timeh if GUID=="00019ed6-4ed3-485f-afb1-be18c270efd3", missing
//merge=2 are the values that are not part of ww data after having deleted obs that were before the start working date

keep if _merge==3
des GUID*, fullnames

rename GUIDRefLineM_ LinemanagerGUIDRef_right 
label var LinemanagerGUIDRef_right "LM from semestrat records"
replace LinemanagerGUIDRef_right="" if LinemanagerGUIDRef_right=="#N/A"






///===============================================================
/// ADDING OTHER VARIABLES
///   rating_6cat_d (rating 6 categories)
///   EmployeeType_wf_3cat_d (employee type 3 categories)
///   rank_police_d (rank for police up to Chief Superintendent. Commander, all Commissioner, and special Sergeant omitted)
///   LengthofServiceGroup_d (years of service)

///   We are also adding variables for the performance rating of the staff (and their line managers) and the ranking in the peer group based on this performance
///   However these variables for performance ranking are only created for reference purposes since they do not provide much relevant information
///   because ratings are usually 2 or 3 (in an scale 1-5) and shows litle variation among peers.
///   Although the rankings of performance do not provide much relevant information, a non-missing value for the ranking
///   help us to recognise those individuals that have (1) a line manager in the quarter and (2) a performance score in the quarter

///===============================================================

drop contar
des rating, full

/// dropping unnecesary information about sickness records

drop nature* hard* Pregnacy* LongTerm 	num_reports_sickness num_days_lost	 


/// dropping other variables that are not part of our analysis
/// (many of these variables have either redundant static information, or many missing values or 
/// the MET has not clarify their interpretation)

drop Link LocalOcu CentralFunction Uniform* PersonType	RankBandStatus	///
SubstantiveRankBand	WDURank	WDURank2	///
RankBandSubcode	YearsinCurrentRankBand	Position	LocalOcu	CentralFunction	///
UniformNonUniformIndicator	FundedNonFunded	JobRole	PositionId	AssignmentCostCentre ///	
PositionCostCentre	OPMCode	OPMCategory	HMICCode	HMICGrouping	LocationCode	///
AssignmentStatus	AssignmentCategory	FTE	HeadCount	WorkingHours	///
MannerofJoining	LocationAllowance	ShiftDisturbanceAllowance	 Contract* ///
Segment	Service	SubService	ShoulderNumber
drop NEWEmployeeType




rename rating_d rating_6cat_d

/// Creating variable employee type (Employee type for subset civil staff, police, special constabulary)
/// Recall we restrict our data to those employee types for which we have records of misconducts  (i.e.,subset=1)
label var EmployeeType "Employee type from complaints CC data"

gen EmployeeType_wf_3cat=EmployeeType_wf if subset==1
replace EmployeeType_wf_3cat ="Civil Staff" if EmployeeType_wf=="Civil Staff (Police Community Support Officer)"
tab EmployeeType_wf_3cat subset, missing

encode EmployeeType_wf_3cat if subset==1, gen(EmployeeType_wf_3cat_d)

label var EmployeeType_wf_3cat "Employee type for subset civil staff, police, special constabulary"
label var EmployeeType_wf_3cat_d "Employee type for subset civil staff, police, special constabulary"


/// Creating variable for the rank band in 'rank_police', only for police and no for civil staff
/// (civil staff has few variation in ranks, most are in Band E)

gen RankBand_police=PositionRankBand
replace RankBand_police="" if EmployeeType_wf_3cat!="Police"
tab RankBand_police EmployeeType_wf_3cat, missing
tab PositionRankBand EmployeeType_wf_3cat, missing


rename RankBand_police rank_police

tab rank_police, sort
replace rank_police="Chief Inspector" if rank_police=="Detective Chief Inspector"
replace rank_police="Chief Superintendent" if rank_police=="Detective Chief Superintendent"
replace rank_police="Police Constable" if rank_police=="Detective Constable" 
replace rank_police="Inspector" if rank_police=="Detective Inspector" 
replace rank_police="Police Sergeant" if rank_police=="Detective Sergeant"
replace rank_police="Superintendent" if rank_police=="Detective Superintendent"
replace rank_police="Constable" if rank_police=="Police Constable" 
replace rank_police="Sergeant" if rank_police=="Police Sergeant"
replace rank_police="" if rank_police=="Band C"
replace rank_police="" if rank_police=="Band E"
replace rank_police="" if rank_police=="Commander" 
replace rank_police="" if rank_police=="Deputy Assistant Commissioner" 
replace rank_police="" if rank_police=="Assistant Commissioner"
replace rank_police="" if rank_police=="Commissioner"
replace rank_police="" if rank_police=="Deputy Commissioner"
replace rank_police="" if rank_police=="Special Sergeant"

label var rank_police "rank police up to Chief Superintendent. Commander, all Commisioner, and special Sergeant omitted"

encode rank_police, gen(rank_police_d)
label var rank_police_d "rank police up to Chief Superintendent. Commander, all Commisioner, and special Sergeant omitted"


/// Creating a numeric variable for length of service

tab LengthofServiceGroup, missing
gen LengthofServiceGroup_d=.
replace LengthofServiceGroup_d=1 if LengthofServiceGroup=="0-4"
replace LengthofServiceGroup_d=2 if LengthofServiceGroup=="5-9"
replace LengthofServiceGroup_d=3 if LengthofServiceGroup=="10-14"
replace LengthofServiceGroup_d=4 if LengthofServiceGroup=="15-19"
replace LengthofServiceGroup_d=5 if LengthofServiceGroup=="20-24"
replace LengthofServiceGroup_d=6 if LengthofServiceGroup=="25-29"
replace LengthofServiceGroup_d=7 if LengthofServiceGroup=="30-34"
replace LengthofServiceGroup_d=8 if LengthofServiceGroup=="35-39"
replace LengthofServiceGroup_d=9 if LengthofServiceGroup=="40+"
tab LengthofServiceGroup_d, missing


label define length 1 "0-4" ///
2 "5-9" ///
3 "10-14" ///
4 "15-19" ///
5 "20-24" ///
6 "25-29" ///
7 "30-34" ///
8 "35-39" ///
9 "40+"

label values LengthofServiceGroup_d length

des rating*
gen rating_5cat_d=rating_6 //category 6 is 'Not Applicable', so we exclude it 
replace rating_5=. if rating_6==6
tab rating_5, missing

tab _merge
drop _merge



bysort LinemanagerGUIDRef_right timeq : egen rank_performance_ties = rank(rating_5)
//The lowest value is ranked 1. By default, equal observations are assigned the average rank.

gen mis=missing(LinemanagerGUIDRef_right)
replace rank_performance=. if mis==1
tab rating_5 mis, missing
tab rank_performance rating_5 , missing

hist rating_5
hist rank_performance 


/// The performance rating of the staff is usually 2 or 3 (in a 1-5 scale). Since it shows little variation between peers
/// the rankings of performance will not provide much relevant information. But a non-missing value for the ranking
/// help us to recognise those individuals that (1) have a line manager in the quarter and (2) have a performance score in the quarter

/// Creating a variable describing the presence or absence of either line managers or rating

gen description_rank="Known rank" if missing(rank_performance)!=1
replace descrip="Unknown rank: No line manager" if mis==1
replace descrip="Unknown rank: No rating 1-5" if missing(rating_5)
replace descrip="Unknown rank: No line manager and no rating 1-5" if missing(rating_5) & mis==1
tab descrip, missing

tab des rating_5, missing
tab rank_per des, missing
drop mis

/// Counting the number of people that have a rank and share the same line manager by quarter (excluding missing)
bysort LinemanagerGUIDRef_right timeq: egen num_people_quarter_same_manager=count(rank_performance)


replace num_people_quarter_same_manager=. if missing(LinemanagerGUIDRef_right)
tab num_people_quarter_same_manager, missing
tab num_people_quarter_same_manager des, missing

tab num_people_quarter_same_manager descrip, missing

/// Flagging individuals who have a rating but have no peers with ratings

sort LinemanagerGUIDRef_right timeq
gen only_one_guy=0 if !missing(num_people_quarter_same_manager)
replace only_one_guy=1 if num_people_quarter_same_manager==1
tab only_one_guy, missing
tab  descript only_one_guy , missing
	
label var only_one_guy "There is only one individual with rating in the group and so there is only one rank in group"


/// Creating a variable 'pcrank' showing the percentile rank, % of peers that are better. Omitted when there are no peers
	
tab descrip
replace descrip="Unknown rank: Is the only individual under LM with rating" if only_one==1 & descrip=="Known rank"
replace descrip="Unknown rank: Individual has no rating but there is only one other peer under LM that has a rating" if only_one==1 & descript=="Unknown rank: No rating 1-5"
replace rank_perfo=. if descript!="Known rank"
label var rank_perform "Ranking of ratings for all, except THOSE WITHOUT PEERS"
tab rank_performance only_one_guy, missing


tab rank_performance_ties num_people_quarter_same_manager, missing 
gen pcrank = (rank_performance_ties - 1) / (num_people_quarter_same_manager - 1)

tab pcrank only_one_guy 
tab pcrank des, missing

label var pcrank "Percentile rank, % of peers that are better. Ommited when there are no peers"
label var num_people_quarter_same_manager "number of people in group but only for those with rank"

hist pcrank // as expected, there is not much variation in the percentile rank due to the lack of variation in the ratings of performance

gen pcrank_0_to_25=0 if pcrank>.25 & missing(pcrank)!=1
replace pcrank_0_to_25=1 if pcrank<=.25
tab pcrank pcrank_0_to_25, missing

gen pcrank_25_to_50=0 if  missing(pcrank)!=1
replace pcrank_25_to_50=1 if pcrank>.25 & pcrank<=.50 
tab pcrank_25_to_50, missing

gen pcrank_50_to_75=0 if  missing(pcrank)!=1
replace pcrank_50_to_75=1 if pcrank>.50 & pcrank<=.75
tab pcrank_50_to_75, missing

gen pcrank_75_to_100=0 if  missing(pcrank)!=1
replace pcrank_75_to_100=1 if pcrank>.75 & pcrank<=1 
tab pcrank_75_to_100, missing

gen p_rank_all=.
replace p_rank_all=1 if pcrank_0_to_25==1
replace p_rank_all=2 if pcrank_25_to_50==1
replace p_rank_all=3 if pcrank_50_to_75==1
replace p_rank_all=4 if pcrank_75_to_100==1

tab pcrank p_rank_all, missing

label define ranks_performance 1 "rank 0% to 25%" ///
2 "rank 25% to 50%" ///
3 "rank 50% to 75%" ///
4 "rank 75% to 100%" ///
, replace

label values p_rank_all ranks_performance
label var p_rank_all "Percentile rank categories, % of peers that are better. Ommited when there are no peers" // SPELLING: Omitted -> Omitted


/// Creating the average peer rating

bysort LinemanagerGUIDRef_right timeq: egen sum_rating=sum(rating_5)
replace sum_rating=. if missing(pcrank)
tab sum_ra des, missing


by LinemanagerGUIDRef_right timeq:egen count_rating=count(rating_5)
replace count_rating=. if missing(sum_ra)

tab count_rating, missing


gen sum_rating_minus_self_rating=sum_rating-rating_5
replace sum_rating_minus_self_rating=. if missing(pcrank)


gen  mean_rating_minus_self_rating=sum_rating_minus_self_rating/(count_rating-1)

tab mean_rating_minus_self_rating only_one_guy, missing

drop count_rating sum_rating
drop sum_rating_minus_self_rating
drop count

cd "$location_cleaned_data"

save "210117 CC  WW  SS GEO RATING RANK.dta", replace

///
/// ADDING LINE MANAGERS PERFORMANCE RATINGS
///

use "210117 CC  WW  SS GEO RATING RANK.dta", clear

keep LinemanagerGUIDRef_right timeq GUID ///
only_one_guy ///
rank* ///
OperationalEffectiveness ///
OrganisationalInfluence ResourceManagement ///
OverallRating rating_5 p_rank_all

gen GUID_LM=GUID ///potential LINE MANAGER

sort GUID_LM timeq

tempfile 270117_GUID_LM
save `270117_GUID_LM', replace

use "210117 CC  WW  SS GEO RATING RANK.dta", clear
keep LinemanagerGUIDRef_right timeq 
rename LinemanagerGUIDRef_right GUID_LM

sort GUID_LM timeq

drop if missing(GUID_LM)
by GUID_LM timeq: gen dup=_n
tab dup
by GUID_LM timeq: gen number_emplyees_under_control=_N

drop if  dup!= number_emplyees_under_control //we retain one obs per lm quarter

drop dup

merge GUID_LM timeq using ///
`270117_GUID_LM'

tab _merge


/// merge==2 are people who ARE NOT LINE MANAGERS
/// merge==1 are people who are line managers but have no ratings 


drop if _merge==1
drop if _merge==2

drop _merge

rename number_emplyees_under_control num_empl_under_control_of_LM

drop GUID  LinemanagerGUIDRef

rename OperationalEffectiveness OperationalEffectiveness_LM
rename OrganisationalInfluence OrganisationalInfluence_LM
rename ResourceManagement ResourceManagement_LM
rename OverallRating OverallRating_LM
rename rating_5 rating_5cat_LM_d
rename only_one_guy only_one_guyLM
rename rank_performance_ties rank_performance_tiesLM
rename GUID_LM LinemanagerGUIDRef_right

drop rank_polic*
rename p_rank_al p_rank_all_LM

sort LinemanagerGUIDRef_right timeq

tempfile 270117_ratings_of_line_managers
save `270117_ratings_of_line_managers', replace


use "210117 CC  WW  SS GEO RATING RANK.dta", clear

sort LinemanagerGUIDRef_right timeq
merge m:1 LinemanagerGUIDRef_right timeq using ///
 `270117_ratings_of_line_managers'

///merge==1 means that the individual quarter is ONLY in the '210117 CC  WW  SS GEO RATING RANK' data, 
///These observations are because there are missing line managers in that data,
///however, there are no missing values in the '270117_ratings_of_line_managers' data.	

gen there_is_LM=1 if !missing(LinemanagerGUIDRef_right)
tab there_is_LM _merge, missing
tab timeq _merge if there_is_LM==1


drop _merge there_is_LM

sort GUID timeq
save "210117 CC  WW  SS GEO RATING RANK LM.dta", replace

///====================================================
/// PREPARING A DATASET THAT WILL BE USED IN R TO IDENTIFY WHO CHANGED PEERS?
///====================================================

use "210117 CC  WW  SS GEO RATING RANK LM.dta", clear

tab EmployeeType_wf if !missing(Line)
tab EmployeeType_wf if missing(Line)
tab EmployeeType_wf subset, missing

sort Line timeq
list Line GUID timeq EmployeeType_wf if !missing(Line) & missing(EmployeeType_wf_3cat) in 500000/600500
tab p_rank_all_LM  EmployeeType_wf if subset==0

// NOTE THAT WE WILL COMPUTE PERS CHANGES FOR THE WHOLE SAMPLE, NOT ONLY FOR THE SUBSET==1 THAT CONSIDERS THE
// SUBSET OF EMPLOYEE TYPES FOR WHOM WE HAVE RECORDS OF MISCONDUCT


keep GUID LinemanagerGUIDRef_right  timeq
encode GUID, gen(GUID_number)
encode LinemanagerGUIDRef_right, gen (LinemanagerGUIDRef_right_number)

generate timeq_text = string(timeq, "%tq")
sort GUID timeq

cd "$location_cleaned_data"

saveold "270117 Data for R to see impact of changes in peers and LM.dta", version(12) replace
