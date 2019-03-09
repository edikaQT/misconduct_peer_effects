
//______________________________________________________________
//
//                  DESCRIPTIVE STATISTICS 
//______________________________________________________________


//________________________________________________________________
//
// DESCRIPTION OF DATA (AFTER MERGING DATASETS)
//________________________________________________________________


// COMPLAINTS data  //2010q2 to 2015q1

clear
set more off

cd "$location_data"
import delimited "CC_STATA.txt", case(preserve) clear

describe, fullnames

// Variable names were imported in the wrong position. We need to move the names one column to the right

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


//Verifying the duplicate counts
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
gen timed = dofm(my) //timed is only a temporal variable because it always staaart in the first day of each month
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
tab unique_caseNo, missing //indentifies a unique case in quarter for each person

bysort GUID timeq: egen sum_unique_caseNo=sum(unique_caseNo)
tab sum_unique_caseNo //how many cases a person has in a quarter

bysort GUID CaseNo: gen DATA_unique_caseNo=(_n==_N)
tab DATA_unique_caseNo, missing //indentifies a unique case  for each person

bysort GUID: egen DATA_sum_unique_caseNo=sum(DATA_unique_caseNo)
tab DATA_sum_unique_caseNo //how many cases a person has 



sort CaseNo GUID AllegSeqNumber  
sort CaseNo  AllegSeqNumber  

list Dup* GUID timeq CaseNo CaseRecorded  AllegSeqNumber TypeDescription  sum_unique_caseNo unique_caseNo if ///
 CaseNo==18839   
//Recall that each 'CaseNumber' X 'AllegSeqNumber' can contain multiple officers / staff but mostly just contains one person.
//Recall 'AllegSeqNumber' within a 'CaseNumber' do not necessarily have the sequence of numbers complete


//   Types of misconduct
//-----------------------------

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
  
  
  gen all_alle_type="Failures in duty" if alle_type1==1
  replace all_alle= "Malpractice" if alle_type2==1
  replace all_alle=  "Discriminatory behaviour" if alle_type3==1
 replace all_alle=  "Opressive_behaviour" if alle_type4==1
 replace all_alle=  "Incivility" if alle_type5==1
  replace all_alle=  "Other allegations (including trafic allegations" if alle_type6==1

    gen xall_alle=1 if alle_type1==1
  replace xall_alle= 2 if alle_type2==1
  replace xall_alle= 3 if alle_type3==1
 replace xall_alle= 4 if alle_type4==1
 replace xall_alle=  5 if alle_type5==1
  replace xall_alle= 6 if alle_type6==1
 label define j_type ///
  1 "Failures in duty" ///
  2  "Malpractice" ///
 3  "Discriminatory behaviour" ///
  4 "Opressive_behaviour" ///
 5 "Incivility" ///
 6 "Other allegations (including trafic allegations", replace
 label values xall j_type

  bysort EmployeeType: tab  xall_alle Action if Action!="Unknown Action", row
tab  Resul Action if Action!="Unknown Action", col


	
	
sort GUID timeq

cd "$location_cleaned_data"
merge GUID using GUID_used_in_RE

keep if _merge==3
tab timeq 
  codebook GUID 

capture drop year
gen year=year(dofq(timeq))

tab timeq year
drop if year==2010 | year==2015
	

	
	
	
//___________________________________________________________________________________________________________________
//	
//Table 1. The Distribution of Allegations Against Civil Staff and Police Officers by Disciplinary Outcome
//___________________________________________________________________________________________________________________
	
bysort EmployeeType: tab  xall_alle Action if Action!="Unknown Action" ///
	, row

codebook GUID

tab Action Result, row

	
// Counting people

tab timeq 
  codebook GUID 

capture drop year
gen year=year(dofq(timeq))

tab timeq year
drop if year==2010 | year==2015

  codebook GUID if Action!="Unknown Action" & ///
  EmployeeType=="Civil Staff"
  
    codebook GUID if Action!="Unknown Action" & ///
  EmployeeType=="Police"
  
    codebook GUID if ///Action!="Unknown Action" & ///
  EmployeeType=="Civil Staff"
  
    codebook GUID if ///Action!="Unknown Action" & ///
  EmployeeType=="Police"


//Allegations recorder against 1,994 civil Staff and 12,921 police officer over the period 2011 to 2014.  

capture drop _merge

sort GUID
cd "$location_cleaned_data"
merge GUID using GUID_used_in_RE

capture codebook GUID if _merge==1
codebook GUID if _merge==3 | _merge==1
codebook GUID if _merge==3 | _merge==2 //35924
codebook GUID if _merge==3

//Of the sample of 35,924 officers and staff, 14,915 had reports of complaints during the
//2011-2014. 


keep if _merge==3
  
 sort GUID timeq
 collapse (count) AllegSeqNumber ///
 (mean) DATA_sum_unique_caseNo ///
 (sum) ///
