
*********************************************************************************************
*																							*
*		*Inferring occupations arduousness from poor health beyond the age of 50			*
*																							*
*               *A. Baurin, S. Tubeuf & V. Vandenberghe										*
*																							*
* arno.baurin@uclouvain.be; sandy.tubeuf@uclouvain.be, vincent.vandenberghe@uclouvain.be	*
*																							*
*********************************************************************************************


*********************************************************************************
*																				*
*							***CODE FOR O*NET DATA***							*
*																				*							
*********************************************************************************

clear all

***GLOBAL PATH***

global path "C:\Users\baurin\OneDrive - UCL"

*****************

clear all
set more off

global source "$path\\UCLouvain - Impact of job on health\Data & Code\ONET data\db_24_3_excel"
global working "$path\\UCLouvain - Impact of job on health\Data & Code\Working file"
global output "$path\\UCLouvain - Impact of job on health\Data & Code\Output file"

*Save the data in .dta format with indicator of Origin

import excel using "$source\\Work Context.xlsx", firstrow clear
rename *, lower
gen Origin = "4"

keep scaleid elementname datavalue onetsoccode Origin

*Keep only the needed measurements 
keep if scaleid=="IM" | scaleid=="CX" | scaleid == "CT"
drop scaleid

*Simplify values and names when reshaping 


rename datavalue s
replace elementname=subinstr(elementname, " ", "_", .) 
replace elementname=subinstr(elementname, ",", "", .) 
replace elementname=subinstr(elementname, "-", "", .) 
replace elementname=subinstr(elementname, "/", "", .) 
replace elementname=subinstr(elementname, "'", "", .) 
replace elementname = substr(elementname,1,30)
replace elementname =  Origin + elementname 

drop Origin

reshape wide s, i(onetsoccode) j(elementname) string

sort onetsoccode
rename onetsoccode onetsoc10

*Saving the clean, O*Net-SOC 10 data
save "$working\onetsoc10.dta", replace

********************************************************************************

*Transforming O*Net to penibility index 

use "$working\onetsoc10.dta", clear

pca s4*, component(3) blank(0.12)

predict penib, score 
qui: su penib
replace penib = penib/r(sd)

*Final cleaning + transforming to ISCO08

keep penib onetsoc10

*From O*NET-SOC 10 to SOC 10
replace onetsoc10 = subinstr(onetsoc10, "-", "", 1)
destring onetsoc10, replace
gen Soc10=int(onetsoc10)
 
*From SOC 10 to ISCO-08
joinby Soc10 using "$path\\UCLouvain - Impact of job on health\Data & Code\ONET data\soc10_isco08.dta"
iscogen isco08 = submajor(isco08), replace
iscolbl isco08 isco08, submajor
collapse (mean) penib, by(isco08)

save "$output\penib.dta", replace

*********************************************************************************
*																				*
*							***END OF CODE FOR O*NET DATA***					*	
*																				*
*********************************************************************************

*********************************************************************************
*																				*
*							***CODE FOR SHARE DATA***							*
*																				*
*********************************************************************************

***************************Health during childhood******************************

clear all
set more off

global source "$path\\UCLouvain - Impact of job on health\Data & Code\SHARE data"
global working "$path\\UCLouvain - Impact of job on health\Data & Code\Working file"
global output "$path\\UCLouvain - Impact of job on health\Data & Code\Output file"

*from Wave 3

use "$source\\Wave 3 Release 7.1.0\sharew3_rel7-1-0_hs.dta", clear 
keep sl_hs003_ mergeid 

mvdecode sl_hs003_, mv(-2 -1 6)
rename sl_hs003_ health_child 

save "$working\\child_health_w3", replace

*from Wave 7

use "$source\\Wave 7 Release 7.1.0\sharew7_rel7-1-0_hs.dta", clear 
keep hs003_ mergeid 

mvdecode hs003_, mv(-2 -1 6)
rename hs003_ health_child 

save "$working\\child_health_w7", replace

*merging files

use "$working\\child_health_w7", clear 

merge 1:1 mergeid using "$working\\child_health_w3", nogen update

