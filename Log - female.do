
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

///Gelbach

*Step 1 - select data with full list of regressors 
					
***fait avant

use "$working\\Final_fileb_male_reduit", clear
					
*Step 2: Baseline equation
					
use "$working\\Final_fileb_female_reduit", clear
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

reg health_wave7_dicho   ib33.main_job ib4.education i.health_child i.death_status_father i.death_status_mother ib4.job_parent  $control , cformat(%9.3f)  ///!!!! if we change specification, we need to change it also in the step 1
										
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
*****creation du log file

log using Female, text  replace

foreach j in 11 12 13 14 21 22 23 24 25 26 31 32 33 34 35 41 42 43 44 51 52 53 54 61 62 63 71 72 73 74 75 81 83 91 92 93 94 96 99 {
																	 
	*Step 7 - Further decomposition 
	 
	global l `j'                          /*choose one occupation ==> 23 Teaching professionals */

	///education 

	quiet {
		
	use final_fileb_female_reduit, clear
	 
	qui reg health_wave7_dicho ib33.main_job ib4.education i.health_child i.death_status_father i.death_status_mother ib4.job_parent $control 

		forvalues i = 0/6 {
			scalar gamma_ed_`i' = _b[`i'.education]
		}
	   
	use final_fileb_female_reduit, clear

		forvalues i=0/6 {
			
			gen y =(education==`i')
			reg y ib33.main_job $control
			scalar rho_ed_`i'= _b[$l.main_job]
			drop y
			
		}
		
	}

	///job_parent 

	quiet {
		
	use final_fileb_female_reduit, clear
	 
	qui reg health_wave7_dicho   ib33.main_job ib4.education i.health_child i.death_status_father i.death_status_mother ib4.job_parent $control 

		forvalues i = 1/7 {
			scalar gamma_jp_`i' = _b[`i'.job_parent]
		}
	   
	use final_fileb_female_reduit, clear

		forvalues i=1/7 {
			
			gen y =(job_parent==`i')
			reg y ib33.main_job $control
			scalar rho_jp_`i'= _b[$l.main_job]
			drop y
			
		}
		
	}

	//hendrow 

	quiet {
		
	use final_fileb_female_reduit, clear
	 
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
		
	   
	use final_fileb_female_reduit, clear

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

	}
	
log close