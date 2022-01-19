
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
*					***CODE FOR THE ANALYSIS OF THE PAPER***					*
*																				*
*********************************************************************************
																
clear all
set more off

global path "C:\Users\baurin\OneDrive - UCL"

global source "$path\\UCLouvain - Impact of job on health\Data & Code\SHARE data"
global working "$path\\UCLouvain - Impact of job on health\Data & Code\Working file"
global output "$path\\UCLouvain - Impact of job on health\Data & Code\Output file"

cd "$working"

use "$output\\Final_file", clear

replace main_job = 99 if ever_work == 5
label define main_job 99 "No job", modify
label values main_job main_job 

drop if main_job ==  1 | main_job == 2 | main_job == 3 | main_job == 95

tab health_wave7 if main_job != .

save "$output\\Final_fileb", replace

////Male 

use "$output\\Final_fileb", clear

keep if gender == 1

save "$output\\Final_fileb_male", replace

global control age i.country 

use "$output\\Final_fileb_male", clear

qui reg health_wave7_dicho   ib33.main_job ib4.education i.health_child i.death_status_father i.death_status_mother ib4.job_parent $control, cformat(%9.3f)  //ref: 33.        Business and administration associa (highest freq)

keep if e(sample)
save "$working\\Final_fileb_male_reduit", replace 


///Story

///First, we will show the impact of job on health going from a naive regression to a complete one.

///Introduction
use "$working\\Final_fileb_male_reduit", clear

reg health_wave7_dicho  age ib33.main_job i.country, cformat(%9.3f) 	//ref:   33 Business and administration associate professionals (rappel: health_wave7_dicho: 0 bonne santé, 1 mauvaise santé)
parmest, saving(peniba, replace) 

save, replace

use "$working\\peniba", clear
gen parmx=""
replace parmx=substr(parm,1,2) if strpos(parm, "main_job")
keep if !missing(parmx)
drop parm
rename parmx parm
destring parm, replace

iscolbl isco08 parm, submajor
label define parm 99 "No job", modify

save first_reg_male.dta, replace  
					
use first_reg_male.dta, clear

append using first_reg_female, gen(Sex)
label define lsex 0 "Male" 1 "Female"
label values Sex lsex
					
label var Sex "sex"
					
graph dot estimate, over(parm, sort(estimate) label(labsize(vsmall))) yline(0) title(" ", size(medsmall)) ytitle("") scheme(s1mono) by(Sex)
					 
///Question 1: does taking the main job or the entire career change something? -> MALE 

use "$working\\Final_fileb_male_reduit", clear

reg health_wave7_dicho age ib99.main_job i.country, cformat(%9.3f) 	//ref: 99 "no job" pour être consistant avec l'équation en T
parmest, saving(penib1, replace)

reg health_wave7_dicho   age T_* i.country, cformat(%9.3f)
parmest, saving(penib2, replace)
				 
use "$working\\penib1", clear
gen parmx=""
replace parmx=substr(parm,1,2) if strpos(parm, "main_job")
keep if !missing(parmx)
drop parm
rename parmx parm
destring parm, replace
drop if parm==99
rename estimate est
rename * *1
rename parm1 parm
save est1, replace

use "$working\\penib2", clear
gen parmx=""
replace parmx=substr(parm,3,.) if strpos(parm,"T_")==1
keep if !missing(parmx)
drop parm
rename parmx parm
destring parm, replace
drop if parm==99
rename estimate est
rename * *2
rename parm2 parm
save est2, replace

use est1, clear
merge 1:1 parm using est2
keep if _merge==3
egen est1_std = std(est1) //standardisation
egen est2_std = std(est2)
iscolbl isco08 parm , submajor


***correlation between main_job and all the career
corr est1 est2
**97.52 % of correlation between raw coefficient

*visualisation in a graph dot, with normalization because values are different						///////////

