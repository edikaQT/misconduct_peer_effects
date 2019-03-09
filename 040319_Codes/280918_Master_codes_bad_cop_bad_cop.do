**********************************************************************
* Paper           	: Quispe-Torreblanca,E & Stewart, N (2019) Causal Peer Effects in Police Misconduct
* Date created      : 2017 January
* Purpose           : Data cleaning and regressions
* Latest version	: 2018September28
**********************************************************************
/////////////////////////////////////////////////////////////////////////////////////////
//
// PATHS STORING THE DATA
//
/////////////////////////////////////////////////////////////////////////////////////////
//
// Location of raw files:
// -------------------------
global location_data "C:\Users\edika\Desktop\key backup\bad cop bad cops\Met_data\complaints_and_sickness" 

// where we have:
// CC_STATA.txt // complaints records
// workforce_STATA.txt // demographics
// my.dta // stata file with a column showing months  

// Location of data about the performance of the staff/officers:
// ---------------------------------------------------------------
//
global location_performance_data "C:\Users\edika\Desktop\key backup\bad cop bad cops\Met_data\csv\231015 new files"


// Location of data containing ethnicity information:
// ---------------------------------------------------------------
// (here we also have "210117 SS.dta", a database containing records of illness. We use it to identify the ethnicity of the 
// individuals)

global location_sickness_data ///
"C:\Users\edika\Desktop\key backup\bad cop bad cops\Met_data\complaints_and_sickness\stata files\210117 final do and files"

global location_peer_data ///
"C:\Users\edika\Desktop\key backup\bad cop bad cops\Met_data\complaints_and_sickness\stata files\210117 final do and files"

// Location where the outputs and cleaned data will be saved:
// -----------------------------------------------------------
//
global location_cleaned_data ///
"C:\Users\edika\Desktop\key backup\bad cop bad cops\Met_data\complaints_and_sickness\stata files\210117 final do and files\2018_output_folder"


// Location of codes:
// --------------------
//
global location_codes /// where the do files are saved
"C:\Users\edika\Desktop\GITHUB\bad_cops_files\March_19_final_revision_to_be_submitted\040319_Codes"


cd "$location_codes"

run 280918_data_cleaning.do
/////////////////////////////////////////////////////////////////////////////////////////
//
//                                 DATA CLEANING
//                                 ==============
//
//  --- IMPORTING COMPLAINTS //2010q2 to 2015q1
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
//      rank_police_d (rank for police up to Chief Superintendent. Commander, all Commisioner, and special Sergeant omitted)
//      LengthofServiceGroup_d (years of service)
// 
//      We are also adding variables for the performance rating of the staff (and their line managers) and the ranking in the peer group is based on this performance
//      However these variables for performance ranking are only created for reference purposes since they do not provide much relevant information
//      because ratings are usually 2 or 3 (in an scale 1-5) and shows little variation among peers.
//      Although the rankings of performance do not provide much relevant information, a non-missing value for the ranking
//      help us to recognise those individuals that have (1) a line manager in the quarter and (2) a performance score in the quarter
//
//      
//      save "210117 CC  WW  SS GEO RATING RANK LM.dta"
//
//  --- PREPARING A DATASET THAT WILL BE USED IN R TO IDENTIFY WHO CHANGED PEERS?
//
//      save "270117 Data for R to see impact of changes in peers and LM.dta"
//
//
//
// R code: '280117_R_code_to_identify_who_changed_peers'
// --------------------------------------------------------
// 
//  The code identifies who changes peers in certain time interval (group of quarters). 
//  --- it shows  (1) number of total peers in the interval
//  --- it shows  (2) number of peers that worked with employee during all the quarters included in the interval
//      
//  It uses data "270117 Data for R to see impact of changes in peers and LM.dta"
//  It save the following csv files:
//  "140217 Who changes peerv2_l1andl2.csv"
//  "140217 Who changes peerv2_l1andl3.csv"
/////////////////////////////////////////////////////////////////////////////////////////








run 280918_types_allegations.do

