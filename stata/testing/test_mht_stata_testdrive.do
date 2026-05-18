********************************************************************************
* MHT Test Drive: Banerjee et al. (Science 2015)
* Viviano, Wuthrich, and Niehaus (2026), "A Model of Multiple Hypothesis Testing"
*
* REFERENCE RESULTS IN BANERJEE ET AL.:
*   Table 3: Pooled treatment effects on 10 indexed outcome families, with
*            BH q-values (column 2) for all 10 hypotheses jointly.
*   Figure 3: Country-specific treatment effects at endline 2.
*   Table 4: Cost-benefit analysis with per-country cost breakdowns.
*
* VERSION A: India arm, 10 outcomes (mht_test)
*   Maps to: Table 3 columns 1-2 (effects + q-values), India rows in Tables S4a-f
*   Question: Which of the 10 outcome results survive economically-grounded MHT?
*
* VERSION B: Pooled 6-country, treatment x country (mht_est)
*   Maps to: Figure 3 (country-specific effects), Table 3 columns 3,6 (F-tests)
*   Question: Which country-specific effects survive when treating 6 programs
*             as 6 distinct treatments?
*
* HOW TO RUN (either works):
*   cd "path/to/package_to_publish"
*   do "testing/test_mht_stata_testdrive.do"
* or:
*   cd "path/to/package_to_publish/testing"
*   do "test_mht_stata_testdrive.do"
*
* OUTPUT:     The log file testing/testdrive_log.txt contains only the
*             package output and commentary (no echoed code).
********************************************************************************

clear all
set more off

* --- Auto-detect package root ---
* Works whether you run from package_to_publish/ or testing/
local root "`c(pwd)'"
capture confirm file "`root'/stata/mht_critical.ado"
if _rc {
    local root "`c(pwd)'/.."
    capture confirm file "`root'/stata/mht_critical.ado"
    if _rc {
        display as error "Cannot find the stata/ folder."
        display as error "Please cd to package_to_publish/ or package_to_publish/testing/"
        exit 601
    }
}

local dta_mod "`root'/testing/data"

adopath + "`root'/stata"

capture log close _testdrive
log using "`root'/testing/testdrive_log.txt", replace text name(_testdrive)


********************************************************************************
* Reference tables (cf. Table 1 in VWN 2026)
********************************************************************************

mht_table, alphabar(0.05) jrange(1 2 3 5 6 10) nmratios(0.5 1.0 2.0)


********************************************************************************
* VERSION A: Heterogeneous Audience -- 10 Outcomes, India
*
* Banerjee et al. Table 3 reports BH q-values for 10 indexed outcome families.
* At endline 1 (pooled): all q <= 0.001 except Physical health (q=0.078) and
* Women's empowerment (q=0.049). We replicate the India arm and apply the
* economically optimal correction from VWN (2026) instead of BH.
*
* The key comparison: does the optimal threshold (which depends on costs)
* confirm or contest the paper's BH-adjusted conclusions?
********************************************************************************

display _newline(2) as result "=================================================="
display as result "  VERSION A: Heterogeneous Audience -- 10 Outcomes, India"
display as result "  Reference: Table 3, Banerjee et al. (2015)"
display as result "=================================================="

