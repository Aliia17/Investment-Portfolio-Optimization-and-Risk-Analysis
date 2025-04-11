clear all
cls

cd "C:\Users\acer\Desktop\MSF\Investments"

import delimited "C:\Users\acer\Desktop\MSF\Investments\returns.csv"

save returns.dta
clear
use returns.dta

*1
gen is_common = (shrcd == 10 | shrcd == 11)
keep if is_common
drop is_common

gen is_valid_exchange = (exchcd == 1 | exchcd == 2 | exchcd == 3)
keep if is_valid_exchange
drop is_valid_exchange

* 2. Clean SICCD and filter for construction and manufacturing industries
gen siccd_cleaned = trim(siccd)
destring siccd_cleaned, generate(siccd_num) force
gen is_construction_manufacturing = (siccd_num >= 1500 & siccd_num <= 1799) | (siccd_num >= 2000 & siccd_num <= 3999)
keep if is_construction_manufacturing
drop is_construction_manufacturing


* market capitalization and clean up
gen market_cap = prc * shrout
gen date_stata = date(date, "YMD")
format date_stata %td
gen year_month = mofd(date_stata)
format year_month %tm

* 4. sorting data by year month
gsort year_month -market_cap

* 5. ranking 
bysort year_month: gen stock_num = _n

*6. 100 top stocks 
bysort year_month: keep if stock_num <= 100

destring ret, replace

save forcapm.dta
use forcapm

drop permno shrcd exchcd siccd ticker comnam shrcls prc shrout market_cap siccd_cleaned siccd_num

*Data wide format 

reshape wide ret, i(year_month) j(stock_num)
destring ret*, replace force

save ret_reshaped.dta

use ret_reshaped.dta
*does not plot inefficient part of the efficient frontier
correlate ret1-ret100

*efrontier with rf rate
efrontier ret1-ret100
*generalized min variance portfolio
gmvport ret1-ret100

*Importing the factors dataset and merging with ret1-ret 100 dataset
clear
import delimited "factors.csv", stringcols(1)
gen year = substr(date, 1, 4)
gen month = substr(date, 5, 2)

destring year month, replace
drop date

save factors.dta
clear

use ret_reshaped.dta
gen year = substr(date, 1, 4)
gen month = substr(date, 6, 2)
drop date
drop year_month
destring year month, replace

merge m:1 year month using factors.dta
sort _merge

keep if _merge==3
gen rfdecimal = rf/100
drop rf

save ret_reshaped_date.dta, replace
clear
use ret_reshaped_date.dta

* generating efrontier without rf rate
forvalues i = 1/100 {
gen excess_ret`i' = ret`i' - rfdecimal
}
efrontier excess_ret1-excess_ret100
summarize rfdecimal
scalar avg_rf = r(mean)
display "Average Risk-Free Rate: " avg_rf

* Generating 2 CML with short allowed and not allowed
cmline excess_ret* ,rfrate(0.0013566)
cmline excess_ret* ,rfrate(0.0013566) noshort

*Reporting a mixed portfolio
*Short sales allowed
*Define the variables
scalar ret_tan_short = .09342434  
scalar std_dev_tan_short = .11037137

scalar combined_return_short = 0.5 * ret_tan_short + 0.5 * avg_rf

* the standard deviation of the combined portfolio
scalar combined_std_dev_short = 0.5 * std_dev_tan_short

* Display the results
display "Expected Return of the Combined Portfolio (Short Allowed): " combined_return_short
display "Standard Deviation of the Combined Portfolio: " combined_std_dev_short

*Short not allowed
scalar ret_tan = .01978041
scalar std_dev_tan = .04765518

scalar combined_return = 0.5 * ret_tan + 0.5 * avg_rf

* the standard deviation of the combined portfolio
scalar combined_std_dev = 0.5 * std_dev_tan

* Display the results
display "Expected Return of the Combined Portfolio (Short Not Allowed): " combined_return
display "Standard Deviation of the Combined Portfolio (Short Not Allowed): "combined_std_dev



*Task 5 optimal portfolios based on no short tangent portfolio

scalar yaliia = (ret_tan-avg_rf)/(3*(std_dev_tan)^2)
display "Optimal position in the risky portfolio for Aliia: " yaliia
scalar ynikita = (ret_tan-avg_rf)/(1.5*(std_dev_tan)^2)
display "Optimal position in the risky portfolio for Nikita: " ynikita
scalar ydinara = (ret_tan-avg_rf)/(4*(std_dev_tan)^2)
display "Optimal position in the risky portfolio for Dinara: " ydinara
scalar yklara = (ret_tan-avg_rf)/(3*(std_dev_tan)^2)
display "Optimal position in the risky portfolio for Klara: " yklara

scalar wrfa = 1 - yaliia
scalar wrfn = 1 - ynikita
scalar wrfk = 1 - yklara
scalar wrfd = 1 - ydinara

display "Weight in a risk-free asset for Aliia: " wrfa
display "Weight in a risk-free asset for Nikita: " wrfn
display "Weight in a risk-free asset for Klara: " wrfk
display "Weight in a risk-free asset for Dinara: " wrfd

