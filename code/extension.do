/****************************************************************************** 
* Stata program: 	extension_data_create
* --------------
*
* Author: 			Tate Mason, UNCC, dmason27@uncc.edu
* -------
*
* Date: 			02/25/2024 
* -----
*
******************************************************************************/
	
	/*****************************************************************
	* (1) Setup basic stata environment variables
	*****************************************************************/

		#delimit cr 		// make carriage return the command delimiter
		clear				//clear data in memory
		clear all			//clear all variables in memory
		set more off		//turn the "more" option for screen output off

		local rootPath "/Users/tate/Library/CloudStorage/Dropbox/Schoolwork/RM/"
		
		local codePath "`rootPath'/code/"
		local dataPath "`rootPath'/Data/RM2-Data/"
		local outputPath "`rootPath'/Output/"
		
		
		
		//local rawDataPath "/Volumes/Elements/data/Census"
		

		set scheme s1color
		cap log close
		//log using `outputPath'extension_data_create.txt, replace
	
	
		
	/*****************************************************************
	* (1) Prepare and collapse IPUMS-USA Data
	*****************************************************************/
		
			
		local readRaw 0
		if `readRaw' {
		
			use `dataPath'/usa_00035.dta, clear //with education and occ
			keep if inlist(gq,1,2,5) //drop peopel in group quarters
			
			/*
			INCTOT Specific Variable Codes 
			-009995 = -$9,900 (1980) 
			-000001 = Net loss (1950) 
			0000000 = None 
			0000001 = $1 or break even (2000, 2005-onward ACS and PRCS) 
			9999999 = N/A
			
			*/
			
			local vars "inctot"
			foreach v of local vars {
				replace `v' = . if inlist(`v',-009995,-000001,0000001,0000000,9999999)
			}
			
			/*
			//deal with top coded values
			//use David Autor's method from: Trends in U.S. Wage Inequality: Revising the Revisionists
			David H. Autor, Lawrence F. Katz and Melissa S. Kearney
			Review of Economics and Statistics, May 2008.
			
			
				INCTOT
				Census	Bottom Code	Top Code
				1950	Net loss	$10,000
				1960	-$9,900	$25,000
				1970	-$9,900	$50,000
				1980	-$9,990	$75,000
				
				1990	-$19,998	 $400,000* //already corrected
				
				2000	-$20,000	$999,998
				ACS	-$19,998	-
				PRCS	-$19,998	-

			
			*/
			
			/*
			INCWAGE Specific Variable Codes 
			999999 = N/A 
			999998 = Missing
			*/
			
			
			local vars "incwage"
			foreach v of local vars {
				replace `v' = . if inlist(`v',999999,999998)
			}
			
			/*	
			
			//deal with top coded values
				//use David Autor's method from: Trends in U.S. Wage Inequality: Revising the Revisionists
				David H. Autor, Lawrence F. Katz and Melissa S. Kearney
				Review of Economics and Statistics, May 2008.
				
				They windsorize by multiplying by 1.5
			
				INCWAGE
				Census	Top Code
				1940	$5,001
				1950	$10,000
				1960	$25,000
				1970	$50,000
				1980	$75,000
				
				1990	 $140,000*
				2000	  $175,000**
				ACS (2000-2002)	  $200,000**
				ACS (2003-onward)	 99.5th Percentile in State**
				 PRCS (2005-onward)	 99.5th Percentile in State**
			
			*/
			
			/*
			FTOTINC Specific Variable Codes 
			-000001 = Net loss (1950) 
			0000000 = No income (1950-2000, ACS/PRCS) 
			9999998 = Not ascertained (1950) 
			9999999 = N/A
			*/
			
			local vars "ftotinc"
			foreach v of local vars {
				replace `v' = . if inlist(`v',-000001,0000000,9999998,9999999)
			
			}
			
					
			
			/*
			INCOTHER Specific Variable Codes 
			-0001 = Net loss (1950) 
			99999 = N/A
			
			*/
			
			local vars "incother"
			foreach v of local vars {
				replace `v' = . if inlist(`v',-0001,99999)
			}
			
			/*****************************************************************
			* Business/Farm Income: This is income from non-incorporated
			* business activities. This includes "self employemnt". If the
			* business is incorporated, then the income is supposed to be
			* counted in incwage, even if the person has an ownership stake.
			*****************************************************************/
			
			
				/*
				INCBUS Specific Variable Codes 
				-09995 = -$9,900 (1970) 
				999999 = N/A
				
				*/
				
				local vars "incbus"
				foreach v of local vars {
					replace `v' = . if inlist(`v',-09995,999999)
				}
				
			
				/*
				INCBUSFM Specific Variable Codes 
				-0001 = Net loss (1950) 
				99999 = N/A
				*/
				
				local vars "incbusfm"
				foreach v of local vars {
					replace `v' = . if inlist(`v',-0001,99999)
				}
				
				/*
				INCFARM Specific Variable Codes 
				-09995 = -$9,990 (1980) 
				999999 = N/A
				*/
				
				local vars "incfarm"
				foreach v of local vars {
					replace `v' = . if inlist(`v',-09995,999999)
				}
				
				/*
				INCBUS00 Specific Variable Codes 
				000001 = $1 or break even (2000, 2005-2007 ACS) 
				999999 = N/A
				*/
				
				local vars "incbus00"
				foreach v of local vars {
					replace `v' = . if inlist(`v',999999)
				}
				
				/*****************************************************************
				* Harmonized business/farm income variable
				* See: https://usa.ipums.org/usa-action/variables/INCTOT#comparability_section
				*****************************************************************/
					
					local vars "incbus incbusfm incfarm incbus00"
					
					foreach v of local vars {
						
						rename `v' raw_`v'
						
					}
							
					gen incbus = . 
					label variable incbus "Harmonized Business/Farm Income"
						
					replace incbus = raw_incbusfm if inlist(year,1950,1960)
					replace incbus = raw_incbus+raw_incfarm if inlist(year,1970,1980,1990)
					replace incbus = raw_incbus00 if year>=2000
				
					
					
			/*****************************************************************
			* Transfers
			*****************************************************************/
			
			
				/*
				INCWELFR Specific Variable Codes 
				99999 = N/A
				*/
				
				local vars "incwelfr"
				foreach v of local vars {
					replace `v' = . if inlist(`v',99999)
				}
				
				/*
				INCSUPP Specific Variable Codes 
				99999 = N/A
				*/
				local vars "incsupp"
				foreach v of local vars {
					replace `v' = . if inlist(`v',99999)
				}
			
			/*****************************************************************
			* Investment Income
			*****************************************************************/
			
			
				/*
				INCINVST Specific Variable Codes 
				-09995 = -$9,990 (1980) 
				000001 = $1 or break even (1990, 2000, ACS, PRCS) 
				999999 = N/A
				*/
				
				local vars "incinvst"
				foreach v of local vars {
					replace `v' = . if inlist(`v',-09995,999999)
				}
			
			/*****************************************************************
			* Retirement Income
			*****************************************************************/
			
				/*
				INCSS Specific Variable Codes 
				99999 = N/A
				*/	
				
				local vars "incss"
				foreach v of local vars {
					replace `v' = . if inlist(`v',99999)
				}
				
				/*
				INCRETIR Specific Variable Codes 
				999999 = N/A
				*/
				
				local vars "incretir"
				foreach v of local vars {
					replace `v' = . if inlist(`v',99999)
				}
			
			//income not from wages or business
			
				rename incother raw_incother
				
				gen incother = inctot - incwage - incbus
				label variable incother "Income not from wages or business/farm"
			
			
			/*****************************************************************
			* House Values
			*****************************************************************/
			
			
				/*
				VALUEH Specific Variable Codes 
				0000000 = N/A (1930) 
				9999998 = Missing (1940 100%) 
				9999999 = Missing (1930), N/A (1940-2000, ACS, and PRCS)
				*/	
				
				local vars "valueh"
				foreach v of local vars {
					replace `v' = . if inlist(`v',9999998,9999999,0000000)
				}
			
			
			/*****************************************************************
			* Rent
			*****************************************************************/
			
			
				/*
				RENT Specific Variable Codes 
				0000 = N/A 
				0001 = No cash rent (1980-1990) 
				9998 = Missing (1940) 
				9999 = No cash rent (1940)
				*/	
				
				local vars "rent"
				foreach v of local vars {
					replace `v' = . if inlist(`v',0000,0001,9998,9999)
				}
				
				
			
			/*****************************************************************
			* Demographic variables
			*****************************************************************/
			
				//race
				recode race (4/6=1) (1/3 7/9=0), gen(asian)
				
				recode raced (400/420=1) (100/399 500/997=0), gen(chinese)
				
				recode raced (600=1) (100/500 610/997=0), gen(filipino)
				
				recode raced (610=1) (100/600 620/997=0), gen(indian)
				
				recode raced (620=1) (100/610 630/997=0), gen(korean)
				
				recode raced (640=1) (100/630 641/997=0), gen(vietnamese)
				
				recode raced(500=1) (100/420 600/997=0), gen(japanese)
				
				recode race(2=1) (1 3/9=0), gen(black)
				
				//renter/owner
				gen renter = 0
				replace renter = 1 if inlist(ownershpd,21,22)
				
				//variables that we'll keep only for the head
				replace metarea = met2013 if year > 2011
					local head_vars "renter rent rentgrs valueh age chinese japanese filipino indian korean vietnamese asian black educ occ1990 ind1990 statefip metro metarea farm hhtype sex builtyr builtyr2 bedrooms"
					//Have been including the statefip and metarea variables as they are in the control vector. Unsure how to collapse to use them and make the code work.//
					replace metarea = met2013 if year > 2011
					foreach v of local head_vars {
						
						replace `v' = . if pernum!=1 //only keep data for household head
					}
				
				
			/*****************************************************************
			* Collpase to Household
			* For demographics, we take the head's characteristics
			*****************************************************************/
				
				collapse (first) `head_vars' (sum) inc* , by(year serial hhwt)
				
				keep if inctot>0 //only keep households with positive income
				keep if year>=1940 //no house values/rents in 1950
				
				replace rent = . if !renter //rent only for renters
				//replace rent = . if rent<=0 //rent only if >0
				
				replace rentgrs = . if !renter //rent only for renters
				//replace rentgrs = . if rentgrs<=0 //rent only if >0
				
				replace valueh = . if renter //house value only if not renter
				//replace valueh = . if valueh<=0 //house value only if >0
								
				//keep if inlist(year,1960, 2019)
				
				save `dataPath'IPUMS-USA_Extension.dta, replace
				
		}
					
	/*****************************************************************
	* (3) Create variables for plots
	*****************************************************************/
			
			use `dataPath'IPUMS-USA_Extension, clear
			
			keep if inlist(year,1980, 2019)
			
			gen rent_inc = 100*rentgrs/(inctot/12) if inctot>0
			gen hval_inc = valueh/(inctot/12) if inctot>0
			
			//windsorize ratios (drop below 5th and above 95th percentile)
				local vars "rent_inc hval_inc"
				winsor2 `vars' , by(year) cuts(5 95) replace
				
			
				
			//trim income for plots
				winsor2 inctot , by(year) suffix(_trimmed) cuts(1 99)
				sum incot*
				replace inctot_trimmed = . if inctot_trimmed != inctot
				
			//fraction of owners
			gen own100 = 100*(1-renter)
			
			
			by year: sum  inctot* rent rentgrs rent_* own* hval* valueh
			
	/*****************************************************************
	* (4) Plot Graphs
	*****************************************************************/
		
		local rootPath "/Users/tate/Library/CloudStorage/Dropbox/Schoolwork/RM/"
		
		local codePath "`rootPath'/code/"
		local dataPath "`rootPath'/Data/"
		local outputPath "`rootPath'/RM2/RM2-Output/"
		
		label variable rent_inc "Rent/Income (%)"
		label variable hval_inc "House Value/Income (%)"
		label variable own100 "Ownership Rate (%)"
		label variable inctot_trimmed "Household Income (trimmed)"
		
		graph drop _all
		local nq=30
		local years "1980 2019"
		local races "asian chinese japanese korean indian vietnamese filipino black"
		
	foreach r of local races {
		foreach y of local years {
			
			#delimit ;
			binscatter rent_inc inctot_trimmed if year==`y' & renter==1 [aw=hhwt],
			by(`r')
			n(`nq')
			linetype(none)
			name(`r'_rent_inc`y')
			title("`y' Rent/Income Ratio")
			xtitle("Income")
			ytitle("Rent-to-income(%)")
			legend(ring(0) pos(1) col(1))
			;
			#delimit cr
			graph export `outputPath'`r'_extend_rentsumm`y'.pdf, as(pdf) replace name(`r'_rent_inc`y')
			
			#delimit ;
			binscatter hval_inc inctot_trimmed if year==`y' & renter==0 [aw=hhwt],
			by(`r')
			n(`nq')
			linetype(none)
			name(`r'_hval_inc`y')
			title("`y' House Value/Income")
			xtitle("Income")
			ytitle("Value-to-income Ratio")
			legend(ring(0) pos(1) col(1))
			;
			#delimit cr
			graph export `outputPath'`r'_extend_valuesumm`y'.pdf, as(pdf) replace name(`r'_hval_inc`y')
			
			#delimit ;
			binscatter own100 inctot_trimmed if year==`y' [aw=hhwt],
			by(`r')
			n(`nq')
			linetype(none)
			name(`r'_owner`y')
			title("`y' Ownership Rate")
			xtitle("Income")
			ytitle("Ownership rate")
			legend(ring(0) pos(1) col(1))
			;
			#delimit cr
			graph export `outputPath'`r'_extend_ownsumm`y'.pdf, as(pdf) replace name(`r'_owner`y') 
		}
	}
		
		
		
	/*****************************************************************
	* End of file
	*****************************************************************/
	
