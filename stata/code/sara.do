import delimited "C:\Users\Sara B\OneDrive\Behavioural Seminar\Task A\Excel data clean Task A.csv", clear varnames(1)
***cleaning data & demographics***
**drop anyone who is not in the age range
tab age
drop if age > 28 & !missing(age)
drop if age < 18 & !missing(age)
tab age, missing

**drop anyone who is male
drop if gender == "Male"

**drop anyone who did not agree to participate 
drop if participation == "I disagree (end survey)"
tab gender
tab participation 

**by country 
tab country 

**residents rotterdam 
tab resident

**create treatment and control group
gen treatment = .
gen control = .


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

**label results
gen group = .
replace group = 1 if treat == 1
replace group = 0 if control == 1
label define grp 0 "Control" 1 "Treatment"
label values group grp

tab progress if progress != 100
tab 

**checks 
tab durationinseconds if progress == 100

** Attrition 
tab treatment if progress != 100
tab control if progress != 100
tab treatment control if progress != 100
tab progress if progress != 100 & treatment==0 & control==0


tab durationinseconds
sum durationinseconds if progress != 100, detail

gen dependent = .



clear
** Treatment Q3, Q4 Q5 Q23 Q24 Q25 Q6
** Control Q22 Q28 Q29 Q30 Q20 Q21 Q27 Q31
gen attrit = (finished != "TRUE")
tab attrit
gen treat = .