save "$output\\child_health_final", replace

*************************End of health during childhood*************************


***************************Health of parent*************************************

clear all
set more off

global source "$path\\UCLouvain - Impact of job on health\Data & Code\SHARE data"
global working "$path\\UCLouvain - Impact of job on health\Data & Code\Working file"
global output "$path\\UCLouvain - Impact of job on health\Data & Code\Output file"

use "$source\\Wave 7 Release 7.1.0\sharew7_rel7-1-0_dn.dta", clear 
 
keep dn027_1 dn027_2 country mergeid dn026_2 dn026_1

rename dn027_1 age_death_mother
rename dn027_2 age_death_father
rename dn026_1 mother_alive
rename dn026_2 father_alive

mvdecode age_death_mother age_death_father mother_alive father_alive, mv(-1 -2 )

qui foreach k in mother father {

gen death_status_`k' = .
replace death_status_`k' = 1 if `k'_alive == 1 

qui foreach j in 11 12 13 14 15 16 17 18 19 20 23 25 28 29 30 31 32 33 34 35 47 48 51 53 55 57 59 61 63 {
su age_death_`k' if country == `j', d
scalar r = r(p50)
replace death_status_`k' = 2 if age_death_`k' != . & age_death_`k' <= r & country ==  `j'
replace death_status_`k' = 3 if age_death_`k' != . & age_death_`k' > r & country == `j'
}
}

label define ldeath 1 "Alive" 2 "Premature dead" 3 "Normal dead"
label values death_status_mother ldeath
label values death_status_father ldeath
 
keep mergeid death_status_mother death_status_father

save "$output\\parent", replace

***********************End of health of parent********************************** 

*****************************Job of parent**************************************

clear all
set more off

global source "$path\\UCLouvain - Impact of job on health\Data & Code\SHARE data"
global working "$path\\UCLouvain - Impact of job on health\Data & Code\Working file"
global output "$path\\UCLouvain - Impact of job on health\Data & Code\Output file"

use "$source\\Wave 7 Release 7.1.0\sharew7_rel7-1-0_cc.dta", clear 
 
keep mergeid cc009isco 

qui: mvdecode _all, mv(95 97 -1 -2 -3 -4 -5 -7 -9 -91 -92 -93 -94 -95 -97 -98 -99 -9999991 -9999992)  

rename cc009 isco

gen isco_cat_ = 9 if isco > 9000
replace isco_cat_ = 8 if isco < 9000
replace isco_cat_ = 7 if isco < 8000
replace isco_cat_ = 6 if isco < 7000
replace isco_cat_ = 5 if isco < 6000
replace isco_cat_ = 4 if isco < 5000
replace isco_cat_ = 3 if isco < 4000
replace isco_cat_ = 2 if isco < 3000
replace isco_cat_ = 1 if isco < 2000
replace isco_cat_ = 0 if isco==.

replace isco_cat = 3 if isco==110 | isco==210 | isco==310 /* armed forces */

replace isco_cat = 2 if isco==212 /* Mathematicians, actuaries and statisticians */
 
tab isco_cat, ge(isco_cat)
rename isco_cat1 isco_unknown
rename isco_cat2 isco_1000
rename isco_cat3 isco_2000
rename isco_cat4 isco_3000
rename isco_cat5 isco_4000
rename isco_cat6 isco_5000
rename isco_cat7 isco_6000
rename isco_cat8 isco_7000
rename isco_cat9 isco_8000
rename isco_cat10 isco_9000

gen managers_professionals = (isco_1000 | isco_2000)
gen technic_profess_armed = (isco_3000)
gen clerk_service_sales = (isco_4000 | isco_5000)
gen agriculture_fishery = (isco_6000)
gen craftsmen_skilled = (isco_7000)
gen elementary_unskilled = (isco_8000 | isco_9000)

label variable isco_unknown "No main breadwinner"
label variable managers_professionals "Managers and professionals"
label variable technic_profess_armed "Technicians, associate professionals and armed forces"
label variable clerk_service_sales "Office clerks, service workers and sales workers"
label variable agriculture_fishery "Skilled agricultural and fishery workers"
label variable craftsmen_skilled "Craftsmen and skilled workers"
label variable elementary_unskilled "Elementary occupations and unskilled workers"

