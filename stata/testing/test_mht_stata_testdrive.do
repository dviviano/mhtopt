********************************************************************************
* MHT Test Drive: Banerjee et al. (Science 2015)
* Viviano, Wuthrich, and Niehaus (2026), "A Model of Multiple Hypothesis Testing"
*
* One outcome x J=6 country arms (reproduces results_note.pdf):
*   Pooled 6-country regression, treatment x country (Eq. 2), J=6 hypotheses.
*   With expensive per-arm costs, the VWN correction is mild and can RETAIN
*   country effects that BH's step-up rule discards.
*
*   Maps to: Figure 3 (country-specific effects), Table 4 (cost data by country).
*
* HOW TO RUN (either works):
*   cd "path/to/mhtopt"
*   do "stata/testing/test_mht_stata_testdrive.do"
* or:
*   cd "path/to/mhtopt/stata/testing"
*   do "test_mht_stata_testdrive.do"
*
* Data: top-level testing/data/ (see testing/README.md; DOI 10.7910/DVN/NHIXNT)
* OUTPUT: stata/testing/testdrive_log.txt (package output only, no echoed code).
********************************************************************************

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
            display as error "Please cd to the repo root (mhtopt/) or stata/testing/."
            exit 601
        }
    }
}

local dta_mod "`root'/testing/data"

adopath + "`root'/stata"

capture log close _testdrive
log using "`root'/stata/testing/testdrive_log.txt", replace text name(_testdrive)


********************************************************************************
* Reference tables (cf. Table 1 in VWN 2026)
********************************************************************************

mht_table, alphabar(0.05) jrange(1 2 3 5 6 10) nmratios(0.5 1.0 2.0)


********************************************************************************
* One outcome x 6 country arms (J=6)
*
* The graduation program differed across countries: different NGOs, different
* assets ($437 India vs $1,228 Ethiopia), different support structures (Table 1).
* We treat the 6 country-specific programs as 6 distinct treatments.
*
* Cost structure: each country = separate RCT with its own budget.
*   Fixed (shared consortium): ~5-15% of total; variable (country): ~85-95%
*   => cf_share ~ 0.10-0.23. The Linear model with low cf_share is natural here
*   because country costs vary widely ($1,257/HH India vs $5,962/HH Peru).
********************************************************************************

display _newline(2) as result "=================================================="
display as result "  One outcome x 6 country arms (J=6)"
display as result "  Reference: Figure 3, Table 4, Banerjee et al. (2015)"
display as result "=================================================="

* --- Data prep: load data, create 6 country treatment indicators (silent) ---
quietly {
    use "`dta_mod'/index_hh_vars.dta", clear

    * 1=Ethiopia, 2=Ghana, 3=Honduras, 4=India, 5=Pakistan, 6=Peru
    forvalues c = 1/6 {
        gen treat_c`c' = (treatment == 1 & country == `c')
    }
}

local treat_vars "treat_c1 treat_c2 treat_c3 treat_c4 treat_c5 treat_c6"

* --- Consumption (primary outcome, cf. Table 3 row 1) ---
display _newline as text "--- Consumption: 6 country-specific treatments ---"
display as text "    (1=Ethiopia, 2=Ghana, 3=Honduras, 4=India, 5=Pakistan, 6=Peru)"

quietly {
    foreach aux in index_ctotal_bsl m_index_ctotal_bsl {
        cap confirm variable `aux'
        if _rc cap gen `aux' = 0
    }
    areg index_ctotal_end `treat_vars' index_ctotal_bsl m_index_ctotal_bsl ///
        control_*, absorb(geo_cluster) cluster(rand_unit)
}

display _newline as text "  FDA default (cf_share=0.46):"
mht_est, vars(`treat_vars') alphabar(0.05)

display _newline as text "  Cobb-Douglas (beta=0.13):"
mht_est, vars(`treat_vars') alphabar(0.05) model(cobbdouglas)

display _newline as text "  Study-specific (cf_share=0.23, jbar=6, countries are expensive):"
mht_est, vars(`treat_vars') alphabar(0.05) cfshare(0.23) jbar(6)

* --- Income & revenues (cf. Table 3 row 6) ---
display _newline as text "--- Income & revenues: 6 country-specific treatments ---"

quietly {
    foreach aux in ind_increv_bsl m_ind_increv_bsl {
        cap confirm variable `aux'
        if _rc cap gen `aux' = 0
    }
    areg ind_increv_end `treat_vars' ind_increv_bsl m_ind_increv_bsl ///
        control_*, absorb(geo_cluster) cluster(rand_unit)
}
mht_est, vars(`treat_vars') alphabar(0.05)

* --- Assets (cf. Table 3 row 3) ---
display _newline as text "--- Assets: 6 country-specific treatments ---"

quietly {
    foreach aux in asset_index_bsl m_asset_index_bsl {
        cap confirm variable `aux'
        if _rc cap gen `aux' = 0
    }
    areg asset_index_end `treat_vars' asset_index_bsl m_asset_index_bsl ///
        control_*, absorb(geo_cluster) cluster(rand_unit)
}
mht_est, vars(`treat_vars') alphabar(0.05)

* --- Food security (cf. Table 3 row 2) ---
display _newline as text "--- Food security: 6 country-specific treatments ---"

quietly {
    foreach aux in index_foodsecurity_bsl m_index_foodsecurity_bsl {
        cap confirm variable `aux'
        if _rc cap gen `aux' = 0
    }
    areg index_foodsecurity_end `treat_vars' index_foodsecurity_bsl ///
        m_index_foodsecurity_bsl control_*, absorb(geo_cluster) cluster(rand_unit)
}
mht_est, vars(`treat_vars') alphabar(0.05)

* --- Financial inclusion (cf. Table 3 row 4) ---
display _newline as text "--- Financial inclusion: 6 country-specific treatments ---"

quietly {
    foreach aux in ind_fin_bsl m_ind_fin_bsl {
        cap confirm variable `aux'
        if _rc cap gen `aux' = 0
    }
    areg ind_fin_end `treat_vars' ind_fin_bsl m_ind_fin_bsl ///
        control_*, absorb(geo_cluster) cluster(rand_unit)
}
mht_est, vars(`treat_vars') alphabar(0.05)


********************************************************************************
* Summary
********************************************************************************

display _newline(2) as result "=================================================="
display as result "  SUMMARY: One outcome x 6 country arms"
display as result "=================================================="
display as text ""
display as text "  Cost structure: adding a country arm is EXPENSIVE (cf_share ~ 0.10-0.23)"
display as text "    => Minimal correction needed (alpha* ~ 0.02-0.04, near unadjusted)"
display as text "    => VWN-Lin retains country effects that BH's step-up rule discards"
display as text "    => Honduras and Peru show weak/no effects under any procedure"
display as text "       (cf. Table 4: Honduras has benefit/cost ratio = -198%)"
display as text ""
display as text "  Correction cuts both ways: it can remove marginally-significant"
display as text "  results or restore ones that FDR procedures discard."
display as text "  See results_note.pdf."

display _newline as result "Done."

log close _testdrive

* Post-process: strip command echo from the log for readability
global clean_log_path "`root'/stata/testing/testdrive_log.txt"
quietly run "`root'/stata/_clean_log.do"
display _newline as text "Clean log saved to: `root'/stata/testing/testdrive_log.txt"