/////////////////////////////////////////////////////////////////////////////////////////
//
//                                 TYPES OF ALLEGATIONS
//                                 =========================
//
//use "210117 CC  WW  SS GEO RATING RANK LM.dta"
//
////////////////////////////////////////////////////////////////////////////
//  --- CREATING DUMMIES FOR THE TYPES OF ALLEGATIONS
////////////////////////////////////////////////////////////////////////////
//Failirues in duty
//------------------
//TypeDes_1                       TypeDesc-Breach Code A PACE
//TypeDes_2                       TypeDesc-Breach Code B PACE
//TypeDes_3                       TypeDesc-Breach Code C PACE
//TypeDes_4                       TypeDesc-Breach Code D PACE
//TypeDes_5                       TypeDesc-Breach Code E PACE
//TypeDes_13                      TypeDesc-Multiple or unspecified breaches of
//TypeDes_8                       TypeDesc-Improper disclosure of information
//TypeDes_14                      TypeDesc-Oppressive conduct or harassment
//TypeDes_16                      TypeDesc-Other assault
//TypeDes_17                      TypeDesc-Other irregularity in procedure
//TypeDes_18                      TypeDesc-Other neglect or failure in duty
//
//Malpractice
//-------------
//TypeDes_6                       TypeDesc-Corrupt practice
//TypeDes_12                      TypeDesc-Mishandling of property
//TypeDes_10                      TypeDesc-Irregularity in evidence/perjury
//
//discriminicatory behaviour
//-------------------------------
//TypeDes_7                       TypeDesc-Discriminatory Behaviour
//TypeDes_11                      TypeDesc-Lack of fairness and impartiality
//
//Incivility
//----------------
//TypeDes_9                       TypeDesc-Incivility, impoliteness
//
//Other
//--------
//TypeDes_15                      TypeDesc-Other
//
//Oppressice behaviour
//----------------------
//TypeDes_19                      TypeDesc-Other sexual conduct
//TypeDes_20                      TypeDesc-Serious non-sexual assault
//TypeDes_21                      TypeDesc-Sexual assault
//TypeDes_23                      TypeDesc-Unlawful/unnecessary arrest
//
//Traffic irregularity
//--------------------------
//TypeDes_22                      TypeDesc-Traffic irregularity

//save  "081018 CC  WW  SS GEO RATING RANK LM Peer common.dta"
//
/////////////////////////////////////////////////////////////////////////////////////////



run 280918_excluding_same_day_misconduct.do
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
//                                 COMPUTE THE NUMBER OF PEERS WHO HAD COMPLAINTS IN A DIFFERENT DATE THAN THE TARGET INDIVIDUAL
//                                 =================================================================================================
//  (if the target individual and his peers had complaints on the same day, it is very likely that the complaints are related to the same case. 
//   We want to exclude these cases and we want to focus on cases of complaints from peers that had no connection with the complaints received by the individual)
//
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
//  import delimited "CC_STATA.txt"...
//  merge GUID timeq using "081018 CC  WW  SS GEO RATING RANK LM Peer common.dta"...
//  save "081018  CC  WW  SS GEO RATING RANK LM Peer common - t2.dta"...
//  save "091018 for loop.dta"
//
//  NUMBER OF PEERS WITH COMPLAINTS IN A QUARTER:
//  -----------------------------------------------
//  How many people had complaint in different dates than target GUID in quarter?
//  ====================================================================
//  Example to understand the loop
//  ---------------------------------
//  If target GUID had 7 peers (1, 2, 3, 4, 5, 6, and 7), and some of these peers had complaints in DAY1, DAY2, DAY3 or DAY4, as listed below.
//  If target GUID has a complaint in DAY1 and DAY2 but he has no more complaints in the quarter

//  Day      	Peers with complaints						
//  1			(Peers 5  6  7         had complaints in day 1)		
//  2			(Peers 2  4  5  6      had complaints in day 2)
//  3        	(Peers 1  2  3  4      had complaints in day 3) <<<<<<<<<<<<<<<< in this day target GUID had no complaints
//  4        	(Peers 1  3  7         had complaints in day 4) <<<<<<<<<<<<<<<< in this day target GUID had no complaints