gen job_parent = .

replace job_parent = 1 if isco_unknown == 1
replace job_parent = 2 if managers_professionals == 1
replace job_parent = 3 if technic_profess_armed == 1
replace job_parent = 4 if clerk_service_sales == 1
replace job_parent = 5 if agriculture_fishery == 1
replace job_parent = 6 if craftsmen_skilled == 1
replace job_parent = 7 if elementary_unskilled == 1

label define ljobparent 1 "ISCO_unknown" 2 "Managers_professionals" 3 "Techinc_profess_armed" 4 "Clerk_service_sales" 5 "Agriculture_fishery" 6 "Craftsmen_skilled" 7 "Elementary_unskilled"

label values job_parent ljobparent

keep mergeid job_parent

save "$output\\job_parent", replace

***************************End of job of parent*********************************
 
********************************Education***************************************

clear all
set more off

global source "$path\\UCLouvain - Impact of job on health\Data & Code\SHARE data"
global working "$path\\UCLouvain - Impact of job on health\Data & Code\Working file"
global output "$path\\UCLouvain - Impact of job on health\Data & Code\Output file"

use "$source\\Wave 7 Release 7.1.0\sharew7_rel7-1-0_gv_isced.dta", clear 

keep mergeid isced1997_r isced1997_m isced1997_f
rename isced1997_r education
rename isced1997_f education_mother
rename isced1997_m education_father 
qui: mvdecode _all, mv(95 97 -1 -2 -3 -4 -5 -7 -9 -91 -92 -93 -94 -95 -97 -98 -99 -9999991 -9999992)  

save "$output\\education_final", replace

*****************************End of education***********************************


***********************************Health***************************************

clear all
set more off

global source "$path\\UCLouvain - Impact of job on health\Data & Code\SHARE data"
global working "$path\\UCLouvain - Impact of job on health\Data & Code\Working file"
global output "$path\\UCLouvain - Impact of job on health\Data & Code\Output file"

use "$source\\Wave 7 Release 7.1.0\sharew7_rel7-1-0_gv_health.dta", clear

merge 1:1 mergeid using "$source\\Wave 7 Release 7.1.0\sharew7_rel7-1-0_ph.dta", nogen

keep mergeid eurod sphus sphus2 adl ph004_ ph005_ iadl ph006d1 ph006d2 ph006d3 ph006d4 ph006d5 ph006d6 ph006d10 ph006d11 ph006d12 ph006d13 ph006d14 ph006d15 ph006d16 ph006d18 ph006d19 ph006d20 ph006d21 ph006dno ph006dot mobility maxgrip bmi

rename adl number_limitations
rename eurod depression
rename sphus health_wave7
rename sphus2 health_wave7_dicho
rename ph004_ long_term_illness
rename ph005_ limited_in_activities
rename iadl limit_with_instrumental_acti
rename ph006d1 heart_attack
rename ph006d2 high_blood_pressure
rename ph006d3 high_blood_cholesterol
rename ph006d4 stroke
rename ph006d5 diabetes
rename ph006d6 chronic_lung_disease
rename ph006d10 cancer
rename ph006d11 stomach
rename ph006d12 parkinson
rename ph006d13 cataracts
rename ph006d14 hip_fracture
rename ph006d15 other_fracture
rename ph006d16 alzheimer
rename ph006d18 other_affective_disorders
rename ph006d19 rheumatoid
rename ph006d20 osteoarthritis
rename ph006d21 chronic_kidney
rename ph006dno none
rename ph006dot other 

qui: mvdecode _all, mv(-1 -2 -3 -4 -5 -7 -9 -91 -92 -93 -94 -95 -97 -98 -99 -9999991 -9999992) //recode to missing 

pca health_wave7 long_term_illness limited_in_activities number_limitations limit_with_instrumental_acti 
predict physical_health_subjective, score  