* the expected return of the combined portfolio
scalar ret_aliia = yaliia * ret_tan + wrfa * avg_rf
scalar ret_nikita = ynikita * ret_tan + wrfn * avg_rf
scalar ret_klara = yklara * ret_tan + wrfk * avg_rf
scalar ret_dinara = ydinara * ret_tan + wrfd * avg_rf
* the standard deviation of the combined portfolio
scalar stda = yaliia * std_dev_tan
scalar stdn = ynikita * std_dev_tan
scalar stdk = yklara * std_dev_tan
scalar stdd = ydinara * std_dev_tan
display "the expected return of the combined portfolio for Aliia: " ret_aliia
display "the expected return of the combined portfolio for Nikita: " ret_nikita
display "the expected return of the combined portfolio for Klara: " ret_klara
display "the expected return of the combined portfolio for Dinara: " ret_dinara

* the Sharpe ratio of the combined portfolio
scalar sr_aliia= (ret_aliia - avg_rf) / stda
scalar sr_nikita = (ret_nikita - avg_rf) / stdn
scalar sr_klara = (ret_klara - avg_rf) / stdk
scalar sr_dinara = (ret_dinara - avg_rf) / stdd

display sr_aliia
display sr_nikita
display sr_klara
display sr_dinara

display "Standard deviation of the combined optimal portfolio for Aliia: " stda
display "Standard deviation of the combined optimal portfolio for Nikita: " stdn
display "Standard deviation of the combined optimal portfolio for Klara: " stdk
display "Standard deviation of the combined optimal portfolio for Dinara: " stdd

save complete.dta
clear
use complete.dta



*Task 6.
clear

use forcapm.dta
gen year = substr(date, 1, 4)
gen month = substr(date, 6, 2)
drop date
drop year_month
drop date_stata
destring year month, replace
drop permno shrcd exchcd siccd ticker comnam shrcls prc shrout market_cap siccd_cleaned
destring ret, replace force
replace ret = 0 if missing(ret)
merge m:1 year month using factors.dta
sort _merge
keep if _merge==3

*gen rfdecimal = rf/100
*drop rf
save long.dta




gen excess_ret = ret - rf 
gen excess_index = ewretd - rf 

gen alpha = .
gen beta = .

levelsof stock_num, local(stocks) 
foreach stock in `stocks' {
    regress excess_ret excess_index if stock_num == `stock'
	
    replace alpha = _b[_cons] if stock_num == `stock'
    replace beta = _b[excess_index] if stock_num == `stock'
}

predict residual, residuals
gen residual_sq = residual^2
egen residual_var = mean(residual_sq), by(stock_num)


gen active_weight = alpha / residual_var 
egen active_weight_sum = sum(active_weight) 
gen active_weight_normalized = active_weight / active_weight_sum 

egen beta_sum = sum(beta) 
gen passive_weight_normalized = beta / beta_sum 

gen active_return = 0

levelsof stock_num, local(stocks)
foreach stock in `stocks' {
    replace active_return = active_return + (active_weight_normalized * excess_ret) if stock_num == `stock'
}
gen passive_return = 0

foreach stock in `stocks' {
    replace passive_return = passive_return + (passive_weight_normalized * excess_ret) if stock_num == `stock'
}
gen active_variance = 0

foreach stock in `stocks' {
    replace active_variance = active_variance + (active_weight_normalized^2 * residual_var) if stock_num == `stock'
}
gen active_std_dev = sqrt(active_variance)
gen passive_variance = 0

foreach stock in `stocks' {
    replace passive_variance = passive_variance + (passive_weight_normalized^2 * residual_var) if stock_num == `stock'
}
gen passive_std_dev = sqrt(passive_variance)
gen sharpe_active = active_return / active_std_dev
gen sharpe_passive = passive_return / passive_std_dev
list stock_num active_weight_normalized passive_weight_normalized

save active_passive.dta

*Task 8 Estimating CAPM
clear 
use long.dta
sort stock_num
egen id = group(stock_num)

gen mktrfdecimal = mktrf/100
gen beta=.

su id 
forval i=`r(min)'(1)`r(max)' {
	qui capture regress ret mktrfdecimal if id == `i', robust 
	qui local b = _b[mktrfdecimal]
	qui replace beta = `b' if id == `i'
}

sort beta

xtile beta_quintile = beta, nq(5)

gen rfdec = rf/100

gen quintile_return = .
gen quintile_stddev = .
gen quintile_sharpe = .

* Loop through each quintile
forval i = 1/5 {
    * Calculate the expected return for the quintile
    quietly summarize ret if beta_quintile == `i'
    scalar quintile_return_`i' = r(mean)

    * Calculate the standard deviation for the quintile
    scalar quintile_stddev_`i' = r(sd)

    * Calculate the Sharpe ratio for the quintile
    scalar quintile_sharpe_`i' = (quintile_return_`i' - rfdec) / quintile_stddev_`i'

    * Store the results in the new variables
    replace quintile_return = quintile_return_`i' if beta_quintile == `i'
    replace quintile_stddev = quintile_stddev_`i' if beta_quintile == `i'
    replace quintile_sharpe = quintile_sharpe_`i' if beta_quintile == `i'
}

save capm.dta, replace
clear 
use capm.dta
collapse (mean) beta quintile_return quintile_stddev quintile_sharpe , by(beta_quintile)
save capmquaitiles.dta 


*Task 9 (Task 8 continued)

use capm.dta


gen excess_return = ret - rf    
gen time = year * 12 + month        
 
gen gamma_0 = . 
gen gamma_1 = . 
 
* Loop over each time period for cross-sectional regressions 
levelsof time, local(times) 
foreach t in `times' { 
    qui regress excess_return beta if time == `t', robust  
    qui replace gamma_0 = _b[_cons] if time == `t'       
    qui replace gamma_1 = _b[beta] if time == `t'        
} 
 
 

su gamma_1 
ttest gamma_1 = 0

save fama_macbeth.dta