alle_type* ///
Action_1	///
Action_2	///
Action_3	///
Action_4	///
Action_5	///
Action_6 ,  by(GUID EmployeeType)

  
 label var alle_type1  "Failures in duty" 
 label var alle_type2  "Malpractice" 
 label var alle_type3  "Discriminatory behaviour" 
 label var alle_type4 "Opressive behaviour" 
 label var alle_type5 "Incivility" 
 label var alle_type6 "Other"
 
//_______________________________________________________________________
// 
// Supplementary Table 1. Correlation of Allegations Within Individuals 
//_______________________________________________________________________

pwcorr alle_type1	alle_type2	alle_type3	alle_type4	///
alle_type5	alle_type6, sig

cd "$location_cleaned_data"

ssc install dataex

eststo clear
estpost correlate alle_type1	alle_type2	alle_type3	alle_type4	///
alle_type5	alle_type6,  matrix
eststo corrtr
esttab using "table_corr.rtf", replace  p  b(3)   noobs nonum unstack  ///
label
eststo clear

 ci2 alle_type1	alle_type2 , corr
 ci2 alle_type1	alle_type3 , corr 
 ci2 alle_type1	alle_type4 , corr
 ci2 alle_type1	alle_type5 , corr
 ci2 alle_type1	alle_type6 , corr
 ci2 alle_type2	alle_type3 , corr
 ci2 alle_type2	alle_type4 , corr
 ci2 alle_type2	alle_type5 , corr
 ci2 alle_type2	alle_type6 , corr
 ci2 alle_type3	alle_type4 , corr
 ci2 alle_type3	alle_type5 , corr
 ci2 alle_type3	alle_type6 , corr
 ci2 alle_type4	alle_type5 , corr
 ci2 alle_type4	alle_type6 , corr
 ci2 alle_type5	alle_type6 , corr
	   
	   
	   
 reshape long alle_type, i( GUID EmployeeType ) j(j)
 des
 label define j_type ///
  1 "Failures in duty" ///
  2  "Malpractice" ///
 3  "Discriminatory behaviour" ///
  4 "Opressive behaviour" ///
 5 "Incivility" ///
 6 "Other allegations (including trafic allegations", replace
 label values j j_type

  
  drop if alle_type==0
  replace alle_type=11 if alle_type>11
  
  
  codebook GUID //14915
  codebook GUID if Alleg<=2
  display 8021/14915 //.53
 //Of the sample of 35,924 officers and staff, 14,915 had reports of complaints during the
//2011-2014. 
 ///Most of them (54%) received only 2 or fewer complaints in this four-year interval (see Supplementary Figure 1).   
 
 tab j


//                                      j |      Freq. 
//----------------------------------------+------------
//                       Failures in duty |     12,442 
//                            Malpractice |      2,864 
//               Discriminatory behaviour |      2,956 
//                    Opressive behaviour |      2,859
//                             Incivility |      4,997
//Other allegations (including trafic all |      1,295
//----------------------------------------+------------
//                                  Total |     27,413 

//_______________________________________________________________________
//
// Supplementary Figure 1. The distribution of individuals according to the number and type of misconduct received 
// over the period 2011Q1-2014Q4. 
//_______________________________________________________________________

graph bar, over(alle_type) by(j, note("") title("Number of cases of misconduct")) scheme(plotplainblind) ///
ytitle("% of People with Cases of Misconduct") 


// Proportion of civil staff, males, black people
// -----------------------------------------------
// The final panel of data has repeated quarterly 
// observations nested within each of the individuals. It comprises 35,924 people 
// (31.7% were civil staff; 64.7%, males; and 13.6%, from black and minority ethnic groups) 
// for the period 2011 to 2014. 
// This is the final panel of data for which we were able to identify the work groups of individuals by linking officers
//  assigned to the same supervisor in a given quarter. 

set more off
cd "$location_cleaned_data"
use "081018 CC  WW  SS GEO RATING RANK LM Peer common M2.dta", clear

sort GUID timeq

cd "$location_cleaned_data"
merge GUID using GUID_used_in_RE

keep if _merge==3

tab timeq if timeq<220 //from 2011Q2 TO 2011Q4

codebook GUID if timeq<220 & subset==1 //35924

codebook GUID if timeq<220 & subset==1 & ///
 EmployeeType_wf_3cat=="Civil Staff"  //11370
codebook GUID if timeq<220 & subset==1 & ///
  EmployeeType_wf_3cat=="Police" //  24,554 

display 11370


display 11370/35924 //31.6%
codebook GUID if timeq<220 & subset==1 & ///
 Gender=="Male"  //23261

 display 23261/35924 //64.7%

 codebook GUID if timeq<220 & subset==1 & ///
 Eth=="BME"

 display 4880/35924 //13.6%