foreach var of varlist physical_health_subjective   {
    su `var'
	replace `var' = `var'/r(sd)
	xtile q`var' = `var', nq(4)
}

keep health_wave7_dicho physical_health_subjective   mergeid  health_wave7

save "$output\\health_final", replace

********************************End of health***********************************


***********************************Job history**********************************

clear all
set more off

global source "$path\\UCLouvain - Impact of job on health\Data & Code\SHARE data"
global working "$path\\UCLouvain - Impact of job on health\Data & Code\Working file"
global output "$path\\UCLouvain - Impact of job on health\Data & Code\Output file"

use "$source\\Wave 7 Release 7.1.0\sharew7_rel7-1-0_re.dta", clear

forvalues i = 1/20 {
rename re011_`i' yjobs`i'
rename re026_`i' yjobf`i'
}

qui mvdecode yjobf* yjobs*, mv(-1 -2)
 
merge 1:1 mergeid using "$source\\\All Waves Coverscreen Release 7.1.0\sharewX_rel7-1-0_gv_allwaves_cv_r.dta"
drop if _merge == 2

 
*Recode "still in this job" to the year of the interview
qui forvalues i = 1/20 {
replace yjobf`i' = int_year_w7 if yjobf`i' == 9997
}

***Adding full-time, part-time,... for the time in the job; full time = 1, part-time = 0.5, if change = 0.75
qui forvalues i = 1/20 {
rename re012isco_`i'   isco`i'
rename re016_`i' part_full_time`i'
recode part_full_time`i' (2 = 0.5) (3 4 5 = 0.75) (-2 -1 = .)
}

*Time in the job 
qui forvalues i = 1/20 {
gen time_in_job_`i' = yjobf`i' - yjobs`i'
replace time_in_job_`i' = time_in_job_`i'  * part_full_time`i'
replace time_in_job_`i' = . if time_in_job_`i' < 0
}

keep mergeid time_in_job_* isco*  

reshape long time_in_job_ isco, i(mergeid) j(job_episode)  //as many lines as job episodes
drop if missing(time_in_job_, isco)
tab isco
iscogen isco = submajor(isco),  replace  //isco 2-digit
recode isco (.=9999)
label define isco 9999 "Missing", modify
label values isco isco

levelsof isco, local (iscolist) clean missing  //put isco 2-digit into a macro [iscolist]
local n :  word count `iscolist'
display `n'

qui forvalues i = 1/`n' {
local w: word `i' of `iscolist'
gen isco_`w' = .    
}


qui forvalues i = 1/`n' {
local w: word `i' of `iscolist'
replace isco_`w' = 1 if isco == `w'  //correspondence tag
replace isco_`w' =  isco_`w' * time_in_job_  //pick the time
rename isco_`w' time_in_isco`w'  
}

drop isco time_in_job_ job_episode 

collapse (sum) time_in_isco*, by(mergeid) //back to one line per respondent ([sum] instead of [max])

dropmiss time_in_isco*, force

save "$working\\job_history", replace

********************************End of job history******************************

*******************************First and last job*******************************
*****************************Job history**********************************

clear all
set more off

global source "$path\\UCLouvain - Impact of job on health\Data & Code\SHARE data"
global working "$path\\UCLouvain - Impact of job on health\Data & Code\Working file"
global output "$path\\UCLouvain - Impact of job on health\Data & Code\Output file"

use "$source\\Wave 7 Release 7.1.0\sharew7_rel7-1-0_re.dta", clear

gen last_job = .

qui forvalues i = 1/20 {
replace last_job = re012isco_`i' if re012isco_`i' != .
}

rename re012isco_1 first_job

keep first_job last_job mergeid

qui mvdecode _all, mv(-1 -2 -7)

iscogen first_job = submajor(first_job), replace
iscogen last_job = submajor(last_job), replace
 
save "$working\\first_last_job", replace

***************************End of first and last job*****************************


********************************Job instability history*************************

clear all
set more off

global source "$path\\UCLouvain - Impact of job on health\Data & Code\SHARE data"
global working "$path\\UCLouvain - Impact of job on health\Data & Code\Working file"
global output "$path\\UCLouvain - Impact of job on health\Data & Code\Output file"

