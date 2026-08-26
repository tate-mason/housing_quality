************************************************
* built-fix.dta                                *
* Author: Tate Mason - dmason27@uncc.edu       *
* Date: Jan 19, 2024                           *
************************************************

	#delimit cr 		
	clear				
	clear all			
	set more off	
	
	set scheme white_tableau
	
	//Data Paths
	
	local data "/Users/tate/Library/CloudStorage/Dropbox/Schoolwork/RM/Data/RM2-Data"
	local output "/Users/tate/Library/CloudStorage/Dropbox/Schoolwork/RM/Output"
	
*************************************
* Dropping NA's in builtyr/builtyr2 *
*************************************

	use `data'/IPUMS-USA_Extension.dta, clear
	
	replace builtyr = . if builtyr == 0
	replace builtyr2 = . if builtyr2 == 0
	
	gen yrbuilt = .

*************************************
* Replacing and Formatting Codes    *
*************************************		
		//Builtyr variable used from 1960-2000 in sample
	replace yrbuilt = 65 if builtyr == 9
	replace yrbuilt = 55 if builtyr == 8
	replace yrbuilt = 45 if builtyr == 7
	replace yrbuilt = 35 if builtyr == 6
	replace yrbuilt = 25 if builtyr == 5
	replace yrbuilt = 15 if builtyr == 4
	replace yrbuilt = 8 if builtyr == 3
	replace yrbuilt = 3 if builtyr == 2
	replace yrbuilt = 1 if builtyr == 1
		
		//Builtyr2 variable used 2010 and 2019 in sample
			//2010
	replace yrbuilt = 1 if builtyr2 == 15 & year==2010 | builtyr2 == 14 & year == 2010
	replace yrbuilt = 3 if builtyr2 == 13 & year == 2010 | builtyr2 == 12 & year == 2010 | 		builtyr2 == 11 & year == 2010 | builtyr2 == 10 & year == 2010
	replace yrbuilt = 8 if builtyr2 == 9 & year == 2010 | builtyr2 == 8 & year == 2010
	replace yrbuilt = 15 if builtyr2 == 7 & year == 2010
	replace yrbuilt = 25 if builtyr2 == 6 & year == 2010
	replace yrbuilt = 35 if builtyr2 == 5 & year == 2010
	replace yrbuilt = 45 if builtyr2 == 4 & year == 2010
	replace yrbuilt = 55 if builtyr2 == 3 & year == 2010
	replace yrbuilt = 65 if builtyr2 == 2 & year == 2010 | builtyr2 == 1 & year == 2010
		
			//2019
	replace yrbuilt = 1 if builtyr2 == 24 & year == 2019 | builtyr2 == 23 & year == 2019
	replace yrbuilt = 3 if builtyr2 == 22 & year == 2019 | builtyr2 == 21 & year == 2019 | builtyr2 == 20 & year == 2019 | builtyr2 == 19 & year == 2019
	replace yrbuilt = 8 if builtyr2 == 18 & year == 2019 | builtyr2 == 17 & year == 2019 | builtyr2 == 16 & year == 2019 | builtyr2 == 15 & year == 2019 | builtyr2 == 14 & year == 2019
	replace yrbuilt = 15 if builtyr2 == 13 & year == 2019 | builtyr2 == 12 & year == 2019 | builtyr2 == 11 & year == 2019 | builtyr2 == 10 & year == 2019 | builtyr2 == 9 & year == 2019 
	replace yrbuilt = 25 if builtyr2 == 7 & year == 2019 
	replace yrbuilt = 35 if builtyr2 == 6 & year == 2019
	replace yrbuilt = 45 if builtyr2 == 5 & year == 2019
	replace yrbuilt = 55 if builtyr2 == 4 & year == 2019
	replace yrbuilt = 65 if builtyr2 == 3 & year == 2019 | builtyr2 == 2 & year == 2019 | builtyr2 == 1 & year == 2019
		
	
*************************************
* Formatting Bedrooms               *
*************************************
	gen newrooms = .

	replace bedrooms = . if bedrooms == 0
	replace newrooms = 0 if bedrooms == 1
	replace newrooms = 1 if bedrooms == 2
	replace newrooms = 2 if bedrooms == 3
	replace newrooms = 3 if bedrooms == 4
	replace newrooms = 4 if bedrooms == 5
	replace newrooms = 5 if bedrooms >= 6
	
*************************************
* Saving Dataset                    *
*************************************	
	save `data'/IPUMS-USA_Extension-correct.dta, replace
	
	
	
	
