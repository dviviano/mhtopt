/*
================================================================================
  analysis_part2_treatments.do
  Banerjee et al. (2015) -- MHT Exercise 2: One Outcome x Multiple Treatments

  Applies VWN MHT as if there are J=6 treatment arms (one per country) and
  a single outcome at a time.

  Approach:
    Modify Equation 1 by replacing the single `treatment` dummy with 6
    country-specific treatment indicators: treat_c = treatment * I(country==c).
    Country FEs are absorbed by geo_cluster (clusters nest within countries).
    Run one pooled regression per outcome, yielding 6 treatment coefficients.

  For each of the 10 outcome families x 2 time periods (EL1/EL2):
    - Run pooled regression with 6 treatment arms
    - Apply mht_est with J=6 under Cobb-Douglas and Linear models
    - Report naive, BH-FDR, VWN-CD, VWN-Lin rejections

  Notes on costs (from testing_v2.txt discussion):
    - Cobb-Douglas may be more natural here: costs scale with treatment arms
      (each country arm is expensive to run)
    - Linear case also reported for comparison
    - J=6 for most outcomes; J=5 when an outcome is not collected in a country
      (Pakistan EL1: no mental health; India EL2: no women's empowerment)

  Countries: 1=Ethiopia 2=Ghana 3=Honduras 4=India 5=Pakistan 6=Peru
================================================================================
*/

clear all
set more off
version 14.0

* --------------------------------------------------------------------------
* Paths -- auto-detect package root
* HOW TO RUN (either works):
*   cd "path/to/package_to_publish"
*   do "testing/full_analysis_case/analysis_part2_treatments.do"
* or:
*   cd "path/to/package_to_publish/testing/full_analysis_case"
*   do "analysis_part2_treatments.do"
* --------------------------------------------------------------------------
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
            display as error "Please cd to package_to_publish/ or its testing/full_analysis_case/ subfolder."
            exit 601
        }
    }
}
local datadir "`root'/testing/data"

adopath + "`root'/stata"

capture log close _part2
log using "`root'/testing/full_analysis_case/part2_treatments_log.txt", replace text name(_part2)

* --------------------------------------------------------------------------
* Parameters
* --------------------------------------------------------------------------
local countries 1 2 3 4 5 6
local cnames    Ethiopia Ghana Honduras India Pakistan Peru
local hhvars    index_ctotal ind_increv asset_index index_foodsecurity ind_fin
local adultvars index_time index_health index_mental index_political index_women
local allvars   `hhvars' `adultvars'
local outnames  Consumption Income Assets FoodSecurity FinInclusion TimeUse PhysHealth MentalHealth PolInvolve WomensEmp

* --------------------------------------------------------------------------
* Result storage: R`k'_`t' is 6x8 matrix (rows=countries)
*   1=coeff 2=se 3=tstat 4=p2s 5=p1s 6=rej_cd 7=rej_lin 8=rej_bh
* --------------------------------------------------------------------------
local nout : word count `allvars'
forvalues k = 1/`nout' {
    foreach t in end fup {
        matrix R`k'_`t' = J(6, 8, .)
    }
}

/* =========================================================================
   PART A  Household-level data
   ========================================================================= */

display ""
display as text "{hline 70}"
display as result "  PART 2: One Outcome x J=6 Treatments (country-specific arms)"
display as text "{hline 70}"
display ""
display as text "  Loading HH data and constructing indices..."

use "`datadir'\pooled_hh.dta", clear