use "$source\\Wave 7 Release 7.1.0\sharew7_rel7-1-0_re.dta", clear

gen njobs=0
gen ngaps=0

qui forvalues i=1/20 {
replace njobs=njobs+1 if !missing(re012isco_`i')  					 
replace ngaps=ngaps+1 if  re032_`i'==2 & !missing(re012isco_`i')  		 
}

rename re005_ ever_work 

mvdecode ever_work , mv(-1 -2)

qui forvalues i = 1/20 {
	replace re032_`i' = 0 if re032_`i' != 2
	replace re032_`i' = 1 if re032_`i' == 2
}

egen nbunemployed = rowtotal(re032_*)

keep mergeid ever_work njobs ngaps nbunemployed

save "$working\\Job_instability", replace

********************************End of job instability history****************** 


**************************************Main job********************************** 

clear all
set more off

global source "$path\\UCLouvain - Impact of job on health\Data & Code\SHARE data"
global working "$path\\UCLouvain - Impact of job on health\Data & Code\Working file"
global output "$path\\UCLouvain - Impact of job on health\Data & Code\Output file"


use "$working\\job_history", replace
 
gen main_job = .

egen time_in_main_job = rowmax(time_in_isco*)

qui foreach i in 1 2 3 11 12 13 14 21 22 23 24 25 26 31 32 33 34 35 41 42 43 44 51 52 53 54 61 62 63 71 72 73 74 75 81 82 83 91 92 93 94 95 96 {
replace main_job = `i' if time_in_isco`i' == time_in_main_job & !inlist(time_in_main_job,. ,9999)
}
 
keep main_job mergeid time_in_main_job  

save "$working\\Main_job", replace
 
*******************************End of main job**********************************

use "$working\\Main_job", clear
merge 1:1 mergeid using "$working\\job_history", nogen
merge 1:1 mergeid using "$working\\Job_instability", nogen

save "$output\\Job", replace



*********************************************************************************
*																				*
*							***END OF CODE FOR SHARE DATA***					*
*																				*
*********************************************************************************

*********************************************************************************
*																				*
*					***CODE FOR MERGING THE FILES***							*
*																				*
*********************************************************************************

clear all
set more off

global source "$path\\UCLouvain - Impact of job on health\Data & Code\SHARE data"
global working "$path\\UCLouvain - Impact of job on health\Data & Code\Working file"
global output "$path\\UCLouvain - Impact of job on health\Data & Code\Output file"

use "$output\\Job"

merge 1:1 mergeid using "$output\\child_health_final", nogen
merge 1:1 mergeid using "$output\\education_final", nogen
merge 1:1 mergeid using "$output\\health_final", nogen
merge 1:1 mergeid using "$output\\parent", nogen
merge 1:1 mergeid using "$working\first_last_job", nogen
merge 1:1 mergeid using "$output\\job_parent", nogen

save  "$output\\Job", replace

preserve 

use "$source\\\All Waves Coverscreen Release 7.1.0\sharewX_rel7-1-0_gv_allwaves_cv_r.dta", clear

keep mergeid age_int_w7 country gender

save  "$working\\Age", replace

restore 

merge 1:1 mergeid using "$working\\Age", nogen

rename main_job isco08

merge m:1 isco08 using "$output\\penib", nogen


rename isco08 main_job
rename penib penib_main_job

sort main_job


gen i = 1

qui foreach j in 11 12 13 14 21 22 23 24 25 26 31 32 33 34 35 41 42 43 44 51 52 53 54 61 62 63 71 72 73 74 75 81 82 83 91 92 93 94 95 96 {

gen penib`j' = 0
 
while main_job[i] != `j' {
replace i = i + 1
}

replace penib`j' = penib_main_job[i]
count if main_job == `j'
replace i = i + r(N)
}

drop i

qui foreach i in 11 12 13 14 21 22 23 24 25 26 31 32 33 34 35 41 42 43 44 51 52 53 54 61 62 63 71 72 73 74 75 81 82 83 91 92 93 94 95 96 {

gen cumu_penib_`i' = time_in_isco`i' * penib`i'
}

