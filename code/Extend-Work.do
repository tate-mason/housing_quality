/*********************************
* Tate Mason                     *
* UNC Charlotte                  *
* Extend-Work.do                 *
*********************************/

/********************************
* 1. Environment Setup          *
********************************/
	#delimit cr 		
	clear				
	clear all			
	set more off	
	
	set scheme white_tableau
	
	//Data Paths
	
	local data "/Users/tate/Library/CloudStorage/Dropbox/Schoolwork/RM/Data/RM2-Data"
	local output "/Users/tate/Library/CloudStorage/Dropbox/Schoolwork/RM/RM2/RM2-Output"
	
	log using `output'/RM2_output, replace
	
	local prepRaw = 0
	local prepDec = 0
	local prepDummies = 0
	local prepDecDummies = 0
	local gapReg = 0
	local doGraph = 0
	local gapGraph = 0
	local tabReg = 1
	local bwReg	= 0
	
/********************************
* 2. Data Setup (Percentiles)   *
********************************/
	if `prepRaw' {
			
			use `data'/IPUMS-USA_Extension-correct.dta, clear
			
			keep if inlist(year,1980,1990,2000,2010,2019)
		
			gen rent_inc = 100*rentgrs/(inctot/12) if inctot>0
			gen hval_inc = valueh/(inctot/12) if inctot>0
			
			
			gen inc_month = inctot/12
			gen own100 = 100*(1-renter)
			
			//compute percentiles
			local vars "rentgrs valueh own100 inc_month"
			
			levelsof year, local(years)
			
			foreach v of local vars {
				di "computing percentiles for `v'..."
				gen pctr_`v'=.
				foreach y of local years {
					di "    year=`y'..."
					xtile pctr_`v'_`y' = `v' [aw=hhwt] if year==`y', nq(100)
					replace pctr_`v'=pctr_`v'_`y' if year==`y'
				}
				
				
			}
			
		
			
			save "`data'/fig2data.dta", replace
		
		}
/********************************
* 2. Data Setup (Deciles)       *
********************************/
	if `prepDec' {
		
		use `data'/IPUMS-USA_Extension-correct.dta, clear
			
			keep if inlist(year,1980,1990,2000,2010,2019)
			
			
		
			gen rent_inc = 100*rentgrs/(inctot/12) if inctot>0
			gen hval_inc = valueh/(inctot/12) if inctot>0
			
			
			gen inc_month = inctot/12
			gen own100 = 100*(1-renter)
		
			//compute deciles	
			local vars "rentgrs valueh own100 inc_month"
			
			levelsof year, local(years)
			
			foreach v of local vars {
				di "computing deciles for `v'..."
				gen dec_`v'=.
				foreach y of local years {
					di "    year=`y'..."
					xtile dec_`v'_`y' = `v' [aw=hhwt] if year==`y', nq(10)
					replace dec_`v'=dec_`v'_`y' if year==`y'
				}
				
				
			}
			
			
			save "`data'/tab1data.dta", replace
	}
/********************************
* 3. Prep Dummies (Percentiles) *
********************************/		
		
