/*
	   project: task a
	   course: seminar applied behavioral economics eb03
	   author: group a
	   date: 25-01-26

	   input: survey.csv
	   output: clean dataset, tables, figures, regression results, log 
	
	   packages: estout
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
global code "$project\code"
global data "$project\data"
global output "$project\output"

global rawdata "$data\raw"
global cleandata "$data\clean"

global tables "$output\tables"
global figures "$output\figures"
global logs "$output\logs"

* ensure output directory structure exists
foreach dir in "$code" "$data" "$output" "$rawdata" "$cleandata" "$tables" "$figures" "$logs" {
    capture mkdir "`dir'"
}

* ensure any previous session is closed
capture log close

* start the log file
log using "$logs\main.log", replace


*===============================================================================
* CLEANUP DATA
*===============================================================================

* import raw data
import delimited "$rawdata\data_raw.csv", clear varnames(1) bindquote(strict) stripquotes(yes)
save "$cleandata\data_clean.dta", replace

* drop qualtrics headers
drop in 1/2

* remove unused variables
drop startdate enddate status ipaddress progress recordeddate responseid recipient* location* distributionchannel userlanguage externalreference

*decouple openingtime variable
gen morning = strpos(openingtime, "1") > 0 if !missing(openingtime)
gen afternoon = strpos(openingtime, "2") > 0 if !missing(openingtime)
gen evening = strpos(openingtime, "3") > 0 if !missing(openingtime)
gen night = strpos(openingtime, "4") > 0 if !missing(openingtime)

* reset labels and set numeric types
foreach i of varlist _all {
	if "`i'" == "openingtime" continue
	
    label variable `i' ""
    if !strmatch("`i'", "*_text") {
        destring `i', replace force
    }
}

* recode variables
recode previousawareness (2 = 0) (1 = 1)

* drop non-hospitality
drop if hospitality == 0


* rename and order
format *_text %12s

rename (variablematrix_1 variablematrix_2 variablematrix_3 variablematrix_4 variablematrix_5)(understanding comprehension feasibility attention intent)

order treatment, after(durationinseconds)
order attention *check, after(voltage)

* sample selection criteria
drop if (duration < 30 | duration > 1800) & !missing(feasibility)
tab duration
drop if attention != 7 & !missing(attention)
drop if controlcheck != 2 & !missing(controlcheck)
drop if treatmentcheck != 2 & !missing(treatmentcheck)


*===============================================================================
* ANALYSIS
*===============================================================================
* attrition
gen attrition = (finished == 0)
drop finished

tab attrition treatment, missing
tab attrition 
drop if attrition == 1

* summarize data
sum type previousawareness employees type openingtime role voltage
tab feasibility treatment, missing

label define previousawareness_labels 0 "no" 1 "yes"
label values previousawareness previousawareness_labels
tab previousawareness

label define employees_labels 1 "1-5" 2 "6-15" 3 "15-50" 4 "More than 50" 5 "Not sure"
label values employees employees_labels
tab employees

label define type_labels 1 "Cafe" 2 "Bar" 3 "Restaurant" 4 "Hotel" 5 "Other"
label values type type_labels
tab type

replace openingtime = subinstr(openingtime, "1", "Morning", .)
replace openingtime = subinstr(openingtime, "2", " Afternoon", .)
replace openingtime = subinstr(openingtime, "3", " Evening", .)
replace openingtime = subinstr(openingtime, "4", " Night", .)
tab openingtime, sort
describe openingtime
gen open_peak3 = .
gen open_morning = strpos(openingtime, "Morning") > 0
gen open_evening = strpos(openingtime, "Evening") > 0
gen open_peak4 = .
replace open_peak4 = 0 if open_morning == 0 & open_evening == 0
replace open_peak4 = 1 if open_morning == 1 & open_evening == 0
replace open_peak4 = 2 if open_morning == 0 & open_evening == 1
replace open_peak4 = 3 if open_morning == 1 & open_evening == 1
label define peak4lbl 0 "Neither peak" ///
                      1 "Morning only" ///
                      2 "Evening only" ///
                      3 "Both peaks"

label values open_peak4 peak4lbl
tab open_peak4
rename open_peak4 opening_times
tab opening_times

tab open_peak 4

label define role_labels 1 "Owner" 2 "Manager" 3 "Head Office" 4 "Employee" 5 "Other"
label values role role_labels
tab role

label define voltage_labels 1 "Low" 2 "Medium" 3 "High" 4 "Not sure"
label values voltage voltage_labels
tab voltage

* balance tests
tab previousawareness treatment, chi2
tab employees treatment, exact
tab type treatment, exact
tab opening_time treatment, exact
tab role treatment, exact
tab voltage treatment, exact

* power calculations
tabstat feasibility, by(treatment) statistics(mean sd n)

ttest feasibility, by(treatment)
power twomeans `r(mu_1)', n1(`r(N_1)') n2(`r(N_2)') sd1(`r(sd_1)') sd2(`r(sd_2)') power(0.8) alpha(0.05)

* ologit models
eststo l1: ologit feasibility i.treatment, robust
eststo l2: ologit feasibility i.treatment i.opening_times, robust
eststo l3: ologit feasibility i.treatment i.opening_time i.previousawareness, robust
eststo l4: ologit feasibility i.treatment i.opening_time i.previousawareness i.type, robust
eststo l5: ologit feasibility i.treatment i.opening_time i.previousawareness i.type i.employees, robust
eststo l6: ologit feasibility i.treatment i.opening_time i.previousawareness i.type i.employees i.role, robust
eststo l7: ologit feasibility i.treatment i.opening_time i.previousawareness i.type i.employees i.role i.voltage, robust

global format_numbers "b(3) se(3) star(* 0.10 ** 0.05 *** 0.01)"
global format_settings "nomtitles lines nogap nodepvars compress nonotes modelwidth(6)"

global format_collabels "collabels(none) mlabels(none)"
global format_coeflabels "coeflabels(_cons "Constant")"

global format_table "$format_numbers $format_settings $format_collables $format_coeflabels"

* define table notes
global format_errors "Standard errors in parentheses"
global format_stars "* p < 0.10, ** p < 0.05, *** p < 0.01"
global format_baseline_notes "Model (1) is the baseline specification.{\line}Model 2 controls for previous awareness of the incoming price changes.{\line}Models (3) to (7) control for bussiness type and demographics."

global format_baseline "addnotes("$format_errors" "$format_stars" "$format_baseline_notes")"

*define scalars
global format_scalars_ologit "stats(r2_p chi2 N, labels("Pseudo R{\up5 2}" "\u967?{\up5 2}" "N"))"
global format_scalars_probit "stats(r2_p chi2 N, labels("Pseudo R{\up5 2}" "\u967?{\up5 2}" "N"))"

* finalize format globals for comfortable use
global format_ologit "drop (cut*) $format_table $format_scalars_ologit equations(1) eqlabels(none)"
global format_oprobit "drop (cut*) $format_table $format_scalars_probit equations(1) eqlabels(none)"

* models
esttab l1 l2 using "$tables\ologit2.rtf", replace $format_ologit $format_baseline
esttab l1 l2 using "$tables\ologit3.rtf", replace $format_ologit $format_baseline
esttab l1 l2 l3 l4 l5 l6 l7 using "$tables\ologit4.rtf", replace $format_ologit $format_baseline

* oprobit models
eststo p1: oprobit feasibility i.treatment, robust
eststo p2: oprobit feasibility i.treatment i.opening_times, robust
eststo p3: oprobit feasibility i.treatment i.opening_time i.previousawareness, robust
eststo p4: oprobit feasibility i.treatment i.opening_time i.previousawareness i.type, robust
eststo p5: oprobit feasibility i.treatment i.opening_time i.previousawareness i.type i.employees, robust
eststo p6: oprobit feasibility i.treatment i.opening_time i.previousawareness i.type i.employees i.role, robust
eststo p7: oprobit feasibility i.treatment i.opening_time i.previousawareness i.type i.employees i.role i.voltage, robust

global format_numbers "b(3) se(3) star(* 0.10 ** 0.05 *** 0.01)"
global format_settings "nomtitles lines nogap nodepvars compress nonotes modelwidth(6)"

global format_collabels "collabels(none) mlabels(none)"
global format_coeflabels "coeflabels(_cons "Constant")"

global format_table "$format_numbers $format_settings $format_collables $format_coeflabels"

* define table notes
global format_errors "Standard errors in parentheses"
global format_stars "* p < 0.10, ** p < 0.05, *** p < 0.01"
global format_baseline_notes "Model (1) is the baseline specification.{\line}Model 2 controls for previous awareness of the incoming price changes.{\line}Models (3) to (7) control for bussiness type and demographics."

global format_baseline "addnotes("$format_errors" "$format_stars" "$format_baseline_notes")"

*define scalars
global format_scalars_ologit "stats(r2_p chi2 N, labels("Pseudo R{\up5 2}" "\u967?{\up5 2}" "N"))"
global format_scalars_probit "stats(r2_p chi2 N, labels("Pseudo R{\up5 2}" "\u967?{\up5 2}" "N"))"

* finalize format globals for comfortable use
global format_ologit "drop (cut*) $format_table $format_scalars_ologit equations(1) eqlabels(none)"
global format_oprobit "drop (cut*) $format_table $format_scalars_probit equations(1) eqlabels(none)"

* models
esttab p1 p2 p3 p4 p5 p6 p7 using "$tables\ologit4.rtf", replace $format_ologit $format_baseline
esttab p1 p2 p3 p4 p5 p6 p7 using "$tables\ologit5.rtf", replace $format_ologit $format_baseline

graph bar (mean) understanding comprehension feasibility intent, over(treatment)
graph export "$figures\bar.png", replace

graph pie, over(barriers)
graph export "$figures\pie.png", replace

* save final processed data
save "$cleandata\survey_clean.dta", replace

* close log and end script
log close
exit