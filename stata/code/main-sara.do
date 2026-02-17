/*
	   project: task a
	   course: seminar applied behavioral economics eb03
	   author: group a
	   date: 25-01-26

	   input: survey.csv
	   output: clean dataset, tables, figures, regression results, log 
	
	   packages: 
	   description: 
*/


*===============================================================================
* SETUP
*===============================================================================
* environment setup
version 19
clear all

* set directory globals
global project "`c(pwd)'"
global code "$project/code"
global rawdata "$project/data/raw"
global cleandata "$project/data/clean"
global tables "$project/output/tables"
global figures "$project/output/figures"
global logs "$project/output/logs"

* ensure output directory structure exists
foreach dir in "$rawdata" "$cleandata" "$tables" "$figures" "$logs" {
    capture mkdir "`dir'"
}

* ensure any previous session is closed
capture log close

* start the log file
log using "$logs/main.log", replace


*===============================================================================
* CLEANUP DATA
*===============================================================================
* import raw survey data and drop qualtrics metadata headers
import delimited "$rawdata/survey.csv", clear ///
	varnames(1) bindquote(strict) stripquotes(yes)
save "$cleandata/survey_clean.dta", replace
drop in 1/2

* remove system-generated variables
#delimit ;
drop startdate enddate status ipaddress
	recorded* responseid recipient* external*
	location* distribution* userlanguage
	treat* create* ;    
#delimit cr

* reset labels and coerce numeric types (excluding open-ended text fields)
foreach i of varlist _all {
    label variable `i' ""
    if !strmatch("`i'", "*_text") {
        destring `i', replace force
    }
}

* define treatment vs control with exclusivity check to ensure branch integrity
local treatment_vars q5_1 q5_2 q5_3 q5_4 q23 q24 q25
local control_vars q29_1 q29_2 q29_3 q29_4 q20 q30 q31

egen did_treatment = rownonmiss(`treatment_vars')
egen did_control = rownonmiss(`control_vars')

* logic: assign strictly if participant belongs to only one branch
gen treatment = .
replace treatment = 1 if did_treatment > 0 & did_control == 0
replace treatment = 0 if did_control > 0 & did_treatment == 0


* consolidate outcome variables; preserve missing values to avoid bias
egen police = rowtotal(q5_1 q29_1), missing
egen service = rowtotal(q5_2 q29_2), missing
egen confront = rowtotal(q5_3 q29_3), missing
egen ignore = rowtotal(q5_4 q29_4), missing
drop q5* q29*

* consolidate qualitative text; normalize missing for concatenation
foreach var in q23_9_text q30_9_text q24_9_text ///
	q20_9_text q25_9_text q21_9_text {
    replace `var' = "" if `var' == "."
}

egen police_reason = rowtotal(q23 q30), missing
egen service_reason = rowtotal(q24 q20), missing
egen confront_reason = rowtotal(q25 q21), missing

gen police_reason_text = q23_9_text + q30_9_text
gen service_reason_text = q24_9_text + q20_9_text
gen confront_reason_text = q25_9_text + q21_9_text
drop q23* q30* q24* q20* q25* q21*

egen knowledge = rowtotal(q6 q31), missing
drop q6 q31

* rename demographic variables and organize dataset order
rename (q1 q8 v42 v43 q17 q18) ///
	(agreement female age country student rotterdam)
rename duration* duration
format *_text %12s

order finished progress duration agreement female age ///
	country student rotterdam
order treatment, after(knowledge)

* recode indicator variables to 0/1 binary space
local dummy_vars female student rotterdam knowledge
foreach i of local dummy_vars  {
    recode `i' (0 = .) (1 = 0) (2 = 1)
}

recode agreement (2 = 0)

* sample selection criteria for final estimation sample
keep if agreement == 1
drop if female == 0 | age < 18 | (age > 28 & !missing(age))


*===============================================================================
* ANALYSIS
*===============================================================================
* summarize data
tabulate treatment finished, missing
summarize age student rotterdam

**Attrition 
describe finished
gen attrit = finished == "FALSE"
label variable attrit "Attrited (did not finish study)"
label define attrit_lbl "Completed" 1 "Attrited"
label values attrit attrit_lbl

tab finished attrit
tab attrit treatment, row
tab attrit
reg attrit treatment, robust


* balance tests
ttest age, by(treatment)
tab student treatment, chi2
tab rotterdam treatment, chi2
tab knowledge treatment, chi2

* power calculations
tabstat police service confront ignore, by(treatment) statistics(mean sd n)

power twomeans 1.810606, /// police
	alpha(0.05) power(0.8) n1(132) n2(102) sd(1.186267)
power twomeans 2.659091, /// service
	alpha(0.05) power(0.8) n1(132) n2(102) sd(1.480861)
power twomeans 2.734848, /// confront
	alpha(0.05) power(0.8) n1(132) n2(102) sd(1.65455)
power twomeans 6.257576, /// ignore
	alpha(0.05) power(0.8) n1(132) n2(102) sd(1.104272)

	** generate dutch, 0 for international, 1 if Dutch
gen dutch = (country == 122)
	
* police models
reg police i.treatment, robust
reg police i.treatment##i.knowledge, robust
reg police i.treatment dutch, robust 
reg police i.treatment dutch c.age, robust
reg police i.treatment dutch c.age i.student, robust
reg police i.treatment dutch c.age i.student i.rotterdam, robust
reg police i.treatment##i.knowledge dutch c.age i.student i.rotterdam, robust
margins treatment#knowledge

* service models
reg service i.treatment, robust
reg service i.treatment##i.knowledge, robust
reg service i.treatment dutch, robust 
reg service i.treatment dutch c.age, robust
reg service i.treatment dutch c.age i.student, robust
reg service i.treatment dutch c.age i.student i.rotterdam, robust
reg service i.treatment##i.knowledge dutch c.age i.student i.rotterdam, robust
margins treatment#knowledge


* confront models
reg confront i.treatment, robust
reg confront i.treatment##i.knowledge, robust
reg confront i.treatment dutch, robust 
reg confront i.treatment dutch c.age, robust
reg confront i.treatment dutch c.age i.student, robust
reg confront i.treatment dutch c.age i.student i.rotterdam, robust
reg confront i.treatment##i.knowledge dutch c.age i.student i.rotterdam, robust
margins treatment#knowledge



* ignore models
reg ignore i.treatment, robust
reg ignore i.treatment##i.knowledge, robust
reg ignore i.treatment dutch, robust 
reg ignore i.treatment dutch c.age, robust
reg ignore i.treatment dutch c.age i.student, robust
reg ignore i.treatment dutch c.age i.student i.rotterdam, robust
reg cignore i.treatment##i.knowledge dutch c.age i.student i.rotterdam, robust
margins treatment#knowledge


*==============================================================================*
* EXPORT
*==============================================================================*
* save final processed data
save "$cleandata/survey_values_clean.dta", replace

* close log and end script
log close
exit