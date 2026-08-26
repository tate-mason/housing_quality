			
			clear
			
			local data "/Users/tate/Library/CloudStorage/Dropbox/Schoolwork/RM/Data/RM1-Data"
			local output "/Users/tate/Library/CloudStorage/Dropbox/Schoolwork/RM/Output"
			
			use `data'/IPUMS-USA_Extension-correct.dta, clear
			
			/*****************************************************************
			* Creating model for Fig2 variables
			*****************************************************************/
				
				/*price rank = (mean house price rank of a white house at p_0) + (increase in mean house price rank as rank in income dist increases)*(rank of same household in overall income distribution)
					+ (interaction between black indicator and intercept alpha) + (interaction between black and rank of household in income dist)*(increase in mean house price rank as rank in income dist increases)
					+ (control vector of household head factors, household type, location, and living on farm property) 
				*/
				
				//100 bins xtile 100
				
			preserve
				drop if year!=1960
				
				gen rent_inc = 100*rentgrs/(inctot/12) if inctot>0
				gen hval_inc = valueh/(inctot/12) if inctot>0
			
				xtile rentp = rentgrs [aw=hhwt], nq(100)
				xtile valuep = valueh [aw=hhwt], nq(100)
				xtile incp = inctot [aw=hhwt], nq(100)
				
				gen asian_b = incp if asian==1
				
				reg rentp i.asian_b
				
				//2a, 2c, 2e
				
				#delimit ;
				binscatter rentp incp [aw=hhwt],
				by(asian) nq(50)
				linetype(qfit)
				name("Fig2a",replace)
				title("Rent Rank Gap in 1960")
				ytitle("Rent Rank")
				xtitle("Income Rank")
				legend(ring(0) pos(1) col(1))
				;
				#delimit cr
				graph export "`output'Ext_Fig2a.pdf"
				
				#delimit
				binscatter valuep incp [aw=hhwt],
				by(asian) nq(50)
				linetype(qfit)
				name("Fig2c",replace)
				title("House Price Rank Gap in 1960")
				ytitle("Price Rank")
				xtitle("Income Rank")
				legend (ring(0) pos(1) col(1))
				;
				#delimit cr
				graph export "`output'Ext_Fig2c.pdf", replace
				
				gen own100 = 100*(1-renter)
				
				#delimit ;
				binscatter own100 incp [aw=hhwt],
				by(asian) nq(50)
				linetype(qfit)
				name("Fig2e",replace)
				title("Ownership Rate Gaps in 1960")
				ytitle("Ownership Rate")
				xtitle("Income Rank")
				legend (ring(0) pos(1) col(1))
				;
				#delimit cr
				graph export "`output'Ext_Fig2e.pdf", replace
			restore	
				//2b, 2d, 2f
				xtile rentp = rentgrs [aw=hhwt], nq(100)
				xtile valuep = valueh [aw=hhwt], nq(100)
				xtile incp = inctot [aw=hhwt], nq(100)	
			 				
				
				
				
				
			/*****************************************************************
			* Creating model for Tab1 variables
			*****************************************************************/
				 //housing quality measure (age/number of bedrooms) = black indicator + (dummies for each income decile to control for non linear relationships between income and outcomes shown) + vector of controls 
				
				//make loop//
					/*			sort year
					local years "1960 1970 1980 1990 2000 2010 2019"
					foreach y of local years {
				xtile incdec_`y' = inctot if year==`y' [aw=hhwt], nq(10)
					}
					
					drop if incdec_`y'===1
					
					local controls "age sex educ hhtype farm statefip metarea"
					reg builtyr black i.incdec_1960 `controls' [aw=hhwt]
					reg bedrooms black i.incdec_1960 `controls' [aw=hhwt]
					*/
