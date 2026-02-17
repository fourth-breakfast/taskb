import delimited "C:\Users\Sara B\OneDrive\Behavioural Seminar\Task A\Excel data clean Task A.csv", clear varnames(1)
tab age
drop if age > 28 & !missing(age)
drop if age < 18 & !missing(age)
tab age, missing
drop if gender == "Male"
drop if participation == "I disagree (end survey)"
tab gender
tab participation 
gen treatment = .
gen control = .
* 0) Start clean (prevents lots of "." missings)
capture gen treat
capture gen control
replace treat   = 0
replace control = 0

* 1) Treatment = 1 if answered ANY treatment question
replace treat = 1 if !missing(q5_1) | !missing(q5_2) | !missing(q5_3) | !missing(q5_4) | ///
    !missing(q23) | !missing(q24) | !missing(q25) | !missing(q23_9_text) | !missing(q25_9_text)

* 2) Control = 1 if answered ANY control question
replace control = 1 if !missing(q29_1) | !missing(q29_2) | !missing(q29_3) | !missing(q29_4) | ///
    !missing(q30) | !missing(q30_9_text) | !missing(q20) | !missing(q20_9_text) | ///
    !missing(q21) | !missing(q21_9_text) | !missing(q31)

* 3) (Optional) If you want treat to be 0 for anyone who is control (only if groups should be mutually exclusive)
replace treat = 0 if control == 1

gen group = .
replace group = 1 if treat == 1
replace group = 0 if control == 1

label define grp 0 "Control" 1 "Treatment"
label values group grp
tab group if progress =


** testing 

drop if progress != 100






clear
** Treatment Q3, Q4 Q5 Q23 Q24 Q25 Q6
** Control Q22 Q28 Q29 Q30 Q20 Q21 Q27 Q31
gen attrit = (finished != "TRUE")
tab attrit
gen treat = .


*****
**Atrittion
describe finished
drop if treatment != 1 & control != 1
gen attrit = finished == "FALSE"
label variable attrit "Attrited (did not finish study)"
label define attrit_lbl "Completed" 1 "Attrited"
label values attrit attrit_lbl

tab finished attrit
tab attrit treatment, row
tab attrit
reg attrit treatment, robust

*** Generating reported values
*reporting to police

gen report_num = .
replace report_num = 1 if q5_1 == "Extremely unlikely"
replace report_num = 2 if q5_1 == "Unlikely"
replace report_num = 3 if q5_1 == "Slightly unlikely"
replace report_num = 4 if q5_1 == "Neither likely nor unlikely"
replace report_num = 5 if q5_1 == "Slightly likely"
replace report_num = 6 if q5_1 == "Likely"
replace report_num = 7 if q5_1 == "Extremely likely"

gen report_num_c = .
replace report_num_c = 1 if q29_1 == "Extremely unlikely"
replace report_num_c = 2 if q29_1 == "Unlikely"
replace report_num_c = 3 if q29_1 == "Slightly unlikely"
replace report_num_c = 4 if q29_1 == "Neither likely nor unlikely"
replace report_num_c = 5 if q29_1 == "Slightly likely"
replace report_num_c = 6 if q29_1 == "Likely"
replace report_num_c = 7 if q29_1 == "Extremely likely"

gen report_llh = .
replace report_llh = report_num       if treatment == 1
replace report_llh = report_num_c  if treatment == 0
label variable report_llh "Likelihood to report catcalling to the police (1=Extremely unlikely, 7=Extremely likely)"

tab report_llh treatment
sum report_llh

*previous knowledge of the law

gen knowledge = .
replace knowledge = 0 if q6 == "No, I was not aware"
replace knowledge = 1 if q6 == "Yes, I was aware"

gen knowledge_c = .
replace knowledge_c = 0 if q31 == "No, I was not aware"
replace knowledge_c = 1 if q31 == "Yes, I was aware"


gen knowledge_pre = .
replace knowledge_pre = knowledge   if treatment == 1
replace knowledge_pre = knowledge_c if treatment == 0

label variable knowledge_pre "Knowledge of sexual harassment law prior to survey (1=Knew about it, 0=Did not know)"


*** ITT

reg report_llh treatment, robust
*not stat. significant when reminded of the law, regardless of previous knowledge at the 10% level (P=0.288)

*prior knowledge as a control
reg report_llh treatment knowledge_pre, robust


*heterogeneous effects
reg report_llh treatment##knowledge_pre, robust
*both treatment and control are independently insignificant, but among participants who already knew about the law, being reminded (treatment) increased their likelihood to report by about 1.05 points on the 7-point scale compared to control.

*with controls:
gen female = .
replace female = 0 if gender == "Male"
replace female = 1 if gender == "Female"

gen rotterdam_resid = .
replace rotterdam_resid = 0 if resident == "No"
replace rotterdam_resid = 1 if resident == "Yes"

