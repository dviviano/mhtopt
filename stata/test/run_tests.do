/*******************************************************************************
    run_tests.do
    Wrapper to run the full unit test suite for the mhtopt package.

    Calls test_all.do (50 tests covering all 5 commands plus paper Table 1
    numeric verification) and writes a clean log.

    HOW TO RUN (either works):
      cd "path/to/mhtopt"
      do "stata/test/run_tests.do"
    or:
      cd "path/to/mhtopt/stata/test"
      do "run_tests.do"

    Output: clean log at stata/test/test_log.txt with PASS/FAIL counts at the end.
*******************************************************************************/

clear all
set more off

* --- Auto-detect package root (the folder containing stata/mht_critical.ado) ---
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
            display as error "Please cd to the repo root (mhtopt/) or stata/test/."
            exit 601
        }
    }
}

local testdir "`root'/stata/test"

adopath + "`root'/stata"

capture log close _tests
log using "`testdir'/test_log.txt", replace text name(_tests)

do "`testdir'/test_all.do"

log close _tests

* Post-process: strip command echo from the log for readability
global clean_log_path "`testdir'/test_log.txt"
quietly run "`root'/stata/_clean_log.do"
display _newline as text "Clean test log saved to: `testdir'/test_log.txt"