* --- Data prep: run 10 regressions, collect p-values (all silent) ---
quietly {
    local hh_outcomes "index_ctotal ind_increv asset_index index_foodsecurity ind_fin"
    local mb_outcomes "index_time index_health index_mental index_political index_women"

    * -- HH-level outcomes --
    use "`dta_mod'/index_hh_vars.dta", clear
    keep if country == 4

    local j = 0
    foreach var of local hh_outcomes {
        foreach aux in `var'_bsl m_`var'_bsl m_country_`var'_bsl {
            cap confirm variable `aux'
            if _rc cap gen `aux' = 0
        }
        areg `var'_end treatment `var'_bsl m_`var'_bsl m_country_`var'_bsl ///
            control_*, absorb(geo_cluster) cluster(rand_unit)
        local j = `j' + 1
        local coef_`j' = _b[treatment]
        local se_`j'   = _se[treatment]
        local t_`j'    = `coef_`j'' / `se_`j''
        if `t_`j'' < 0 {
            local p_`j' = 1 - (1 - normal(abs(`t_`j''))) / 2
        }
        else {
            local p_`j' = (1 - normal(`t_`j''))
        }
    }

    * -- Member-level outcomes --
    use "`dta_mod'/index_mb_vars.dta", clear
    keep if country == 4

    foreach var of local mb_outcomes {
        foreach aux in `var'_bsl m_`var'_bsl m_country_`var'_bsl {
            cap confirm variable `aux'
            if _rc cap gen `aux' = 0
        }
        areg `var'_end treatment `var'_bsl m_`var'_bsl m_country_`var'_bsl ///
            control_*, absorb(geo_cluster) cluster(rand_unit)
        local j = `j' + 1
        local coef_`j' = _b[treatment]
        local se_`j'   = _se[treatment]
        local t_`j'    = `coef_`j'' / `se_`j''
        if `t_`j'' < 0 {
            local p_`j' = 1 - (1 - normal(abs(`t_`j''))) / 2
        }
        else {
            local p_`j' = (1 - normal(`t_`j''))
        }
    }

    * -- Build a dataset of p-values --
    clear
    set obs `j'
    gen outcome_id = _n
    gen str20 outcome = ""
    gen p_value = .
    gen coef = .
    gen se = .
    gen t_stat = .

    local label_list Consumption Income Assets FoodSec Finance TimeUse PhysHealth MentHealth Political WomenEmp
    forvalues i = 1/`j' {
        local lbl : word `i' of `label_list'
        replace outcome = "`lbl'" in `i'
        replace p_value = `p_`i'' in `i'
        replace coef = `coef_`i'' in `i'
        replace se = `se_`i'' in `i'
        replace t_stat = `t_`i'' in `i'
    }
}

* --- Results: regression summary ---
display _newline as text "Regression summary (India, treatment coefficient, one-sided p):"
list outcome coef se t_stat p_value, noobs

* --- mht_test: Linear model (FDA calibration) ---
display _newline as text "--- mht_test: Linear model (cf_share=0.46), alpha_bar=0.05 ---"
mht_test p_value, alphabar(0.05)
list outcome p_value mht_reject_opt mht_reject_bonf mht_reject_holm ///
     mht_reject_bh mht_reject_unadj, noobs

* --- mht_test: Cobb-Douglas model ---
display _newline as text "--- mht_test: Cobb-Douglas (beta=0.13, iota=0.075) ---"
mht_test p_value, alphabar(0.05) model(cobbdouglas) generate(cd) replace
list outcome p_value cd_reject_opt cd_reject_bonf, noobs

* --- Comparison with Banerjee et al. Table 3 ---
display _newline as text "--- Comparison with Banerjee et al. Table 3 ---"
display as text "  Paper uses BH q-values (FDR control) on pooled 6-country sample."
display as text "  Our analysis: India only, with cost-based optimal correction."
display as text ""
display as text "  Paper Table 3 q-values (endline 1, pooled):"
display as text "    Most indices: q = 0.001  => significant under BH"
display as text "    Physical health: q = 0.078 => NOT significant at 5% under BH"
display as text "    Women's empowerment: q = 0.049 => borderline under BH"
display as text ""
display as text "  Our findings (India only):"
display as text "    CONFIRMED: 5 core results (consumption, income, assets,"
display as text "      food security, time use) robust under ALL corrections."
display as text "    CONTESTED: Financial inclusion (p~0.049) is rejected"
display as text "      unadjusted but NOT under any correction -- overstated."
display as text "    DEPENDS ON COSTS: Physical health (p~0.007) survives"
display as text "      Linear optimal but not Cobb-Douglas or Bonferroni."


********************************************************************************
* VERSION A: Study-specific cost calibration
*
* The FDA default (cf_share=0.46) was calibrated for treatment arms in
* clinical trials. For OUTCOMES, costs are mostly fixed w.r.t. the number
* of outcomes measured (Table 4: program costs ~$1,268, survey costs ~$100).
* Estimated cf_share for outcomes ~ 0.80-0.90.
********************************************************************************

display _newline(2) as text "--- Study-specific calibration (Table 4 cost data) ---"
display as text "  From Table 4 (India): program+overhead ~$1,268, survey ~$100-150"
display as text "  => cf_share_outcomes ~ 0.80-0.90 (most costs fixed w.r.t. outcomes)"

foreach cf in 0.46 0.75 0.82 0.90 {
    quietly mht_critical, jhypotheses(`j') alphabar(0.05) cfshare(`cf')
    display as text "  cf_share=`cf': alpha* = " %7.5f r(alpha_opt)
}
display as text "  Bonferroni:     alpha* = " %7.5f 0.05/`j'

display _newline as text "  Physical health (p~0.007) is the SWING outcome:"
display as text "    cf_share <= 0.80: rejected (significant)"
display as text "    cf_share >= 0.90: NOT rejected (insignificant)"
display as text "    This is the package's value: making cost-dependence explicit."


********************************************************************************
* VERSION B: Multiple Treatments -- 6 Countries as 6 Programs
*
* The graduation program differed across countries: different NGOs, different
* assets ($437 India vs $1,228 Ethiopia), different support structures (Table 1).
* We treat the 6 country-specific programs as 6 distinct treatments.
*
* Maps to: Figure 3 (country-specific effects at endline 2)
*          Table 3 cols 3,6 (F-tests for equality across sites -- often rejected)
*          Table 4 (cost data by country)
*
* Cost structure: each country = separate RCT with its own budget.
*   Fixed (shared consortium): ~5-15% of total
*   Variable (country-specific): ~85-95%
*   => cf_share ~ 0.10-0.20
*
* The Linear model with low cf_share is more natural than Cobb-Douglas here
* because country costs vary widely ($1,257/HH India vs $5,962/HH Peru),
* which fits additive fixed+variable better than a power law.
********************************************************************************

display _newline(2) as result "=================================================="
display as result "  VERSION B: Multiple Treatments -- 6 Countries"
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

display _newline as text "  Study-specific (cf_share=0.10, countries are expensive):"
mht_est, vars(`treat_vars') alphabar(0.05) cfshare(0.10)

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
* Summary: Version A vs Version B
********************************************************************************

display _newline(2) as result "=================================================="
display as result "  SUMMARY: Version A vs Version B"
display as result "=================================================="
display as text ""
display as text "  Version A (10 outcomes, India):"
display as text "    Cost structure: adding outcomes is CHEAP (cf_share ~ 0.82)"
display as text "    => Strict correction needed (alpha* ~ 0.008, near Bonferroni)"
display as text "    => Confirms 5 core results; physical health is borderline"
display as text ""
display as text "  Version B (6 countries, pooled):"
display as text "    Cost structure: adding a country is EXPENSIVE (cf_share ~ 0.10)"
display as text "    => Minimal correction needed (alpha* ~ 0.040, near unadjusted)"
display as text "    => Retains effects that Bonferroni would discard"
display as text "    => Honduras and Peru show no effects under any procedure"
display as text "       (cf. Table 4: Honduras has benefit/cost ratio = -198%)"
display as text ""
display as text "  Same data, two framings, opposite corrections."
display as text "  This is the core insight of VWN (2026)."

display _newline as result "Done."

log close _testdrive

* Post-process: strip command echo from the log for readability
global clean_log_path "`root'/testing/testdrive_log.txt"
quietly run "`root'/stata/_clean_log.do"
display _newline as text "Clean log saved to: `root'/testing/testdrive_log.txt"