egen total_penib = rowtotal(cumu_penib*)
 
drop cumu_penib* 

gen mean_penib = total_penib/njobs  


qui foreach i in 11 12 13 14 21 22 23 24 25 26 31 32 33 34 35 41 42 43 44 51 52 53 54 61 62 63 71 72 73 74 75 81 82 83 91 92 93 94 95 96 {

gen pt_penib_`i' = penib`i' if time_in_isco`i' != .
}

egen sd_penib = rowsd(pt_penib*)

drop pt* penib1* penib2* penib3* penib4* penib5* penib6* penib7* penib8* penib9*

des time_in_isco*
rename time_in_isco* T_*
  label var  T_1  "1. Commissioned armed forces officers"
  label var  T_2  "2. Non-commissioned armed forces officers"
   label var  T_3   "3. Armed forces occupations, other ranks"
    *label var  T_10   "10. Managers"
  label var  T_11   "11. Chief executives, senior officials and legislators"
    label var T_12  "12. Administrative and commercial managers"
      label var T_13    "13. Production and specialized services managers"
          label var T_14   "14. Hospitality, retail and other services managers"
          *label var T_20   "20. Professionals"
          label var T_21   "21. Science and engineering professionals"
          label var T_22   "22. Health professionals"
          label var T_23   "23. Teaching professionals"
          label var T_24   "24. Business and administration professionals"
          label var T_25   "25. Information and communications technology professionals"
          label var T_26   "26. Legal, social and cultural professionals"
          *label var T_30   "30. Technicians and associate professionals"
          label var T_31   "31. Science and engineering associate professionals"
          label var T_32   "32. Health associate professionals"
          label var T_33   "33. Business and administration associate professionals"
          label var T_34   "34. Legal, social, cultural and related associate professionals"
          label var T_35   "35. Information and communications technicians"
          *label var T_40   "40. Clerical support workers"
          label var T_41   "41. General and keyboard clerks"
          label var T_42   "42. Customer services clerks"
          label var T_43   "43. Numerical and material recording clerks"
          label var T_44   "44. Other clerical support workers"
          *label var T_50   "50. Services and sales workers"
          label var T_51   "51. Personal services workers"
          label var T_52   "52. Sales workers"
          label var T_53   "53. Personal care workers"
          label var T_54   "54. Protective services workers"
         * label var T_60   "60. Skilled agricultural, forestry and fishery workers"
          label var T_61   "61. Market-oriented skilled agricultural workers"
          label var T_62   "62. Market-oriented skilled forestry, fishery and hunting workers"
          label var T_63   "63. Subsistence farmers, fishers, hunters and gatherers"
          * label var T_70   "70. Craft and related trades workers"
          label var T_71   "71. Building and related trades workers (excluding electricians)"
          label var T_72   "72. Metal, machinery and related trades workers"
          label var T_73   "73. Handicraft and printing workers"
          label var T_74   "74. Electrical and electronics trades workers"
        label var T_75   "75. Food processing, woodworking, garment and other craft and related trades workers"
          *label var T_80   "80. Plant and machine operators and assemblers"
          label var T_81   "81. Stationary plant and machine operators"
          label var T_82   "82. Assemblers"
          label var T_83   "83. Drivers and mobile plant operators"
          *label var T_90   "90. Elementary occupations"
          label var T_91   "91. Cleaners and helpers"
          label var T_92   "92. Agricultural, forestry and fishery labourers"
          label var T_93   "93. Labourers in mining, construction, manufacturing and transport"
          label var T_94   "94. Food preparation assistants"
          label var T_95   "95. Street and related sales and services workers"
          label var T_96   "96. Refuse workers and other elementary workers"


drop if health_wave7 == .

iscolbl isco08 main_job, submajor

recode health_child (1 2 = 0) (3 4 5 = 1)

save "$output\\Final_file", replace
  
*********************************************************************************
*																				*
*							***END OF CODE FOR MERGING THE FILES***				*
*																				*
*********************************************************************************