graph dot est1_std est2_std, over(parm, sort(est1_std) label(labsize(vsmall))) ///
legend(label(1 "OCC: Main job")  label(2 "OCC: Time in ISCO")   region(color(none)) row(3) size(*.6) ) scheme(s1mono) yline(0)
graph export "$working\\Picture_main_job_time_male.png", as(png) replace


///QUESTION 1bis: Is it important to take first, last or main job? 

use "$working\\Final_fileb_male_reduit", clear 

replace first_job = 99 if ever_work == 5
replace last_job = 99 if ever_work == 5

foreach var of varlist first_job last_job {
	drop if `var' ==  1 | `var' == 2 | `var' == 3 | `var' == 95
}

reg health_wave7_dicho   age ib33.main_job i.country, cformat(%9.3f) 
parmest, saving(main, replace) 

reg health_wave7_dicho  age  ib33.first_job i.country, cformat(%9.3f)
parmest, saving(first, replace) 

reg health_wave7_dicho  age ib33.last_job i.country i.country, cformat(%9.3f)
parmest, saving(last, replace) 

foreach j in main  last first{
	use "$working\\`j'", clear

	replace parm=substr(parm,1,2 )

	rename * *_`j'
	rename parm parm

	destring parm, replace force

	drop if parm == .
				
	drop in 40/l
			
	save, replace
}

merge 1:1 parm using "$working\\main", nogen
merge 1:1 parm using "$working\\last", nogen

qui foreach x in  first main last {
	 su estimate_`x'
	 gen estimate_`x'_std=(estimate_`x' - r(mean))/r(sd)
}

 iscolbl isco08 parm , submajor 

*visualisation in a graph dot, with normalization because values are different						 

graph dot estimate_main_std estimate_last_std estimate_first_std, over(parm, sort(estimate_main_std) label(labsize(vsmall))) ///
legend(label(1 "OCC: Main job")  label(2 "OCC: Last job")  label(3 "OCC: First job")   region(color(none)) row(3) size(*.6) ) scheme(s1mono) yline(0)
graph export "$working\\Picture_main_first_last_job_male.png", as(png) replace
				  
corr estimate_main  estimate_first estimate_last
*81.99 between main and firstt 
*94.91 between main and last 

////QUESTION 2: How much the coefficient change when we include new variables? 

//		-> MALE
												
clear all
set more off

global path "C:\Users\baurin\OneDrive - UCL"

global source "$path\\UCLouvain - Impact of job on health\Data & Code\SHARE data"
global working "$path\\UCLouvain - Impact of job on health\Data & Code\Working file"
global output "$path\\UCLouvain - Impact of job on health\Data & Code\Output file"

cd "$working"
		
use "$working\\Final_fileb_male_reduit" 

global control age i.country 

reg health_wave7_dicho   ib33.main_job $control, cformat(%9.3f)  
parmest, saving(main, replace)

reg health_wave7_dicho   ib33.main_job ib4.education   $control, cformat(%9.3f)  
parmest, saving(education, replace)

reg health_wave7_dicho   ib33.main_job ib4.education i.health_child i.death_status_father i.death_status_mother ib4.job_parent $control, cformat(%9.3f)  
parmest, saving(complete, replace)

