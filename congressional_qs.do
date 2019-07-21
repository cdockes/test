/***



congressional_qs.do

Produce some stats on mobility out of poverty for congressman harder


JG 2-15-19
CD 2-19-19

****/

global data "C:\Users\cad308\Downloads"


*-----------------------------------
* 1) Is it true that 70% of kids
* 		born in  poverty stay
* 		in poverty?
*----------------------------------

* use the 100 by 100 transition matrix from IGE
use "${data}/onlinedata1", clear

* each cell is the joint probability, so can generate sums 
*	for different definitions of poverty.

* set the definitoin of poverty (1-100)
global pov 20

local totvars
forval p = 1 / $pov {
	local totvars `totvars' par_frac_bin_`p'
}

egen rowtot = rowtotal(`totvars') //percent of kids who are a given kid income bin and had poor parents
egen kidtot = total(rowtot) if kid_fam_bin <= $pov // percent of kids across kid income bins who had poor parents
egen partot = total(rowtot) //percent of kids who grow up with par inc <= pov cutoff

* fraction of kids who are born into poverty (should just be pov)
summ partot, meanonly
qui local fracpoorpar: di %4.3f `r(mean)'
di in red "`fracpoorpar'% of kids are born into poverty(p${pov})"

* joint probability
summ kidtot, meanonly
qui local fracpoorparpoorkid: di %4.3f `r(mean)'
di in red "`fracpoorparpoorkid'% of kids are born in poverty (p${pov}) and stay poor as adults"

* of those who start poor, what fraction stay poor?
qui local condprob: di %4.3f (`fracpoorparpoorkid'/`fracpoorpar')*100
di in red "Among kids born into poverty (p${pov}), `condprob'% are poor as adults"


*-----------------------------------
* What are the best and worst
* cities for leaving poverty?
*-----------------------------------

* Use CZ quintile transition matrices from IGE
use "${data}/onlinedata6", clear
drop if missing(n_ige_rank_8085)

* set the poverty quntile threshold
global povq 1

* generate the probability of leaving poverty
* 	conditional on having poor parents
*	(prob parq=povq, without conditioning on kid outcomes)

* first construct the joint probabilities
forval pq = 1/5 {
		forval kq = 1/5 {

			gen jprob_p`pq'_k`kq' = prob_p`pq'_k`kq'*frac_par_`pq'

		}
}

* get the fraction of kids who grew up with parents under the poverty threshold
local partotvars
forval q = 1 / $povq {

	local partotvars `partotvars' frac_par_`q'
}
egen frac_poorpar = rowtotal(`partotvars')

* get the fraction of kids who had poor parents and became not poor themselves
* (sum joint probs)
local totvars
forval pq = 1 / $povq {
	forval kq = 1 / 5 {

		* skip if the kid is not rich enough
		if `kq'<=$povq continue

		* otherwise add this combo to the list we want to total
		local totvars `totvars' jprob_p`pq'_k`kq'

	}
}

egen frac_poorpar_notpoorkid = rowtotal(`totvars')

* get the conditional prob
gen condprob = frac_poorpar_notpoorkid/frac_poorpar
g condprob_middle = prob_p1_k3 + prob_p1_k4 + prob_p1_k5
* Make a map
//maptile2 condprob, geography(cz) colorscheme(dh1) savegraph("C:\Users\cad308\Opportunity Insights Dropbox\Caroline Dockes/transition_map.png")


* make lists of the best and worst places
preserve

drop if n_ige_rank_8085<5000 // get rid of smallest places
gsort - condprob 
* best places
list czname stateabbrv condprob frac_poorpar n_ige_rank_8085 in 1/10, sep(10)

* worst places
gsort condprob
list czname stateabbrv condprob frac_poorpar n_ige_rank_8085 in 1/10, sep(10)
restore
preserve
* Do same thing within CA
keep if stateabbrv == "CA"
maptile2 condprob, geography(cz) colorscheme(dh1) zoom savegraph("C:\Users\cad308\Opportunity Insights Dropbox\Caroline Dockes/transition_map_california.png")
maptile2 condprob_middle, geography(cz) colorscheme(dh1) zoom savegraph("C:\Users\cad308\Opportunity Insights Dropbox\Caroline Dockes/transition_to_middle_class_map_california.png")

gsort - condprob 
* best places - California
list czname stateabbrv condprob frac_poorpar n_ige_rank_8085 in 1/10, sep(10)
* worst places - California
gsort condprob
list czname stateabbrv condprob frac_poorpar n_ige_rank_8085 in 1/10, sep(10)
restore
*-----------------------------------
* What is the difference in prob
* of rising out of poverty in 
* Modesto vs Silicon Valley?
*-----------------------------------

* Modesto is it's own CZ
* Use San Jose for Silicon Valley
* Keep also SF
keep if inlist(cz, 37000, 37500, 37800 )

gsort condprob
list czname stateabbrv condprob frac_poorpar n_ige_rank_8085 
restore


* Try to replicate 30% number for making it to the middle class
* see https://medium.com/@thericktastic/only-4-of-people-who-are-born-into-poverty-will-ever-make-it-out-666ef76ea46e

* Find what 'middle class' means in terms of ranks - article says 35k-106k annual hhinc (defined by two-thirds to double the median income)
use "$dropbox\outside\finer_geo\website\data\pctile_to_dollar_cw.dta", clear
su kid_hh_income if percentile == 50 
local median = r(mean)
local lower = 2*`median'/3
local upper = 2*`median'
local cutoff_lower = `lower' // set this to 35000 instead to use article value
local cutoff_upper = `upper' // set this to 106000 to use article value

su percentile if kid_hh_income >=`cutoff_lower'
global middle = r(min)
su percentile if kid_hh_income <`cutoff_upper'
global middle_upper = r(max)
* use the 100 by 100 transition matrix from IGE
use "${data}/onlinedata1", clear

* each cell is the joint probability, so can generate sums 
*	for different definitions of poverty.

* set the definitoin of poverty (1-100)
global pov 20


local totvars
forval p = 1 / $pov {
	local totvars `totvars' par_frac_bin_`p'
}

egen rowtot = rowtotal(`totvars') //percent of kids who are a given kid income bin and had poor parents
egen kidtot = total(rowtot) if kid_fam_bin >= $middle // percent of kids who make it to the middle class among poor parent kids
egen kidtot_exact = total(rowtot) if kid_fam_bin >= $middle & kid_fam_bin <= ${middle_upper}
egen partot = total(rowtot) //percent of kids who grow up with par inc <= pov cutoff

* fraction of kids who are born into poverty (should just be pov)
summ partot, meanonly
qui local fracpoorpar: di %4.3f `r(mean)'
di in red "`fracpoorpar'% of kids are born into poverty(p${pov})"

* joint probability
summ kidtot, meanonly
qui local fracpoorparmiddlekid: di %4.3f `r(mean)'
di in red "`fracpoorparmiddlekid'% of kids are born in poverty (p${pov}) and make it at least to the middle class"

* of those who start poor, what fraction stay poor?
qui local condprob: di %4.3f (`fracpoorparmiddlekid'/`fracpoorpar')*100
di in red "Among kids born into poverty (p${pov}), `condprob'% make it to at least the middle class (income >= p${middle} )"

* poor kids who make it exactly to the middle class (i.e. exclude kids who make it to top incomes)
summ kidtot_exact, meanonly
qui local fracpoorparmiddleexactkid: di %4.3f `r(mean)'
di in red "`fracpoorparmiddleexactkid'% of kids are born in poverty (p${pov}) and make it to the middle class"

qui local condprob2: di %4.3f (`fracpoorparmiddleexactkid'/`fracpoorpar')*100
di in red "Among kids born into poverty (p${pov}), `condprob2'% make it to the middle class (income >= p${cutoff} )"

* for comparison, get number for middle class children

drop *tot*
local totvars
local p1 = $middle
local p2 = ${middle_upper}
forval p = `p1' / `p2' {
	local totvars `totvars' par_frac_bin_`p'
}

egen rowtot = rowtotal(`totvars') //percent of kids who are a given kid income bin and had middle class parents
egen kidtot = total(rowtot) if kid_fam_bin >= $middle // percent of kids who make it to the middle class among middle class kids
egen kidtot_exact = total(rowtot) if kid_fam_bin >= $middle & kid_fam_bin <= ${middle_upper}
egen partot = total(rowtot) //percent of kids who grow up with middle class parents


* fraction of kids who are born in middle class
summ partot, meanonly
qui local frac: di %4.3f `r(mean)'
di in red "`frac'% of kids are born into the middle class(p${middle} to p${middle_upper})"

* joint probability
summ kidtot, meanonly
qui local fracmiddleparmiddlekid: di %4.3f `r(mean)'
di in red "`fracmiddleparmiddlekid'% of middle class kids stay in the middle class or more"

* of those who start poor, what fraction stay poor?
qui local condprob: di %4.3f (`fracmiddleparmiddlekid'/`frac')*100
di in red "Among middle class kids, `condprob'% make it to at least the middle class (income >= p${middle} )"

* poor kids who make it exactly to the middle class (i.e. exclude kids who make it to top incomes)
summ kidtot_exact, meanonly
qui local fracpoorparmiddleexactkid: di %4.3f `r(mean)'
di in red "`fracpoorparmiddleexactkid'% of kids are born in middle and make it to the middle class"

qui local condprob2: di %4.3f (`fracpoorparmiddleexactkid'/`frac')*100
di in red "Among middle-class kids, `condprob2'% stay in the middle class "



*------------------------------------------------------
*  Do some stuff by race
*-----------------------------------------------------

use "C:\Users\cad308\Downloads\table_3-1.dta", clear
egen leave_pov = rowtotal(kfr_q2_cond_par_q1 kfr_q3_cond_par_q1 kfr_q4_cond_par_q1 kfr_q5_cond_par_q1)
keep if gender == "P" & kid_race != "Other"
g order = _n
labmask order, values(kid_race)
tw (bar leave_pov order, barwidth(0.4)) ///
	, xlabel(,val notick) xtitle("") ytitle("Probability of Leaving Poverty") ///
	title(" ", size(huge)) ylabel(0(0.2)1)
	
	graph export "C:\Users\cad308\Opportunity Insights Dropbox\Caroline Dockes/race_breakdown_transition.wmf", replace