//  how many people had complaint in different dates than target GUID in the quarter? 
//  1  2  3  4  7, so 5 people
//
//  we built two loops that count the number of peers who had complaints in different dates
//
//   1) NUMBER OF PEERS WITH COMPLAINTS DIVIDED BY THE ACTION TYPE RECEIVED 
//
//     use "091018 for loop.dta"...
//     save "091018 for loop_results.dta"
//
//   2) NUMBER OF PEERS WITH COMPLAINTS (no division by sanction received, just the general count) 
//
//     use "091018 for loop.dta"...
//     save "091018 result looop do peers for num complaints M2.dta"...
//     save "091018 result looop do peers for num complaints M2 collapse.dta"
//
//     use "091018 for loop_results.dta"...
//     merge GUID timeq using "110217 result looop do peers for num complaints M2 collapse.dta"...
//     save "091018 results loop peers with num complaintM2.dta"
//
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////







run 280918_peer_data_part1
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
// --- creating dummies for peers' misconduct and for peers receiving any specific sanction
// --- creating an approximation of the length of service 
// --- adding variables for the performance/rating and the police rank
//
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


run 280918_peer_data_part2 //considers cases when target moves to other group or when one or more cops move to his group

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
//
//                         PREPARING THE DATA OF PEOPLE WHO CHANGE PEERS IN ORDER TO DO IV REGRESSIONS
//                        ================================================================================
//
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// It uses:
//  "081018 CC  WW  SS GEO RATING RANK LM Peer common M2.dta"
//  "140217 Who changes peerv2_l1andl2.csv"
//  "140217 Who changes peerv2_l1andl3.csv"
// It saves:
//  "101018 restricted peer 3 periods t-1 quarter new way_any_movement", replace

// HERE WE PREPARE THE DATA OF PEOPLE WHO CHANGE PEERS IN ORDER TO DO IV REGRESSIONS
// Target person: 'Target'

// If 'Target' is in quarter T and we want to know the effects of peers
//    (1) we use peers in T-1 TO AVOIDE THE REFLECTION PROBLEM
//    (2) BUT IT IS STILL POSSIBLE THAT THERE ARE CORRELATED EFFECTS because
//        the 'Target' and his peers are in the same environment
//        or because they were matched together based on unobservable features
//        SO WE CANNOT USE PEERS IN T-1 BUT WE CAN INSTRUMENT THEM	
//
// =====================
//  METHOD (what we do here...)
// =====================

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

//  - We restrict the data and we include ONLY target 'T' who moves in t-1 to group 'Line Manager 2'
//    (by move we mean that 100% of their peers in t-1 are NEW. 
//     So no one of his peers in t-2 move with him to 'Line Manager 2' in t-1.

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

// summary of steps: 
// - we import the (1) total number of peers in quarters t-1  and
//   (2) the total number of peers who worked with the target in both quarters t-1 and t-2, which is a subset of (1)
// - we also import the (1) total number of peers in quarters t-1 and 
//   (2) the total number of peers who worked with the target in both quarters t-1 and t-3, which is a subset of (1)

// - merge GUID timeq using "081018 CC  WW  SS GEO RATING RANK LM Peer common M2.dta" 
// - creating lags of peer misconduct
// - save "101018 DATA UPDATED WITH PEERS L1ANDXX.dta", replace

// - keeping those GUID that move in t-1. So we use the restriction:
//   (1) peers in t-1 different from peers in  t-2 &
//   (2) peers in t-1 different from peers in  t-3  
//    in consequence, GUID moves in t-1
//    (recall that peers remain for at least 2 quarters, so new peers in t-1 remain as peers in t)
// - FINDIG WHEN THERE WERE SIMULTANEOUS MOVEMENTS AND WHEN THERE WAS ONLY ONE MOVEMENT TO THE NEW LINE MANAGER 
//   (we want to identify simultaneous movements, i.e., find 'H' moving to LM2 in t-1 too )  

// - PREPARING CONTROLS IN DATA
// - MERGING WITH INSTRUMENTS (FOR PEOPLE WHO MOVED AND NEW PEERS WHO MOVED SIMULTANEOUSLY TO LM2 IN OUR EXAMPLE)
// - NOW MERGING WITH PEOPLE WHO STAYED BUT PEERS MOVED
//   (recall we know who moved alone to a new LM. The target is the one who stayed but received the new peer)
//
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////



///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
//
//                                               REGRESSIONS
//                                       ===============================
//
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//  It uses: "101018 restricted peer 3 periods t-1 quarter new way_any_movement", replace
// =====================
//   MAIN REGRESSIONS
// =====================
// ALL COPS
global business_groups_control level3_territorial_police_v2
global restrictions_subset " "
run 280918_regressions.do