foreach j in main education complete {

	use `j', clear
	keep estimate parm 
	replace parm=substr(parm,1,2 ) 
	keep in 1/40
	destring parm,  replace
	save, replace 

}

use main, clear 
rename estimate est_main
merge 1:1 parm using education, nogen
rename estimate est_edu
merge 1:1 parm using complete, nogen 
rename estimate est_complete

iscolbl isco08 parm, submajor
label define parm 99 "No job", modify

graph dot est*, over(parm, sort(est_main) label(labsize(vsmall))) yline(0) title(" ", size(medsmall)) ytitle("") scheme(s1mono)  legend(label(1 "Baseline")  label(2 "Baseline + education")  label(3 "Baseline + education and health endowment")   region(color(none)) row(3) size(*.6) ) 
graph export "$working\\Picture_baseline_educ_educ_child_male.png", as(png) replace

corr est*
*97.01 between main and edu 
*96.69 between main and complete 

gen reduction_2 = est_edu / est_main
gen reduction_3 = est_com/est_main

su red*

**2=75.97%
**3=75.09

///Gelbach

*Step 1 - select data with full list of regressors 
					
***fait avant

use "$working\\Final_fileb_male_reduit", clear
					
*Step 2: Baseline equation 
					
use "$working\\Final_fileb_male_reduit", clear
numlabel `r(names)', add
					
reg health_wave7_dicho ib33.main_job $control, cformat(%9.3f) 

preserve
						
	parmest, norestore  list(parm estimate)
	clonevar isco = parm
	replace isco=substr(isco,1,2) if strpos(isco, "main_job")

	destring isco, force replace 
	keep if isco!=.
	keep estimate isco
	rename estimate beta_b
	sort isco
	save "$working\\beta_b.dta", replace
					
restore
										
*Step 3: Full model 

reg health_wave7_dicho   ib33.main_job ib4.education i.health_child i.death_status_father i.death_status_mother ib4.job_parent  $control , cformat(%9.3f)  
					///!!!! if we change specification, we need to change it also in the step 1
										
numlabel `r(names)', add
					
preserve
						
	parmest, norestore  list(parm estimate min95 max95 p,clean noobs)
	clonevar isco = parm
	replace isco=substr(isco,1,2) if strpos(isco, "main_job")
						
	destring isco, force replace 
	keep if isco != .
	keep estimate isco
	rename estimate beta_f
	sort isco
	save "$working\\beta_f.dta", replace

restore

*Step 4: Heterogeneity terms 
					
foreach j in education health_child death_status_father death_status_mother job_parent {
							
	qui gen `j'_hat=0

	qui levelsof `j', local(list)

	qui foreach k in  `list' {
			qui replace `j'_hat =    _b[`k'.`j'] if `j' == `k'
	}

					}
					
gen hendow_hat= health_child_hat + death_status_father_hat + death_status_mother_hat
					
*Step 5: ancillary equations 
					
					
foreach j in education hendow  job_parent {
					 
	reg `j'_hat ib33.main_job $control
					
	preserve
						
		parmest, norestore  list(parm estimate )
		clonevar isco = parm
		replace isco=substr(isco,1,2) if strpos(isco, "main_job")
						
		destring isco, force replace 
		keep if isco!=.
		keep estimate isco
		rename estimate delta_`j'
		sort isco
		save "$working//delta_`j'.dta", replace
									
	restore
					
}
					
*Step 6: Results

use beta_b , clear
					
merge 1:1 isco using beta_f,   nogen 
merge 1:1 isco using  delta_education, nogen     
merge 1:1 isco using  delta_job_parent, nogen   
merge 1:1 isco using  delta_hendow, nogen  
iscolbl isco08 isco, sub //reinject isco2 labels

order isco beta_b  delta* beta_f
					
rename (beta_f beta_b) (beta_full beta_naive) 

save, replace										
                                                                 
*Step 7 - Further decomposition 
 
global l  94                          /*choose one occupation ==> 23 Teaching professionals */

///education 