* -- Financial Inclusion index --
foreach t in bsl end fup {
    foreach var in loan_totalamt sav_totalamt sav_depositamt {
        gen z_`var'_`t' = .
        forvalues i = 1/6 {
            qui sum `var'_`t' if treatment==0 & country==`i' `=cond("`t'"=="bsl","& m_`var'_`t'==0","")'
            if `r(N)'>0 replace z_`var'_`t' = (`var'_`t'-`r(mean)')/`r(sd)' if country==`i' `=cond("`t'"=="bsl","& m_`var'_`t'==0","")'
        }
    }
    egen ind_fin_`t' = rowmean(z_loan_*_`t' z_sav_*_`t')
    forvalues i = 1/6 {
        qui sum ind_fin_`t' if treatment==0 & country==`i' `=cond("`t'"=="bsl","& !mi(ind_fin_bsl)","")'
        if `r(N)'>0 replace ind_fin_`t' = (ind_fin_`t'-`r(mean)')/`r(sd)' if country==`i'
    }
}

* -- Income and Revenue index --
cap drop ind_increv* z_ranimals* z_iagr* z_ibusiness* z_ipaid*
foreach t in bsl end fup {
    foreach var in ranimals_month iagri_month ibusiness_month ipaidlabor_month {
        gen z_`var'_`t' = .
        forvalues i = 1/6 {
            qui summ `var'_`t' if treatment==0 & country==`i' `=cond("`t'"=="bsl","& m_`var'_`t'==0","")'
            if `r(N)'>0 replace z_`var'_`t' = (`var'_`t'-`r(mean)')/`r(sd)' if country==`i' `=cond("`t'"=="bsl","& m_`var'_`t'==0","")'
        }
    }
    egen ind_increv_`t' = rowmean(z_ranim*_`t' z_iagri*_`t' z_ibus*_`t' z_ipaid*_`t')
    forvalues i = 1/6 {
        qui sum ind_increv_`t' if treatment==0 & country==`i' `=cond("`t'"=="bsl","& !mi(ind_increv_bsl)","")'
        if `r(N)'>0 replace ind_increv_`t' = (ind_increv_`t'-`r(mean)')/`r(sd)' if country==`i'
    }
}

* -- Total Consumption index --
cap drop index_ctotal*
foreach t in bsl end fup {
    gen index_ctotal_`t' = .
    forvalues i = 1/6 {
        qui sum ctotal_pcmonth_`t' if treatment==0 & country==`i' `=cond("`t'"=="bsl","& m_ctotal_pcmonth_`t'==0","")'
        if `r(N)'>0 replace index_ctotal_`t' = (ctotal_pcmonth_`t'-`r(mean)')/`r(sd)' if country==`i' `=cond("`t'"=="bsl","& m_ctotal_pcmonth_`t'==0","")'
    }
}

* -- Missing-baseline dummies --
foreach outcomevar in `hhvars' {
    cap confirm variable m_country_`outcomevar'_bsl
    if _rc!=0 {
        gen m_country_`outcomevar'_bsl = 0
        foreach country in `countries' {
            cap assert missing(`outcomevar'_bsl) if country==`country'
            if !_rc replace m_country_`outcomevar'_bsl = 1 if country==`country'
        }
    }
    cap confirm variable m_`outcomevar'_bsl
    if _rc!=0 {
        gen m_`outcomevar'_bsl = (mi(`outcomevar'_bsl) & m_country_`outcomevar'_bsl==0)
        replace `outcomevar'_bsl = 0 if m_`outcomevar'_bsl==1 | m_country_`outcomevar'_bsl==1
    }
}

* -- Country-specific treatment dummies --
forvalues i = 1/6 {
    gen byte treat_c`i' = (treatment==1 & country==`i')
}

* -- HH regressions --
display ""
display as text "  Running HH regressions..."

