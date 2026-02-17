/*
       project: task a
       course: seminar applied behavioral economics eb03
       author: group a
       date: 25-01-26

       input: survey.csv
       output: clean dataset, tables, figures, regression results, log 

       description: 
*/

version 19
clear all

* set directory globals
global project "`c(pwd)'"
global rawdata "$project/data/raw"
global cleandata "$project/data/clean"
global tables "$project/tables"
global figures "$project/figures"
global logs "$project/logs"

capture log close
log using "$logs/main.log", replace

* import raw survey data and drop qualtrics metadata headers
import delimited "$rawdata/survey_labels.csv", clear ///
varnames(1) bindquote(strict) stripquotes(yes)
save "$cleandata/survey_labels_clean.dta", replace

* save final processed data
save "$cleandata/survey_values_clean.dta", replace

* close log and end script
log close
exit