if `prepDummies' {
		
		use "`data'/fig2data.dta", clear
		
		
		local races "asian chinese japanese korean vietnamese filipino indian black"
			levelsof pctr_inc_month, local(ps)
			foreach p of local ps {
				 
				di "p=`p'"
				//generate dummy for income ranks
					gen _incr_p`p' = 0 if pctr_inc_month!=.
					replace _incr_p`p' = 1 if pctr_inc_month==`p'
				foreach r of local races {
					di "race=`r'..."
				//generate interaction with race
					gen _ia_`r'_incr_p`p' = `r'*_incr_p`p'
				
				
				}
		
			}
			
			
			save "`data'/fig2_reg_data.dta", replace
			
		}
/********************************
* 3. Prep Dummies (Deciles)     *
********************************/		
		
if `prepDecDummies' {
		
		use "`data'/tab1data.dta", clear
		
			local races "asian chinese japanese korean vietnamese filipino indian black"
		
			levelsof dec_inc_month, local(ds)
			foreach d of local ds {
				 
				di "d=`d'"
				//generate dummy for income ranks
					gen _incr_d`d' = 0 if dec_inc_month!=.
					replace _incr_d`d' = 1 if dec_inc_month==`d'
				foreach r of local races {
					di "race =`r'"
				//generate interaction with asian
					gen _ia_`r'_incr_d`d' = `r'*_incr_d`d'
				
				}
			}
			
			
			save "`data'/tab1_reg_data.dta", replace
			
		}
		

/********************************
* 4. Gap Regressions            *
********************************/
if `gapReg'{
		use `data'/fig2_reg_data.dta
		local races "asian chinese japanese korean vietnamese filipino indian black"
		foreach r of local races {
		//create interactions
			gen _ia_`r'_y = `r'*pctr_inc_month
		
		//run regression for each year and outcome
			
			
			local vars "rentgrs valueh own100"
			local controls "educ age sex hhtype farm metarea statefip"
			local years "1980,1990,2000,2010,2019"
			
			sum `controls'
		
			replace pctr_own100=own100 //this one is a linear probability model (no rank necessary)
			levelsof year, local(years) //grab available years
			foreach v of local vars {
				gen `r'_rgap_`v'_p25=.
				gen `r'_rgap_`v'_p50=.
				gen `r'_rgap_`v'_p75=.
				foreach y of local years {
			
					//run parametric regression (linear in income rank)
						reg pctr_`v' pctr_inc_month `r' _ia_`r'_y `controls' [aw=hhwt] if year==`y', 
					
					//predice race gap at various income ranks
						replace `r'_rgap_`v'_p25 = _b[`r'] + _b[_ia_`r'_y]*25 if year==`y'
						replace `r'_rgap_`v'_p50 = _b[`r'] + _b[_ia_`r'_y]*50 if year==`y'
						replace `r'_rgap_`v'_p75 = _b[`r'] + _b[_ia_`r'_y]*75 if year==`y'
				}
				
			}
		}
					save `data'/graph.dta, replace
	}	
/********************************
* 5. Graphing                   *
********************************/	
if `doGraph' {
		use `data'/graph.dta, clear
		local races "asian chinese japanese korean vietnamese filipino indian black"
		foreach r of local races {
			preserve
			//collapse saved coefficients by year
				collapse `r'_rgap*, by(year)
		
			//plot saved coefficients
				tsset year
			
			
				graph drop _all
		
				local vars "rentgrs valueh own100"
				foreach v of local vars {
				
					if "`v'"=="rentgrs" {
						local ylab "`r'/Non-`r' Rent Rank Gap"
					}
					else if "`v'"=="valueh" {
						local ylab "`r'/Non-`r' House Price Rank Gap"
					}
					else if "`v'"=="own100" {
						local ylab "`r'/Non-`r' Ownership Gap (perc. pt.)"
					}
				
				#delimit ;
					tsline `r'_rgap_`v'_p25 `r'_rgap_`v'_p50 `r'_rgap_`v'_p75,
				
					lwidth(thin thick thin)
					lpattern(dash solid solid)
				
					legend(ring(0) pos(5) col(1) region(style(none)) order(1 "25-th Perc. Inc. Rank" 2 "50-th Perc. Inc. Rank" 3 "75-th Perc. Inc. Rank"))
				
					xlabel(1980(10)2020, grid gstyle(major) glstyle(dot) glcolor(black) glwidth(small))
					ylabel(-20(5)20, grid gstyle(major) glstyle(dot) glcolor(black) glwidth(small))
					yline(0,lcolor(black) lwidth(thin))
				
					ytitle("`ylab'")
					xtitle("Year")
				
				
					name(`r'_`v')
				
					;
				#delimit cr
					graph export "`output'/`r'_extended_rgap_`v'.pdf", as(pdf) name(`r'_`v') replace
				}
				restore
			}
		}

/********************************
* 1980 Gap Graphics             *
********************************/
	if `gapGraph' { 
		use `data'/IPUMS-USA_Extension-correct.dta, clear
		
		local races "asian chinese japanese korean vietnamese indian filipino black"
		foreach r of local races{
			preserve
				drop if year!=1980
				
				gen rent_inc = 100*rentgrs/(inctot/12) if inctot>0
				gen hval_inc = valueh/(inctot/12) if inctot>0
			
				xtile rentp = rentgrs [aw=hhwt], nq(100)
				xtile valuep = valueh [aw=hhwt], nq(100)
				xtile incp = inctot [aw=hhwt], nq(100)
				
				gen `r'_b = incp if `r'==1
				
				reg rentp i.`r'_b
				
				//2a, 2c, 2e
				
				#delimit ;
				binscatter rentp incp [aw=hhwt],
				by(`r') nq(50)
				linetype(qfit)
				name(`r'_Fig2a,replace)
				title("Rent Rank Gap in 1980")
				ytitle("Rent Rank")
				xtitle("Income Rank")
				legend(ring(0) pos(1) col(1))
				;
				#delimit cr
				graph export `output'/`r'_2a.pdf, as(pdf) name(`r'_Fig2a) replace
				
				#delimit
				binscatter valuep incp [aw=hhwt],
				by(`r') nq(50)
				linetype(qfit)
				name(`r'_Fig2c,replace)
				title("House Price Rank Gap in 1980")
				ytitle("Price Rank")
				xtitle("Income Rank")
				legend (ring(0) pos(1) col(1))
				;
				#delimit cr
				graph export `output'/`r'_2c.pdf, as(pdf) name(`r'_Fig2c) replace
				
				gen own100 = 100*(1-renter)
				
				#delimit ;
				binscatter own100 incp [aw=hhwt],
				by(`r') nq(50)
				linetype(qfit)
				name(`r'_Fig2e,replace)
				title("Ownership Rate Gaps in 1980")
				ytitle("Ownership Rate")
				xtitle("Income Rank")
				legend (ring(0) pos(1) col(1))
				;
				#delimit cr
				graph export `output'/`r'_2e.pdf, as(pdf) name(`r'_Fig2e) replace
			restore	
		}
	}		
/********************************
* Table 1 Regressions           *
********************************/
	if `tabReg' {		
		clear
		use `data'/tab1_reg_data.dta
				
		drop _incr_d1
		
		//by year: summ newrooms yrbuilt black _incr_d* educ age sex hhtype farm metro statefip
		
		/*local controls "educ age sex hhtype farm metro statefip"
		local early "1970"
		foreach e of local early {
			di "Year = `e'"
			reg yrbuilt black _incr_d* `controls' if year==`e'
			reg newrooms black _incr_d* `controls' if year==`e'
		}*/
		
		
		local races "asian chinese japanese korean vietnamese filipino indian black"
		local controls2 "educ age sex hhtype farm metro metarea statefip"
		local years "1980 1990 2000 2010 2019"
		foreach r of local races {
			foreach y of local years {
				di "Year = `y'"
				reg yrbuilt `r' _incr_d* `controls2' if year==`y'
				reg newrooms `r' _incr_d* `controls2' if year==`y'
			}
		}
	}

/********************************
* Between Race Regressions      *
********************************/	
	if `bwReg' {
		clear
		use `data'/tab1_reg_data.dta
		
		drop _incr_d1
		
		local races "asian chinese japanese korean vietnamese filipino indian black"
		local controls2 "educ age sex hhtype farm metro metarea statefip"
		local years "1980 1990 2000 2010 2019"
		foreach r of local races {
			foreach y of local years {
				di "Year = `y'"
				reg yrbuilt asian _incr_d* `controls2' if year==`y' & asian==1 | `r'== 1
				reg newrooms asian _incr_d* `controls2' if year==`y' & asian==1 | `r'== 1
			}
		}
		foreach r of local races {
			foreach y of local years {
				di "Year = `y'"
				reg yrbuilt chinese _incr_d* `controls2' if year==`y' & chinese==1 | `r'== 1
				reg newrooms chinese _incr_d* `controls2' if year==`y' & chinese==1 | `r'== 1
			}
		}
		foreach r of local races {
			foreach y of local years {
				di "Year = `y'"
				reg yrbuilt `r' _incr_d* `controls2' if year==`y' & japanese==1 | `r'== 1
				reg newrooms `r' _incr_d* `controls2' if year==`y' & japanese==1 | `r'== 1
			}
		}
		foreach r of local races {
			foreach y of local years {
				di "Year = `y'"
				reg yrbuilt korean _incr_d* `controls2' if year==`y' & korean==1 | `r'== 1
				reg newrooms korean _incr_d* `controls2' if year==`y' & korean==1 | `r'== 1
			}
		}
		foreach r of local races {
			foreach y of local years {
				di "Year = `y'"
				reg yrbuilt vietnamese _incr_d* `controls2' if year==`y' & vietnamese==1 | `r'== 1
				reg newrooms vietnamese _incr_d* `controls2' if year==`y' & vietnamese==1 | `r'== 1
			}
		}
		foreach r of local races {
			foreach y of local years {
				di "Year = `y'"
				reg yrbuilt filipino _incr_d* `controls2' if year==`y' & filipino==1 | `r'== 1
				reg newrooms filipino _incr_d* `controls2' if year==`y' & filipino==1 | `r'== 1
			}
		}
		foreach r of local races {
			foreach y of local years {
				di "Year = `y'"
				reg yrbuilt indian _incr_d* `controls2' if year==`y' & indian==1 | `r'== 1
				reg newrooms indian _incr_d* `controls2' if year==`y' & indian==1 | `r'== 1
			}
		}
		foreach r of local races {
			foreach y of local years {
				di "Year = `y'"
				reg yrbuilt black _incr_d* `controls2' if year==`y' & black==1 | `r'== 1
				reg newrooms black _incr_d* `controls2' if year==`y' & black==1 | `r'== 1
			}
		}
	}
	
	*/

cap log close