local loop 1
foreach var in `hhvars' {
    local oname : word `loop' of `outnames'
    foreach t in end fup {
        * Short-survey controls for specific vars at endline
        local ssc ""
        if inlist("`var'","index_ctotal","ind_increv","ind_fin") & "`t'"=="end" {
            local ssc "css_g? css_p? css_h?"
        }

        * Build varlist of treatment arms with nonmissing outcome
        local tvars ""
        forvalues i = 1/6 {
            qui count if !mi(`var'_`t') & country==`i'
            if `r(N)' > 0 local tvars "`tvars' treat_c`i'"
        }
        local J_eff : word count `tvars'

        if `J_eff' > 0 {
            * Run regression
            qui areg `var'_`t' `tvars' `var'_bsl m_`var'_bsl m_country_`var'_bsl control_* `ssc', absorb(geo_cluster) cluster(rand_unit)
            local df_r = e(df_r)

            * Extract per-country coefficients
            matrix b = e(b)
            matrix V = e(V)
            forvalues i = 1/6 {
                local pos = colnumb(b, "treat_c`i'")
                if `pos' < . {
                    local coeff = b[1,`pos']
                    local se    = sqrt(V[`pos',`pos'])
                    local tstat = `coeff'/`se'
                    local p2s   = 2*ttail(`df_r',abs(`tstat'))
                    local p1s   = cond(`tstat'>0,`p2s'/2,1-`p2s'/2)
                    matrix R`loop'_`t'[`i',1] = `coeff'
                    matrix R`loop'_`t'[`i',2] = `se'
                    matrix R`loop'_`t'[`i',3] = `tstat'
                    matrix R`loop'_`t'[`i',4] = `p2s'
                    matrix R`loop'_`t'[`i',5] = `p1s'
                }
            }

            * MHT: Cobb-Douglas (one-sided, alphabar=0.05)
            * mht_est reads from e(b)/e(V) saved at entry
            qui mht_est, vars(`tvars') alphabar(0.05) model(cobbdouglas) onesided
            scalar aopt_cd_`loop'_`t' = r(alpha_opt)
            local n_cd = r(n_reject_opt)
            local n_bh = r(n_reject_bh)
            * Store per-country CD and BH rejections
            forvalues i = 1/6 {
                cap scalar _tmp = r(rej_opt_treat_c`i')
                if !_rc matrix R`loop'_`t'[`i',6] = scalar(_tmp)
                cap scalar _tmp = r(rej_bh_treat_c`i')
                if !_rc matrix R`loop'_`t'[`i',8] = scalar(_tmp)
            }

            * MHT: Linear (one-sided, alphabar=0.05)
            qui mht_est, vars(`tvars') alphabar(0.05) model(linear) onesided
            scalar aopt_lin_`loop'_`t' = r(alpha_opt)
            local n_lin = r(n_reject_opt)
            * Store per-country Lin rejections
            forvalues i = 1/6 {
                cap scalar _tmp = r(rej_opt_treat_c`i')
                if !_rc matrix R`loop'_`t'[`i',7] = scalar(_tmp)
            }

            * Count naive rejections
            local n_n10 0
            local n_n5  0
            forvalues i = 1/6 {
                if R`loop'_`t'[`i',4] < . {
                    if R`loop'_`t'[`i',4] < 0.10 local n_n10 = `n_n10' + 1
                    if R`loop'_`t'[`i',4] < 0.05 local n_n5  = `n_n5'  + 1
                }
            }

            scalar J_`loop'_`t'     = `J_eff'
            scalar n_n10_`loop'_`t' = `n_n10'
            scalar n_n5_`loop'_`t'  = `n_n5'
            scalar n_bh_`loop'_`t'  = `n_bh'
            scalar n_cd_`loop'_`t'  = `n_cd'
            scalar n_lin_`loop'_`t' = `n_lin'

            display as text "    `oname'_`t': J=" as result %1.0f `J_eff' as text "  N10=" as result `n_n10' as text "  N5=" as result `n_n5' as text "  BH=" as result `n_bh' as text "  CD=" as result `n_cd' as text "  Lin=" as result `n_lin'
        }
        else {
            scalar J_`loop'_`t'       = 0
            scalar n_n10_`loop'_`t'   = 0
            scalar n_n5_`loop'_`t'    = 0
            scalar n_bh_`loop'_`t'    = 0
            scalar n_cd_`loop'_`t'    = 0
            scalar n_lin_`loop'_`t'   = 0
            scalar aopt_cd_`loop'_`t' = .
            scalar aopt_lin_`loop'_`t'= .
            display as text "    `oname'_`t': J=0 (no observations)"
        }
    }
    local loop = `loop' + 1
}

/* =========================================================================
   PART B  Member-level data
   ========================================================================= */

display ""
display as text "  Loading MB data and constructing indices..."

use "`datadir'\pooled_mb.dta", clear
rename *mentalhealth* *mental*

* -- Time Use index --
cap drop index_time*
foreach t in bsl end fup {
    gen index_time_`t' = .
    forvalues i = 1/6 {
        qui sum time_work_`t' if treatment==0 & country==`i' `=cond("`t'"=="bsl","& m_time_work_bsl==0","")'
        if `r(N)'>0 replace index_time_`t' = (time_work_`t'-`r(mean)')/`r(sd)' if country==`i' `=cond("`t'"=="bsl","& m_time_work_bsl==0","")'
    }
}

* -- Missing-baseline dummies --
foreach outcomevar in `adultvars' {
    cap confirm variable m_country_`outcomevar'_bsl
    if _rc!=0 {
        gen m_country_`outcomevar'_bsl = 0
        foreach country in `countries' {
            cap assert missing(`outcomevar'_bsl) if country==`country'
            if !_rc replace m_country_`outcomevar'_bsl = 1 if country==`country'
        }
    }
    cap confirm variable m_`outcomevar'_bsl
    if _rc!=0 {
        gen m_`outcomevar'_bsl = 0
        replace m_`outcomevar'_bsl = 1 if mi(`outcomevar'_bsl)
        replace `outcomevar'_bsl = 0 if m_`outcomevar'_bsl==1 | m_country_`outcomevar'_bsl==1
    }
}

* -- Country-specific treatment dummies --
forvalues i = 1/6 {
    gen byte treat_c`i' = (treatment==1 & country==`i')
}

* -- MB regressions --
display ""
display as text "  Running MB regressions..."

local loop 6
foreach var in `adultvars' {
    local oname : word `loop' of `outnames'
    foreach t in end fup {
        * Short-survey controls
        local ssc ""
        if "`var'"=="index_mental" & "`t'"=="end" local ssc "css_g? css_p? css_h?"

        * Build varlist of treatment arms with nonmissing outcome
        local tvars ""
        forvalues i = 1/6 {
            qui count if !mi(`var'_`t') & country==`i'
            if `r(N)' > 0 local tvars "`tvars' treat_c`i'"
        }
        local J_eff : word count `tvars'

        if `J_eff' > 0 {
            qui areg `var'_`t' `tvars' `var'_bsl m_`var'_bsl m_country_`var'_bsl control_* `ssc', absorb(geo_cluster) cluster(rand_unit)
            local df_r = e(df_r)

            matrix b = e(b)
            matrix V = e(V)
            forvalues i = 1/6 {
                local pos = colnumb(b, "treat_c`i'")
                if `pos' < . {
                    local coeff = b[1,`pos']
                    local se    = sqrt(V[`pos',`pos'])
                    local tstat = `coeff'/`se'
                    local p2s   = 2*ttail(`df_r',abs(`tstat'))
                    local p1s   = cond(`tstat'>0,`p2s'/2,1-`p2s'/2)
                    matrix R`loop'_`t'[`i',1] = `coeff'
                    matrix R`loop'_`t'[`i',2] = `se'
                    matrix R`loop'_`t'[`i',3] = `tstat'
                    matrix R`loop'_`t'[`i',4] = `p2s'
                    matrix R`loop'_`t'[`i',5] = `p1s'
                }
            }

            * MHT: Cobb-Douglas
            qui mht_est, vars(`tvars') alphabar(0.05) model(cobbdouglas) onesided
            scalar aopt_cd_`loop'_`t' = r(alpha_opt)
            local n_cd = r(n_reject_opt)
            local n_bh = r(n_reject_bh)
            forvalues i = 1/6 {
                cap scalar _tmp = r(rej_opt_treat_c`i')
                if !_rc matrix R`loop'_`t'[`i',6] = scalar(_tmp)
                cap scalar _tmp = r(rej_bh_treat_c`i')
                if !_rc matrix R`loop'_`t'[`i',8] = scalar(_tmp)
            }

            * MHT: Linear
            qui mht_est, vars(`tvars') alphabar(0.05) model(linear) onesided
            scalar aopt_lin_`loop'_`t' = r(alpha_opt)
            local n_lin = r(n_reject_opt)
            forvalues i = 1/6 {
                cap scalar _tmp = r(rej_opt_treat_c`i')
                if !_rc matrix R`loop'_`t'[`i',7] = scalar(_tmp)
            }

            local n_n10 0
            local n_n5  0
            forvalues i = 1/6 {
                if R`loop'_`t'[`i',4] < . {
                    if R`loop'_`t'[`i',4] < 0.10 local n_n10 = `n_n10' + 1
                    if R`loop'_`t'[`i',4] < 0.05 local n_n5  = `n_n5'  + 1
                }
            }

            scalar J_`loop'_`t'     = `J_eff'
            scalar n_n10_`loop'_`t' = `n_n10'
            scalar n_n5_`loop'_`t'  = `n_n5'
            scalar n_bh_`loop'_`t'  = `n_bh'
            scalar n_cd_`loop'_`t'  = `n_cd'
            scalar n_lin_`loop'_`t' = `n_lin'

            display as text "    `oname'_`t': J=" as result %1.0f `J_eff' as text "  N10=" as result `n_n10' as text "  N5=" as result `n_n5' as text "  BH=" as result `n_bh' as text "  CD=" as result `n_cd' as text "  Lin=" as result `n_lin'
        }
        else {
            scalar J_`loop'_`t'       = 0
            scalar n_n10_`loop'_`t'   = 0
            scalar n_n5_`loop'_`t'    = 0
            scalar n_bh_`loop'_`t'    = 0
            scalar n_cd_`loop'_`t'    = 0
            scalar n_lin_`loop'_`t'   = 0
            scalar aopt_cd_`loop'_`t' = .
            scalar aopt_lin_`loop'_`t'= .
            display as text "    `oname'_`t': J=0 (no observations)"
        }
    }
    local loop = `loop' + 1
}

/* =========================================================================
   PART C  Summary Table  -- significance at 10% level
   ========================================================================= */

display ""
display as text "{hline 90}"
display as result "  SUMMARY TABLE: MHT Exercise 2 -- One Outcome x J=6 Treatments"
display as text "  Banerjee et al. (2015)  |  Viviano, Wuthrich & Niehaus (2026)"
display as text "{hline 90}"
display ""
display as text "  Each row = one outcome family. J = number of country-treatment arms."
display as text "  Cells = number of countries (out of J) with significant treatment effect."
display as text ""
display as text "  All results shown at 10% significance level:"
display as text "  Naive  = two-sided p < 0.10"
display as text "  BH     = BH/FDR (one-sided, alphabar=0.05)"
display as text "  VWN-CD = Cobb-Douglas optimal (alpha_bar=0.05 one-sided)"
display as text "  VWN-Lin= Linear/FDA optimal   (alpha_bar=0.05 one-sided)"
display ""
display as text "  VWN Optimal alpha_opt (one-sided) for J=6:"
display as text "    CD =" as result %8.6f scalar(aopt_cd_1_end) as text "  Lin =" as result %8.6f scalar(aopt_lin_1_end)
display as text "  (Two-sided equiv: CD=" as result %6.4f 2*scalar(aopt_cd_1_end) as text " Lin=" as result %6.4f 2*scalar(aopt_lin_1_end) as text ")"
display ""

* Table header
display as text "  {hline 72}"
display as text "  Outcome        |   EL1 (endline)           |   EL2 (follow-up)         |"
display as text "                 |  J  Naive   BH  VWN-CD Lin|  J  Naive   BH  VWN-CD Lin|"
display as text "  {hline 72}"

forvalues k = 1/`nout' {
    local oname : word `k' of `outnames'
    local rowname = "`oname'" + "                "
    local rowname = substr("`rowname'",1,15)
    local disprow "  `rowname' |"
    foreach t in end fup {
        local Jv   = string(scalar(J_`k'_`t'),     "%3.0f")
        local n10v = string(scalar(n_n10_`k'_`t'), "%3.0f")
        local bhv  = string(scalar(n_bh_`k'_`t'),  "%3.0f")
        local cdv  = string(scalar(n_cd_`k'_`t'),  "%3.0f")
        local linv = string(scalar(n_lin_`k'_`t'), "%3.0f")
        local disprow "`disprow' `Jv'   `n10v'   `bhv'    `cdv'   `linv' |"
    }
    display as result "`disprow'"
}
display as text "  {hline 72}"

/* =========================================================================
   PART D  Per-outcome detail tables  (10% significance)
   ========================================================================= */

display ""
display as text "{hline 90}"
display as result "  PART D: Per-outcome detail (6 country-treatment arms)"
display as text "{hline 90}"
display as text "  Significance at 10%: * = significant, . = not significant, - = not collected"
display as text "  Naive = two-sided p < 0.10 | BH/CD/Lin at alpha_bar=0.05 one-sided"

forvalues k = 1/`nout' {
    local oname : word `k' of `outnames'
    foreach t in end fup {
        if "`t'"=="end" local rlabel "EL1 (endline)"
        else            local rlabel "EL2 (follow-up)"
        local Jv = scalar(J_`k'_`t')
        if `Jv'==0 continue

        display ""
        display as text "  -- `oname'  `rlabel'  J=`Jv' --"
        display as text "  Country          Coeff     (SE)    p(2s)  Naive   BH   CD   Lin"
        display as text "  {hline 66}"

        forvalues i = 1/6 {
            local cn : word `i' of `cnames'
            local cnpad = "`cn'" + "                "
            local cnpad = substr("`cnpad'",1,15)

            local coeff_i = R`k'_`t'[`i',1]
            if mi(`coeff_i') {
                display as text "  `cnpad'   -         -       -      -     -    -    -"
            }
            else {
                local scoeff = string(R`k'_`t'[`i',1], "%8.4f")
                local sse    = string(R`k'_`t'[`i',2], "%7.4f")
                local sp2    = string(R`k'_`t'[`i',4], "%7.4f")
                local s_n10  = cond(R`k'_`t'[`i',4] < 0.10, "*", ".")
                local s_cd   = cond(R`k'_`t'[`i',6]==1, "*", ".")
                local s_lin  = cond(R`k'_`t'[`i',7]==1, "*", ".")
                local s_bh   = cond(R`k'_`t'[`i',8]==1, "*", ".")
                display as result "  `cnpad' `scoeff' (`sse') `sp2'    `s_n10'     `s_bh'    `s_cd'    `s_lin'"
            }
        }
    }
}

/* =========================================================================
   PART E  Cost model discussion
   ========================================================================= */

display ""
display as text "{hline 70}"
display as result "  DISCUSSION: Cost Models for Multiple Treatments"
display as text "{hline 70}"
display ""
display as text "  In Exercise 2, J=6 represents treatment arms across countries."
display as text "  Each arm requires separate implementation in a different country,"
display as text "  implying costs that scale with the number of arms."
display ""
display as text "  Cobb-Douglas (beta=0.13, iota=0.075):"
display as text "    - Costs scale smoothly with J (treatment arms)"
display as text "    - Natural fit: each country arm is expensive to implement"
display as text "    - For J=6: alpha_opt =" as result %8.6f scalar(aopt_cd_1_end)
display ""
display as text "  Linear/FDA (cfshare=0.46, jbar=3):"
display as text "    - Fixed cost per additional test"
display as text "    - For J=6: alpha_opt =" as result %8.6f scalar(aopt_lin_1_end)
display ""
display as text "  Comparison for J=6 (one-sided thresholds):"
display as text "    Bonferroni:    0.05/6 = 0.0083"
display as text "    VWN-CD:       " as result %8.6f scalar(aopt_cd_1_end)
display as text "    VWN-Lin:      " as result %8.6f scalar(aopt_lin_1_end)
display as text "    Unadjusted:   0.05"
display ""

display ""
display as text "{hline 68}"
display as result "  EXERCISE 2 COMPLETE"
display as text "{hline 68}"
display ""

log close _part2

* Post-process: strip command echo from the log for readability
global clean_log_path "`root'/testing/full_analysis_case/part2_treatments_log.txt"
quietly run "`root'/stata/_clean_log.do"

exit