quiet {
    
use final_fileb_male_reduit, clear
 
qui reg health_wave7_dicho ib33.main_job ib4.education i.health_child i.death_status_father i.death_status_mother ib4.job_parent $control 

	forvalues i = 0/6 {
		scalar gamma_ed_`i' = _b[`i'.education]
	}
   
use final_fileb_male_reduit, clear

	forvalues i=0/6 {
	    
		gen y =(education==`i')
		reg y ib33.main_job $control
		scalar rho_ed_`i'= _b[$l.main_job]
		drop y
		
	}
	
}

///job_parent 

quiet {
    
use final_fileb_male_reduit, clear
 
qui reg health_wave7_dicho   ib33.main_job ib4.education i.health_child i.death_status_father i.death_status_mother ib4.job_parent $control 

	forvalues i = 1/7 {
		scalar gamma_jp_`i' = _b[`i'.job_parent]
	}
   
use final_fileb_male_reduit, clear

	forvalues i=1/7 {
	    
		gen y =(job_parent==`i')
		reg y ib33.main_job $control
		scalar rho_jp_`i'= _b[$l.main_job]
		drop y
		
	}
	
}

//hendrow 

quiet {
    
use final_fileb_male_reduit, clear
 
qui reg health_wave7_dicho   ib33.main_job ib4.education i.health_child i.death_status_father i.death_status_mother ib4.job_parent $control 

	forvalues i = 1/3 {
		scalar gamma_df_`i' = _b[`i'.death_status_father]
	}
	
	forvalues i = 1/3 {
		scalar gamma_dm_`i' = _b[`i'.death_status_mother]
	}
	
	forvalues i = 0/1 {
	    scalar gamma_hc_`i' = _b[`i'.health_child]
	}
	
   
use final_fileb_male_reduit, clear

	forvalues i=1/3 {
	    
		gen y =(death_status_father==`i')
		reg y ib33.main_job $control
		scalar rho_df_`i'= _b[$l.main_job]
		drop y
		
	}
	
	forvalues i=1/3 {
	    
		gen y =(death_status_mother==`i')
		reg y ib33.main_job $control
		scalar rho_dm_`i'= _b[$l.main_job]
		drop y
		
	}
	
	forvalues i=0/1 {
	    
		gen y =(health_child==`i')
		reg y ib33.main_job $control
		scalar rho_hc_`i'= _b[$l.main_job]
		drop y
		
	}
	
}

use beta_b, clear

list isco beta_* delta_edu delta_job_parent delta_hendow if  isco==$l

dis "GAMMA Impact of isced on bad health at 50+"
scalar list gamma_ed_6 gamma_ed_5 gamma_ed_4 gamma_ed_3 gamma_ed_2 gamma_ed_1 gamma_ed_0

dis "RHO propensity of occ. to be over/under exposed to different isced"
scalar list rho_ed_6 rho_ed_5 rho_ed_4 rho_ed_3 rho_ed_2 rho_ed_1 rho_ed_0

dis "GAMMA Impact of job_parent on bad health at 50+"
scalar list gamma_jp_7 gamma_jp_6 gamma_jp_5 gamma_jp_4 gamma_jp_3 gamma_jp_2 gamma_jp_1 

dis "RHO propensity of occ. to be over/under exposed to different job_parent"
scalar list rho_jp_7 rho_jp_6 rho_jp_5 rho_jp_4 rho_jp_3 rho_jp_2 rho_jp_1  

dis "GAMMA Impact of hendow on bad health at 50+"
scalar list gamma_df_3 gamma_df_2 gamma_df_1 gamma_dm_3 gamma_dm_2 gamma_dm_1 gamma_hc_0 gamma_hc_1

dis "RHO propensity of occ. to be over/under exposed to different hendow"
scalar list rho_df_3 rho_df_2 rho_df_1 rho_dm_3 rho_dm_2 rho_dm_1 rho_hc_0 rho_hc_1

*reconstruct delta_edu 
dis "delta_edu $l"  rho_ed_0*gamma_ed_0 + rho_ed_1*gamma_ed_1 + rho_ed_2*gamma_ed_2 + rho_ed_3*gamma_ed_3 + rho_ed_4*gamma_ed_4 + rho_ed_5*gamma_ed_5 + rho_ed_6*gamma_ed_6
dis "delta_jp $l"   rho_jp_1*gamma_jp_1 + rho_jp_2*gamma_jp_2 + rho_jp_3*gamma_jp_3 + rho_jp_4*gamma_jp_4 + rho_jp_5*gamma_jp_5 + rho_jp_6*gamma_jp_6  + rho_jp_7*gamma_jp_7 
dis "delta_hendow $l"   gamma_df_3 * rho_df_3 + rho_df_2 * gamma_df_2 + rho_df_1 * gamma_df_1  + rho_dm_3 * gamma_dm_3  + rho_dm_2 * gamma_dm_2 + rho_dm_1 * gamma_dm_1 + rho_hc_0 * gamma_hc_0 + rho_hc_1 * gamma_hc_1
					
///QUESTION 3: Yes, but what part of variance does it explain? 
 
///////////MALE 
 
use "$working\\Final_fileb_male_reduit", clear
levelsof country
 
reg health_wave7_dicho ib33.main_job  age   ib4.education i.health_child i.death_status_father i.death_status_mother ib4.job_parent i.country, cformat(%9.3f) coeflegend
predict phealth, xb
					 
levelsof main_job, local(jlist) clean
gen main_job_hat = 0
qui foreach j in  `jlist' {
	replace main_job_hat = _b[`j'.main_job] if main_job == `j'
}

gen education_hat = 0 
qui foreach j in 0 1 2 3 4 5 6 {
	replace education_hat = _b[`j'.education] if education == `j'
}

gen child_hat = 0
replace child_hat = _b[1.health_child] * health_child
qui foreach j in father mother {
	qui forvalues i = 1/3 {
		replace child_hat = child_hat + _b[`i'.death_status_`j'] if death_status_`j' == `i'
	}
}

gen country_hat=0
levelsof country, local(clist)
qui foreach j in  `clist' {
	replace country_hat =  _b[`j'.country] if country == `j'
}

gen job_parent_hat=0
levelsof job_parent, local(clist)
qui foreach j in  `clist' {
	replace job_parent_hat =  _b[`j'.job_parent] if job_parent == `j'
}

gen age_hat=0
replace age_hat = _b[age_int_w7] * age_int_w7
					 
corr phealth main_job_hat, cov
local s1= (r(cov_12)/r(Var_1))*100
dis "Part penib/job in model variance = "  (r(cov_12)/r(Var_1))*100 " %."
					 			 
corr phealth education_hat, cov
local s2= (r(cov_12)/r(Var_1))*100
dis "Part education in model variance = " (r(cov_12)/r(Var_1))*100 " %."

corr phealth child_hat, cov
local s3= (r(cov_12)/r(Var_1))*100
dis "Part chil/parental health in model variance = " (r(cov_12)/r(Var_1))*100 " %."

corr phealth country_hat, cov
local s4= (r(cov_12)/r(Var_1))*100
dis "Part country in model variance = " (r(cov_12)/r(Var_1))*100 " %."

corr phealth age_hat, cov
local s5= (r(cov_12)/r(Var_1))*100
dis "Part age in model variance = " (r(cov_12)/r(Var_1))*100 " %."

corr phealth job_parent_hat, cov
local s6= (r(cov_12)/r(Var_1))*100
dis "Part job_parent in model variance = " (r(cov_12)/r(Var_1))*100 " %."

dis "Check sum of parts/shares= " `s1'  + `s2' + `s3' +  `s4'  + `s5' + `s6' //exactly 100%

use "$working\\Final_fileb_male_reduit", clear

capture program drop boot

program boot, rclass
version 16
args y
confirm var `y'

tempname  phealth main_job_hat education_hat child_hat country_hat   age_hat job_parent_hat s1 s2 s3 s4 s5 s6

qui reg `y'  age_int_w7 ib33.main_job  ib4.education i.health_child i.death_status_father i.death_status_mother ib4.job_parent i.country  
qui predict `phealth', xb
					 
qui keep if `phealth' != .

qui levelsof main_job, local(jlist) clean
qui gen `main_job_hat' = 0
qui foreach j in  `jlist' {
	qui replace `main_job_hat' = _b[`j'.main_job] if main_job == `j'
}

qui gen `education_hat' = 0 
qui foreach j in 0 1 2 3 4 5 6 {
	qui replace `education_hat' = _b[`j'.education] if education == `j'
}

qui gen `child_hat' = 0
qui replace `child_hat' = _b[1.health_child] * health_child
qui foreach j in father mother {
	qui forvalues i = 1/3 {
		qui replace `child_hat' = `child_hat' + _b[`i'.death_status_`j'] if death_status_`j' == `i'
	}
}

qui gen `country_hat'=0
qui levelsof country, local(clist)
qui foreach j in  `clist' {
	qui replace `country_hat' =    _b[`j'.country] if country == `j'
}

qui gen `job_parent_hat'=0
qui levelsof job_parent, local(clist)
qui foreach j in  `clist' {
	qui replace `job_parent_hat' =    _b[`j'.job_parent] if job_parent == `j'
}

qui gen `age_hat'=0
qui replace `age_hat' = _b[age_int_w7] * age_int_w7

qui corr `phealth' `main_job_hat', cov
return scalar s1= (r(cov_12)/r(Var_1))*100
					 
qui corr `phealth' `education_hat', cov
return scalar s2 = (r(cov_12)/r(Var_1))*100
					 
qui corr `phealth' `child_hat', cov
return scalar  s3= (r(cov_12)/r(Var_1))*100
					 
qui corr `phealth' `country_hat', cov
return scalar  s4= (r(cov_12)/r(Var_1))*100
					 
qui corr `phealth' `age_hat', cov
return scalar  s5= (r(cov_12)/r(Var_1))*100
					 
qui corr `phealth' `job_parent_hat', cov
return scalar  s6= (r(cov_12)/r(Var_1))*100
					  
end 
						
bootstrap  s1=r(s1) s2=r(s2) s3=r(s3) s4=r(s4) s5= r(s5) s6=r(s6), seed(122) reps(100) nodrop mse : boot health_wave7_dicho //programme name + dependant variables
					
					 
//////////BY COUNTRY group 

use "$working\\Final_fileb_male_reduit", clear

***set on the basis of https://data.worldbank.org/indicator/NY.GDP.PCAP.CD
					 
*group "high": 11 Austria, 12 Germany, 13 Sweden, 14 Netherlands, 17 France, 18 Denmark, 20 Switzerland, 23 Belgium, 30 Ireland, 31 Luxembourg, 55 Finland, 25 Israel

*group "middle": 15 Spain, 16 Italy,   28 Czech Republic, 33 Portugal, 53 Cyprus, 59 Malta, 34 Slovenia, 35 Estonia

*group "low": 29 Poland, 32 Hungary, 47 Croatia, 48 Lithuania, 51 Bulgaria, 57 Latvia, 61 Romania, 63 Slovakia, 19 Greece 

recode country (11 12 13 14 17 18 20 23 25 30 31 55 = 1 "High") (15 16  28 33 53 59 34 35 = 2 "Middle") (29 19 32   47 48 51 57 61 63 = 3 "Low"), generate(gdp_cat)   label(country_group) 

save "$output\\Final_filec_male", replace

forvalues i = 1/3 {

	use "$output\\Final_filec_male", clear

	drop if gdp_cat != `i'
	bootstrap  s1=r(s1) s2=r(s2) s3=r(s3) s4=r(s4) s5= r(s5) s6=r(s6), seed(122) reps(100) nodrop mse : boot health_wave7_dicho //programme name + dependant variables

	sleep 10000
}

use "$output\\Final_filec_male", clear

drop if main_job == 94
capture program drop bootgdp
	program bootgdp, rclass
	version 16
	args y
	confirm var `y'

	//Corr
	local x 1 2 3  // gdp_cat

	foreach k in `x' {
						 
		tempname  phealth main_job_hat s`k'  // very important to "store" interm. results in temp.var 
		//Tempvar
		qui reg `y'   age_int_w7 ib33.main_job  ib4.education i.health_child i.death_status_father i.death_status_mother i.country ib4.job_parent if gdp_cat==`k'
		predict `phealth', xb
						
		levelsof main_job if gdp_cat==`k', local(jlist) clean
		gen `main_job_hat' = 0
		qui foreach j in  `jlist' {
			replace `main_job_hat' = _b[`j'.main_job] if main_job == `j' & gdp_cat == `k'
		}

		corr `phealth' `main_job_hat' if gdp_cat == `k' , cov
		scalar `s`k''= 100*[r(cov_12)/r(Var_1)]
		return scalar s`k'= 100*[r(cov_12)/r(Var_1)] //Share to attribute to main occ. (Export of scalars to be boostrapped )
	}

	*restore 
		
	//Export of scalars to be boostrapped  

	tempname   diff12_   diff23_  diff13_
	return scalar diff12_=  `s1'  - `s2' //Diff between [gpd_cat] 1 et 2 Export of scalars to be boostrapped  
	return scalar diff23_= `s2' - `s3' //Diff between [gpd_cat] 2 et 3
	return scalar diff13_= `s1' - `s3' //Diff between [gpd_cat] 1 et 3
						
	end	

					 
bootstrap  s1=r(s1) s2=r(s2) s3=r(s3)  ///
diff12_=r(diff12_) diff23_=r(diff23_) diff13_=r(diff13_) , ///
seed(122) reps(100) nodrop mse : bootgdp health_wave7_dicho //programme name + dependant variables

		 
////////////////////////////////////////////////////////////////////////////////

									ROBUSTNESS TEST 

////////////////////////////////////////////////////////////////////////////////

//////////////MALE

*Robustness test 1: avec les - de 70 *************************************

use "$working\\Final_fileb_male_reduit", clear

drop if age>70

save "$output\\Final_fileb70_male", replace 

use "$output\\Final_fileb70_male", clear

reg health_wave7_dicho    age_int_w7 ib33.main_job  ib4.education i.health_child i.death_status_father ib4.job_parent i.death_status_mother i.country, cformat(%9.3f) 
						 
capture program drop boot
program boot, rclass
	version 16
	args y
	confirm var `y'

	tempname  phealth main_job_hat education_hat child_hat country_hat   age_hat job_parent_hat s1 s2 s3 s4 s5 s6

	qui reg `y'    age_int_w7 ib33.main_job  ib4.education i.health_child i.death_status_father ib4.job_parent i.death_status_mother i.country  
	qui predict `phealth', xb
						 
	qui keep if `phealth' != .

	qui levelsof main_job, local(jlist) clean
	qui gen `main_job_hat' = 0
	qui foreach j in  `jlist' {
		qui replace `main_job_hat' = _b[`j'.main_job] if main_job == `j'
	}

	qui gen `education_hat' = 0 
	qui foreach j in 0 1 2 3 4 5 6 {
		qui replace `education_hat' = _b[`j'.education] if education == `j'
	}

	qui gen `child_hat' = 0
	qui replace `child_hat' = _b[1.health_child] * health_child
	qui foreach j in father mother {
		qui forvalues i = 1/3 {
			qui replace `child_hat' = `child_hat' + _b[`i'.death_status_`j'] if death_status_`j' == `i'
		}
	}

	qui gen `country_hat'=0
	qui levelsof country, local(clist)
	qui foreach j in  `clist' {
		qui replace `country_hat' =    _b[`j'.country] if country == `j'
	}

	qui gen `job_parent_hat'=0
	qui levelsof job_parent, local(clist)
	qui foreach j in  `clist' {
		qui replace `job_parent_hat' =    _b[`j'.job_parent] if job_parent == `j'
	}

	qui gen `age_hat'=0
	qui replace `age_hat' = _b[age_int_w7] * age_int_w7
						 
	qui corr `phealth' `main_job_hat', cov
	return scalar s1= (r(cov_12)/r(Var_1))*100
							 
	qui corr `phealth' `education_hat', cov
	return scalar s2 = (r(cov_12)/r(Var_1))*100
						 
	qui corr `phealth' `child_hat', cov
	return scalar  s3= (r(cov_12)/r(Var_1))*100
						 
	qui corr `phealth' `country_hat', cov
	return scalar  s4= (r(cov_12)/r(Var_1))*100
							 
	qui corr `phealth' `age_hat', cov
	return scalar  s5= (r(cov_12)/r(Var_1))*100
						 
	qui corr `phealth' `job_parent_hat', cov
	return scalar  s6= (r(cov_12)/r(Var_1))*100
						  
end 

bootstrap  s1=r(s1) s2=r(s2) s3=r(s3) s4=r(s4) s5= r(s5) s6=r(s6), seed(122) reps(100) nodrop mse : boot health_wave7_dicho //programme name + dependant variables
	 
*Robustness test 2: avec une autre variable ***********************

//////////////MALE

use "$working\\Final_fileb_male_reduit", clear

gen robu = .
replace robu = 0 if physical_health_sub <= 0
replace robu = 1 if physical_health_subjective > 0 

save "$output\\Final_filebr_male", replace


use "$output\\Final_filebr_male", clear

reg robu   age ib33.main_job  ib4.education health_child i.death_status_father i.death_status_mother i.country ib4.job_parent, cformat(%9.3f)
								
use "$output\\Final_filebr_male", clear

capture program drop boot

program boot, rclass
	version 16
	args y
	confirm var `y'

	tempname  phealth main_job_hat education_hat child_hat country_hat   age_hat job_parent_hat s1 s2 s3 s4 s5 s6

	qui reg `y'  ib4.job_parent age_int_w7 ib33.main_job  ib4.education i.health_child i.death_status_father i.death_status_mother i.country  
	qui predict `phealth', xb
							 
	qui keep if `phealth' != .

	qui levelsof main_job, local(jlist) clean
	qui gen `main_job_hat' = 0
	qui foreach j in  `jlist' {
		qui replace `main_job_hat' = _b[`j'.main_job] if main_job == `j'
	}

	qui gen `education_hat' = 0 
	qui foreach j in 0 1 2 3 4 5 6 {
		qui replace `education_hat' = _b[`j'.education] if education == `j'
	}

	qui gen `child_hat' = 0
	qui replace `child_hat' = _b[1.health_child] * health_child
	qui foreach j in father mother {
		qui forvalues i = 1/3 {
			qui replace `child_hat' = `child_hat' + _b[`i'.death_status_`j'] if death_status_`j' == `i'
		}
	}

	qui gen `country_hat'=0
	qui levelsof country, local(clist)
	qui foreach j in  `clist' {
		qui replace `country_hat' =    _b[`j'.country] if country == `j'
	}

	qui gen `age_hat'=0
	qui replace `age_hat' = _b[age_int_w7] * age_int_w7

	qui gen `job_parent_hat'=0
	qui levelsof job_parent, local(clist)
	qui foreach j in  `clist' {
		qui replace `job_parent_hat' =    _b[`j'.job_parent] if job_parent == `j'
	}
							 
	qui corr `phealth' `main_job_hat', cov
	return scalar s1= (r(cov_12)/r(Var_1))*100
							 
	qui corr `phealth' `education_hat', cov
	return scalar s2 = (r(cov_12)/r(Var_1))*100
						 
	qui corr `phealth' `child_hat', cov
	return scalar  s3= (r(cov_12)/r(Var_1))*100
							 
	qui corr `phealth' `country_hat', cov
	return scalar  s4= (r(cov_12)/r(Var_1))*100
							 
	qui corr `phealth' `age_hat', cov
	return scalar  s5= (r(cov_12)/r(Var_1))*100
							 
	qui corr `phealth' `job_parent_hat', cov
	return scalar  s6= (r(cov_12)/r(Var_1))*100
						  
end 		


bootstrap  s1=r(s1) s2=r(s2) s3=r(s3) s4=r(s4) s5= r(s5) s6=r(s6), seed(122) reps(100) nodrop mse: boot robu

*********************************************************************************
*																				*
*					***END OF CODE FOR THE ANALYSIS OF THE PAPER***				*
*																				*	
*********************************************************************************