// Outputs, Tables: table_RE_FE.doc, table_IV.doc, first_stage.doc and table_composition.rtf correspond to the following tables in the paper
// Supplementary Table 3 (RE and FE estimates)
// Table 2 (GMM and IVPROBIT estimates)
// Supplementary Table 4: First Stage GMM Results (from Table 2, GMM)
//
// Outputs, Figures:
// Supplementary Figure 2: Distribution of number of peers by sample. The top panel includes all quarters. The
// Figure 2. Fitted probability of misconduct at conditional on the proportion of peers exhibiting events of misconduct in t − 1 
// We also save people used in the RE regressions in GUID_used_in_RE.dta

// =================================
//   ROBUST CHECKS - REGRESSIONS
// =================================


// In Supplementary Information, we repeat the analysis adding fixed effects for each borough (level4_territorial_police_v2) and
// distinguishing the effect for the cases in which the cop moves to a new group or when 
// a peer moves to the group of the target

// ALL COPS
global business_groups_control level4_territorial_police_v2
global restrictions_subset " "
run 280918_regressions.do
// Outputs, Tables: table_IV.doc and first_stage.doc correspond to the following tables in the paper
// Supplementary Table 5 (GMM AND IVPROBIT estimates)
// Supplementary Table 6: First Stage GMM Results (from Table 5, GMM)



// COPS WHO MOVED
global business_groups_control level4_territorial_police_v2
global restrictions_subset " if proportion_per_l1andl2==0 &  proportion_per_l1andl3==0 " 
run 280918_regressions.do
// Outputs, Tables: table_IV.doc and first_stage.doc correspond to the following tables in the paper
// Supplementary Table 7, Columns 1 and 2 (GMM AND IVPROBIT estimates)
// Supplementary Table 8: First Stage GMM Results (from Table 7, Column 1, GMM)


// COPS WHO STAYED
global business_groups_control level4_territorial_police_v2
global restrictions_subset " if proportion_per_l1andl2!=0 |  proportion_per_l1andl3!=0 " 
run 280918_regressions.do
// Outputs, Tables: table_IV.doc and first_stage.doc correspond to the following tables in the paper
// Supplementary Table 7, Columns 3 and 4 (GMM AND IVPROBIT estimates)
// Supplementary Table 8: First Stage GMM Results (from Table 7, Column 3, GMM)


// ALL COPS (Including the Interaction of Peer Misconduct and Peer Group Size )
global business_groups_control level4_territorial_police_v2
global restrictions_subset " "
run 291118_interaction.do
// Outputs, Tables: table_interaction.doc and first_stage_interaction.doc, correspond to the following tables in the paper
//  Supplementary Table 9 (GMM AND IVPROBIT estimates)
//  Supplementary Table 10: First Stage GMM Results (from Table 9, Column 1, GMM)

// WHY COPS SWITCH LINE MANAGERS OR MOVE GROUPS?
global business_groups_control level3_territorial_police_v2
global restrictions_subset " "
run 191118_why_they_move.do
// Outputs, Tables: table_move.doc corresponds to the following tables in the paper
//  Supplementary Table 11 (RE estimates)

// =================================
//   FALSIFICATION - REGRESSIONS
// =================================
run 280918_falsification.do
// Outputs, Tables: table_falsification.doc and table_falsification_column4.doc correspond to the following tables in the paper
// Table 3. Estimated Likelihood of Misconduct, Peer Effects: Falsification Test


// =================================
//   DESCRIPTIVE STATISTICS
// =================================

// We show the descriptive statistics of the sample with peers and line managers used in our main regressions
global business_groups_control level4_territorial_police_v2
global restrictions_subset " "
run 280918_regressions.do
//  sample used with peers is saved in GUID_used_in_RE.dta
run 101018_desc_tables.do
// Outputs: "table_corr.rtf" corresponds to the following tables in the paper
// Supplementary Table 1. Correlation of Allegations Within Individuals
// Other outputs:
// Table 1. The Distribution of Allegations Against Civil Staff and Police Officers by Disciplinary Outcome
// Supplementary Figure 1. The distribution of individuals according to the number and type of misconduct received 
