// ssc install mrtab

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

* import raw data
import delimited "$rawdata\data_raw.csv", clear varnames(1) bindquote(strict) stripquotes(yes)
save "$cleandata\data_clean.dta", replace

* drop qualtrics headers and destring
drop in 1/2
destring _all, replace

drop if finished == 0

* remove unused variables
drop startdate enddate status ipaddress progress recordeddate responseid recipient* location* distributionchannel userlanguage externalreference durationinseconds finished

* stats
sum q1_1 q4* q6*

gen q3_right = (q3 == 3) & !missing(q3)
tab q3_right

gen q2_right = (strpos(q2, "3") > 0 | strpos(q2, "6") > 0) if !missing(q2)
tab q2_right

forval i = 1/8 {
    gen q2_`i' = (strpos(q2, "`i'") > 0) if !missing(q2)
}

mrtab q2_1-q2_8

tab q8
tab q9
tab q10
tab q11