gen student_stat = .
replace student_stat = 0 if student == "No"
replace student_stat = 1 if student == "Yes"

*regression with controls
reg report_llh treatment##knowledge_pre female student_stat rotterdam_resid, robust

*interaction is still statistically significant, the singular groups are not

*Inofficial Channel

gen ireport_num = .
replace ireport_num = 1 if q5_2 == "Extremely unlikely"
replace ireport_num = 2 if q5_2 == "Unlikely"
replace ireport_num = 3 if q5_2 == "Slightly unlikely"
replace ireport_num = 4 if q5_2 == "Neither likely nor unlikely"
replace ireport_num = 5 if q5_2 == "Slightly likely"
replace ireport_num = 6 if q5_2 == "Likely"
replace ireport_num = 7 if q5_2 == "Extremely likely"

gen ireport_num_c = .
replace ireport_num_c = 1 if q29_2 == "Extremely unlikely"
replace ireport_num_c = 2 if q29_2 == "Unlikely"
replace ireport_num_c = 3 if q29_2 == "Slightly unlikely"
replace ireport_num_c = 4 if q29_2 == "Neither likely nor unlikely"
replace ireport_num_c = 5 if q29_2 == "Slightly likely"
replace ireport_num_c = 6 if q29_2 == "Likely"
replace ireport_num_c = 7 if q29_2 == "Extremely likely"

gen ireport_llh = .
replace ireport_llh = ireport_num       if treatment == 1
replace ireport_llh = ireport_num_c  if treatment == 0
label variable report_llh "Likelihood to report catcalling through inofficical channel (1=Extremely unlikely, 7=Extremely likely)"

reg ireport_llh treatment##knowledge_pre, robust

reg ireport_llh treatment##knowledge_pre, robust

reg ireport_llh treatment##knowledge_pre female student_stat rotterdam_resid, robust


*Confront
gen confront = .
replace confront = 1 if q5_3 == "Extremely unlikely"
replace confront = 2 if q5_3 == "Unlikely"
replace confront = 3 if q5_3 == "Slightly unlikely"
replace confront = 4 if q5_3 == "Neither likely nor unlikely"
replace confront = 5 if q5_3 == "Slightly likely"
replace confront = 6 if q5_3 == "Likely"
replace confront = 7 if q5_3 == "Extremely likely"

gen confront_c = .
replace confront_c = 1 if q29_3 == "Extremely unlikely"
replace confront_c = 2 if q29_3 == "Unlikely"
replace confront_c = 3 if q29_3 == "Slightly unlikely"
replace confront_c = 4 if q29_3 == "Neither likely nor unlikely"
replace confront_c = 5 if q29_3 == "Slightly likely"
replace confront_c = 6 if q29_3 == "Likely"
replace confront_c = 7 if q29_3 == "Extremely likely"

gen confront_llh = .
replace confront_llh = confront      if treatment == 1
replace confront_llh = confront_c  if treatment == 0
label variable confront_llh "Likelihood to confront catcalling behaviour (1=Extremely unlikely, 7=Extremely likely)"

reg confront_llh treatment##knowledge_pre, robust

reg confront_llh treatment##knowledge_pre, robust

reg confront_llh treatment##knowledge_pre female student_stat rotterdam_resid, robust




*Ignore
gen ignore = .
replace ignore = 1 if q5_4 == "Extremely unlikely"
replace ignore = 2 if q5_4 == "Unlikely"
replace ignore = 3 if q5_4 == "Slightly unlikely"
replace ignore = 4 if q5_4 == "Neither likely nor unlikely"
replace ignore = 5 if q5_4 == "Slightly likely"
replace ignore = 6 if q5_4 == "Likely"
replace ignore = 7 if q5_4 == "Extremely likely"

gen ignore_c = .
replace ignore_c = 1 if q29_4 == "Extremely unlikely"
replace ignore_c = 2 if q29_4 == "Unlikely"
replace ignore_c = 3 if q29_4 == "Slightly unlikely"
replace ignore_c = 4 if q29_4 == "Neither likely nor unlikely"
replace ignore_c = 5 if q29_4 == "Slightly likely"
replace ignore_c = 6 if q29_4 == "Likely"
replace ignore_c = 7 if q29_4 == "Extremely likely"

gen ignore_llh = .
replace ignore_llh = confront      if treatment == 1
replace ignore_llh = confront_c  if treatment == 0
label variable ignore_llh "Likelihood to ignore catcalling behaviour (1=Extremely unlikely, 7=Extremely likely)"

reg ignore_llh treatment##knowledge_pre, robust

reg ignore_llh treatment##knowledge_pre, robust

reg ignore_llh treatment##knowledge_pre female student_stat rotterdam_resid, robust


///Country

tab country
tab country, gen(country_)
reg report_llh treatment##knowledge_pre country_*, robust


