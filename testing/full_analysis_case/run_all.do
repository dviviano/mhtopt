********************************************************************************
* Run All: Full Analysis Case -- Banerjee et al. (Science 2015)
* Viviano, Wuthrich, and Niehaus (2026), "A Model of Multiple Hypothesis Testing"
*
* Runs the three analysis parts sequentially. Each part produces its own
* clean log file (command echo stripped):
*
*   part2_treatments_log.txt    -- One outcome x 6 country arms (J=6)
*   part3_calibration_log.txt   -- Cost calibration from Table 4
*   part4_gradient_log.txt      -- Sensitivity to fixed cost share (BH divergence)
*
* HOW TO RUN (either works):
*   cd "path/to/mhtopt"
*   do "testing/full_analysis_case/run_all.do"
* or:
*   cd "path/to/mhtopt/testing/full_analysis_case"
*   do "run_all.do"
*
* Each part is also independently runnable.
* Results summary: testing/full_analysis_case/results_note.pdf
********************************************************************************

clear all
set more off

* --- Auto-detect package root ---
local root "`c(pwd)'"
capture confirm file "`root'/stata/mht_critical.ado"
if _rc {
    local root "`c(pwd)'/.."
    capture confirm file "`root'/stata/mht_critical.ado"
    if _rc {
        local root "`c(pwd)'/../.."
        capture confirm file "`root'/stata/mht_critical.ado"
        if _rc {
            display as error "Cannot find the stata/ folder."
            display as error "Please cd to mhtopt/ or its testing/full_analysis_case/ subfolder."
            exit 601
        }
    }
}

local casedir "`root'/testing/full_analysis_case"

capture log close _run_all
log using "`casedir'/run_all_log.txt", replace text name(_run_all)

display as result "{hline 72}"
display as result "  Full Analysis Case: Banerjee et al. (Science 2015)"
display as result "  Running all three parts..."
display as result "{hline 72}"

display _newline(2) as result ">>> Part 2: One outcome x 6 country arms (J=6)"
do "`casedir'/analysis_part2_treatments.do"

display _newline(2) as result ">>> Part 3: Cost calibration from Table 4"
do "`casedir'/analysis_part3_calibration.do"

display _newline(2) as result ">>> Part 4: Sensitivity to fixed cost share"
do "`casedir'/analysis_part4_gradient.do"

display _newline(2) as result "{hline 72}"
display as result "  All three parts completed."
display as result "{hline 72}"

log close _run_all

* Post-process: strip command echo from the log for readability
global clean_log_path "`casedir'/run_all_log.txt"
quietly run "`root'/stata/_clean_log.do"
display _newline as text "Clean logs saved to `casedir'/:"
display as text "  run_all_log.txt (combined)"
display as text "  part2_treatments_log.txt"
display as text "  part3_calibration_log.txt"
display as text "  part4_gradient_log.txt"
