* HOW TO RUN (either works):
*   cd "path/to/package_to_publish"
*   do "testing/full_analysis_case/analysis_part4_gradient.do"
* or:
*   cd "path/to/package_to_publish/testing/full_analysis_case"
*   do "analysis_part4_gradient.do"

clear all
set more off
version 14.0

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
            display as error "Please cd to package_to_publish/ or its testing/full_analysis_case/ subfolder."
            exit 601
        }
    }
}
local datadir "`root'/testing/data"

adopath + "`root'/stata"

capture log close _part4
log using "`root'/testing/full_analysis_case/part4_gradient_log.txt", replace text name(_part4)

* ==========================================================================
* PART 4: cf_share Gradient Analysis
*
* Vary cf_share from 0.00 to 0.50 (step 0.05, plus 0.23)
* Track: where L_cal rejects more/fewer/same as BH, and which countries
* J_bar = 6 throughout (calibrated to this study)
* ==========================================================================

display ""
display as text "{hline 70}"
display as result "  PART 4: cf_share Gradient (Exercise 2 Revisited)"
display as text "  Varying cf_share from 0.00 to 0.50, J_bar=6 throughout"
display as text "  BH benchmark: one-sided, alpha_bar=0.05"
display as text "{hline 70}"
display ""

local hhvars    index_ctotal ind_increv asset_index index_foodsecurity ind_fin
local adultvars index_time index_health index_mental index_political index_women
local allvars   `hhvars' `adultvars'
local outnames  Consumption Income Assets FoodSecurity FinInclusion TimeUse PhysHealth MentalHealth PolInvolve WomensEmp
local countries 1 2 3 4 5 6
local cnames Ethiopia Ghana Honduras India Pakistan Peru
local nout : word count `allvars'

* Initialize: one-sided p-values, two-sided p-values, BH rejection indicators
forvalues k = 1/`nout' {
    foreach t in end fup {
        matrix P1s_`k'_`t' = J(6, 1, .)
        matrix P2s_`k'_`t' = J(6, 1, .)
        matrix BH_`k'_`t'  = J(6, 1, .)
    }
}

* ============================================================
* PHASE 1: Run all regressions once, store p-values and BH
* ============================================================

display as result "=== Phase 1: Running regressions ==="
display ""

* --- HH data ---
use "`datadir'\pooled_hh.dta", clear

* Build financial inclusion index
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

* Build income index
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

* Build consumption index
cap drop index_ctotal*
foreach t in bsl end fup {
    gen index_ctotal_`t' = .
    forvalues i = 1/6 {
        qui sum ctotal_pcmonth_`t' if treatment==0 & country==`i' `=cond("`t'"=="bsl","& m_ctotal_pcmonth_`t'==0","")'
        if `r(N)'>0 replace index_ctotal_`t' = (ctotal_pcmonth_`t'-`r(mean)')/`r(sd)' if country==`i' `=cond("`t'"=="bsl","& m_ctotal_pcmonth_`t'==0","")'
    }
}

* Baseline controls
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

* Treatment dummies
forvalues i = 1/6 {
    gen byte treat_c`i' = (treatment==1 & country==`i')
}

* --- Run HH regressions ---
display as text "  Running HH regressions..."
local loop 1
foreach var in `hhvars' {
    local oname : word `loop' of `outnames'
    foreach t in end fup {
        local ssc ""
        if inlist("`var'","index_ctotal","ind_increv","ind_fin") & "`t'"=="end" {
            local ssc "css_g? css_p? css_h?"
        }

        local tvars ""
        forvalues i = 1/6 {
            qui count if !mi(`var'_`t') & country==`i'
            if `r(N)' > 0 local tvars "`tvars' treat_c`i'"
        }
        local J_eff : word count `tvars'
        scalar J_`loop'_`t' = `J_eff'

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
                    matrix P1s_`loop'_`t'[`i',1] = `p1s'
                    matrix P2s_`loop'_`t'[`i',1] = `p2s'
                }
            }

            * BH results (model choice irrelevant for BH, using CD)
            qui mht_est, vars(`tvars') alphabar(0.05) model(cobbdouglas) onesided
            scalar n_bh_`loop'_`t' = r(n_reject_bh)
            forvalues i = 1/6 {
                cap scalar _tmp = r(rej_bh_treat_c`i')
                if !_rc matrix BH_`loop'_`t'[`i',1] = scalar(_tmp)
            }

            display as text "    `oname'_`t': J=`J_eff'  BH=" as result string(scalar(n_bh_`loop'_`t'),"%1.0f")
        }
        else {
            scalar n_bh_`loop'_`t' = 0
        }
    }
    local loop = `loop' + 1
}

* --- MB data ---
use "`datadir'\pooled_mb.dta", clear
rename *mentalhealth* *mental*

cap drop index_time*
foreach t in bsl end fup {
    gen index_time_`t' = .
    forvalues i = 1/6 {
        qui sum time_work_`t' if treatment==0 & country==`i' `=cond("`t'"=="bsl","& m_time_work_bsl==0","")'
        if `r(N)'>0 replace index_time_`t' = (time_work_`t'-`r(mean)')/`r(sd)' if country==`i' `=cond("`t'"=="bsl","& m_time_work_bsl==0","")'
    }
}

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

forvalues i = 1/6 {
    gen byte treat_c`i' = (treatment==1 & country==`i')
}

display ""
display as text "  Running MB regressions..."
local loop 6
foreach var in `adultvars' {
    local oname : word `loop' of `outnames'
    foreach t in end fup {
        local ssc ""
        if "`var'"=="index_mental" & "`t'"=="end" local ssc "css_g? css_p? css_h?"

        local tvars ""
        forvalues i = 1/6 {
            qui count if !mi(`var'_`t') & country==`i'
            if `r(N)' > 0 local tvars "`tvars' treat_c`i'"
        }
        local J_eff : word count `tvars'
        scalar J_`loop'_`t' = `J_eff'

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
                    matrix P1s_`loop'_`t'[`i',1] = `p1s'
                    matrix P2s_`loop'_`t'[`i',1] = `p2s'
                }
            }

            qui mht_est, vars(`tvars') alphabar(0.05) model(cobbdouglas) onesided
            scalar n_bh_`loop'_`t' = r(n_reject_bh)
            forvalues i = 1/6 {
                cap scalar _tmp = r(rej_bh_treat_c`i')
                if !_rc matrix BH_`loop'_`t'[`i',1] = scalar(_tmp)
            }

            display as text "    `oname'_`t': J=`J_eff'  BH=" as result string(scalar(n_bh_`loop'_`t'),"%1.0f")
        }
        else {
            scalar n_bh_`loop'_`t' = 0
        }
    }
    local loop = `loop' + 1
}

display ""
display as result "  Phase 1 complete. P-values and BH results stored."
display ""

* ============================================================
* PHASE 2: cf_share Gradient
* ============================================================

display as text "{hline 70}"
display as result "  PHASE 2: cf_share Gradient"
display as text "{hline 70}"
display ""

* --- 2a. Alpha_opt table ---
display as result "=== Optimal Thresholds by cf_share ==="
display as text "  (One-sided, alpha_bar=0.05, J_bar=6, nm_ratio=1)"
display ""
display as text "  cf_share   alpha*(J=6)   alpha*(J=5)   2s equiv(J=6)"
display as text "  {hline 60}"

foreach cfs in 0.00 0.05 0.10 0.15 0.20 0.23 0.25 0.30 0.35 0.40 0.45 0.50 {
    qui mht_critical, jhypotheses(6) alphabar(0.05) model(linear) cfshare(`cfs') jbar(6) nmratio(1)
    local a6 = r(alpha_opt)
    qui mht_critical, jhypotheses(5) alphabar(0.05) model(linear) cfshare(`cfs') jbar(6) nmratio(1)
    local a5 = r(alpha_opt)
    local tag ""
    if `cfs' == 0.10 local tag " <-- Part 3 calibration"
    if `cfs' == 0.23 local tag " <-- ambiguous items as fixed"
    if `cfs' == 0.46 local tag " <-- FDA default (not shown in grid)"
    display as result "  " %5.2f `cfs' "     " %9.6f `a6' "     " %9.6f `a5' "     " %9.6f 2*`a6' as text "`tag'"
}
display as text "  {hline 60}"
display as text "  BH (J=6): step-up thresholds = k*0.05/6 for rank k"
display as text "    Rank 1: 0.00833  Rank 2: 0.01667  Rank 3: 0.02500"
display as text "    Rank 4: 0.03333  Rank 5: 0.04167  Rank 6: 0.05000"
display as text "  Bonferroni: 0.008333"
display ""

* --- 2b. Summary table ---
display as result "=== Rejection Counts by cf_share ==="
display as text "  Note: both L_cal and BH reject 'prefixes' of sorted p-values,"
display as text "  so equal counts => identical rejection sets (no composition changes)."
display ""

display as text "  cf_share  alpha*  TotL  TotBH  #(L>BH)  #(BH>L)  #(L=BH)"
display as text "  {hline 65}"

foreach cfs in 0.00 0.05 0.10 0.15 0.20 0.23 0.25 0.30 0.35 0.40 0.45 0.50 {
    qui mht_critical, jhypotheses(6) alphabar(0.05) model(linear) cfshare(`cfs') jbar(6) nmratio(1)
    local aopt6 = r(alpha_opt)
    qui mht_critical, jhypotheses(5) alphabar(0.05) model(linear) cfshare(`cfs') jbar(6) nmratio(1)
    local aopt5 = r(alpha_opt)

    local total_lcal = 0
    local total_bh = 0
    local n_lcal_gt_bh = 0
    local n_bh_gt_lcal = 0
    local n_equal = 0

    forvalues k = 1/`nout' {
        foreach t in end fup {
            local Jeff = scalar(J_`k'_`t')
            if `Jeff' == 0 continue
            local aopt = cond(`Jeff'==5, `aopt5', `aopt6')

            * Count L_cal rejections
            local n_lcal_cell = 0
            forvalues i = 1/6 {
                if P1s_`k'_`t'[`i',1] < . {
                    if P1s_`k'_`t'[`i',1] < `aopt' local n_lcal_cell = `n_lcal_cell' + 1
                }
            }

            local n_bh_cell = scalar(n_bh_`k'_`t')
            local total_lcal = `total_lcal' + `n_lcal_cell'
            local total_bh = `total_bh' + `n_bh_cell'

            if `n_lcal_cell' > `n_bh_cell' local n_lcal_gt_bh = `n_lcal_gt_bh' + 1
            else if `n_lcal_cell' < `n_bh_cell' local n_bh_gt_lcal = `n_bh_gt_lcal' + 1
            else local n_equal = `n_equal' + 1
        }
    }

    local tag ""
    if `cfs' == 0.10 local tag "  *"
    if `cfs' == 0.23 local tag "  **"
    display as result "  " %5.2f `cfs' "   " %7.5f `aopt6' "  " ///
        %3.0f `total_lcal' "    " %3.0f `total_bh' "      " ///
        %2.0f `n_lcal_gt_bh' "        " %2.0f `n_bh_gt_lcal' "        " ///
        %2.0f `n_equal' as text "`tag'"
}

display as text "  {hline 65}"
display as text "  * = Part 3 calibration (10%)   ** = ambiguous as fixed (23%)"
display as text "  TotL/TotBH = sum of country rejections across all 20 cells"
display as text "  #(L>BH) = number of outcome-period cells where L_cal rejects more"
display ""

* --- 2c. Detail: cells where L_cal != BH ---
display as result "=== Detail: Where L_cal and BH Differ ==="
display ""

foreach cfs in 0.00 0.05 0.10 0.15 0.20 0.23 0.25 0.30 0.35 0.40 0.45 0.50 {
    qui mht_critical, jhypotheses(6) alphabar(0.05) model(linear) cfshare(`cfs') jbar(6) nmratio(1)
    local aopt6 = r(alpha_opt)
    qui mht_critical, jhypotheses(5) alphabar(0.05) model(linear) cfshare(`cfs') jbar(6) nmratio(1)
    local aopt5 = r(alpha_opt)

    local has_diff = 0

    forvalues k = 1/`nout' {
        local oname : word `k' of `outnames'
        foreach t in end fup {
            local Jeff = scalar(J_`k'_`t')
            if `Jeff' == 0 continue
            local aopt = cond(`Jeff'==5, `aopt5', `aopt6')

            * Count L_cal rejections
            local n_lcal_cell = 0
            forvalues i = 1/6 {
                if P1s_`k'_`t'[`i',1] < . {
                    if P1s_`k'_`t'[`i',1] < `aopt' local n_lcal_cell = `n_lcal_cell' + 1
                }
            }

            local n_bh_cell = scalar(n_bh_`k'_`t')

            if `n_lcal_cell' != `n_bh_cell' {
                if `has_diff' == 0 {
                    display as result "--- cf_share = " %4.2f `cfs' "  (alpha*(J=6) = " %7.5f `aopt6' ") ---"
                    local has_diff = 1
                }

                local tname = cond("`t'"=="end","EL1","EL2")
                local dir = cond(`n_lcal_cell' > `n_bh_cell', "L > BH", "BH > L")
                display as text "  `oname' `tname': L_cal=`n_lcal_cell', BH=`n_bh_cell' (`dir')"

                * Show countries that differ between L_cal and BH
                forvalues i = 1/6 {
                    if P1s_`k'_`t'[`i',1] >= . continue
                    local cn : word `i' of `cnames'
                    local p1s = P1s_`k'_`t'[`i',1]
                    local bh_rej = BH_`k'_`t'[`i',1]
                    local lcal_rej = (`p1s' < `aopt')

                    if `lcal_rej' != `bh_rej' {
                        local ltag = cond(`lcal_rej'==1, "YES", "no")
                        local btag = cond(`bh_rej'==1,   "YES", "no")
                        display as text "    `cn': p1s=" %7.5f `p1s' "  L_cal=`ltag'  BH=`btag'"
                    }
                }
            }
        }
    }

    if `has_diff' == 0 {
        display as text "--- cf_share = " %4.2f `cfs' ": L_cal = BH everywhere ---"
    }
    display ""
}

* ============================================================
* PHASE 3: Full table at cf_share = 0.23 vs 0.10 (side by side)
* ============================================================

display as text "{hline 82}"
display as result "  Full Table: cf_share = 0.10 vs 0.23"
display as text "  (10% = Part 3 calibration; 23% = ambiguous items classified as fixed)"
display as text "{hline 82}"
display ""

* Compute thresholds
qui mht_critical, jhypotheses(6) alphabar(0.05) model(linear) cfshare(0.10) jbar(6) nmratio(1)
local a6_10 = r(alpha_opt)
qui mht_critical, jhypotheses(5) alphabar(0.05) model(linear) cfshare(0.10) jbar(6) nmratio(1)
local a5_10 = r(alpha_opt)

qui mht_critical, jhypotheses(6) alphabar(0.05) model(linear) cfshare(0.23) jbar(6) nmratio(1)
local a6_23 = r(alpha_opt)
qui mht_critical, jhypotheses(5) alphabar(0.05) model(linear) cfshare(0.23) jbar(6) nmratio(1)
local a5_23 = r(alpha_opt)

display as text "  cf_share=0.10: alpha*(J=6) = " as result %9.6f `a6_10' as text "  (2s = " as result %9.6f 2*`a6_10' as text ")"
display as text "  cf_share=0.23: alpha*(J=6) = " as result %9.6f `a6_23' as text "  (2s = " as result %9.6f 2*`a6_23' as text ")"
display ""

display as text "  {hline 86}"
display as text "  Outcome        |    EL1                      |    EL2                      |"
display as text "                 |  J  Naive  BH  L_10  L_23  |  J  Naive  BH  L_10  L_23  |"
display as text "  {hline 86}"

forvalues k = 1/`nout' {
    local oname : word `k' of `outnames'
    local rowname = "`oname'" + "                "
    local rowname = substr("`rowname'",1,15)
    local disprow "  `rowname' |"

    foreach t in end fup {
        local Jeff = scalar(J_`k'_`t')
        local n_bh = scalar(n_bh_`k'_`t')

        * Count naive (two-sided p < 0.10)
        local n_naive = 0
        forvalues i = 1/6 {
            if P2s_`k'_`t'[`i',1] < . {
                if P2s_`k'_`t'[`i',1] < 0.10 local n_naive = `n_naive' + 1
            }
        }

        * Count L_cal at cf_share=0.10
        local aopt10 = cond(`Jeff'==5, `a5_10', `a6_10')
        local n_l10 = 0
        forvalues i = 1/6 {
            if P1s_`k'_`t'[`i',1] < . {
                if P1s_`k'_`t'[`i',1] < `aopt10' local n_l10 = `n_l10' + 1
            }
        }

        * Count L_cal at cf_share=0.23
        local aopt23 = cond(`Jeff'==5, `a5_23', `a6_23')
        local n_l23 = 0
        forvalues i = 1/6 {
            if P1s_`k'_`t'[`i',1] < . {
                if P1s_`k'_`t'[`i',1] < `aopt23' local n_l23 = `n_l23' + 1
            }
        }

        local Jv    = string(`Jeff',   "%3.0f")
        local naivev = string(`n_naive', "%3.0f")
        local bhv   = string(`n_bh',   "%3.0f")
        local l10v  = string(`n_l10',  "%3.0f")
        local l23v  = string(`n_l23',  "%3.0f")
        local disprow "`disprow' `Jv'   `naivev'   `bhv'   `l10v'    `l23v'  |"
    }
    display as result "`disprow'"
}
display as text "  {hline 86}"
display as text "  Naive = two-sided p < 0.10"
display as text "  BH = BH step-up (one-sided, alpha_bar=0.05)"
display as text "  L_10 = VWN Linear (cf_share=0.10, J_bar=6)"
display as text "  L_23 = VWN Linear (cf_share=0.23, J_bar=6)"

* ============================================================
* PHASE 4: Sorted p-value grid by cf_share
* ============================================================

display ""
display as text "{hline 70}"
display as result "  PHASE 4: Sorted P-values with Rejection Grid"
display as text "  * = rejected at that cf_share; . = not rejected"
display as text "  Countries sorted by one-sided p-value (smallest first)"
display as text "  Column headers = cf_share values (×100)"
display as text "{hline 70}"
display ""

* Pre-compute alpha* for each cf_share at J=5 and J=6
local cfs_list 0.00 0.05 0.10 0.15 0.20 0.23 0.25 0.30 0.35 0.40 0.45 0.50
foreach cfs of local cfs_list {
    local cfstag = subinstr("`cfs'", ".", "p", .)
    qui mht_critical, jhypotheses(6) alphabar(0.05) model(linear) ///
        cfshare(`cfs') jbar(6) nmratio(1)
    local a6_`cfstag' = r(alpha_opt)
    qui mht_critical, jhypotheses(5) alphabar(0.05) model(linear) ///
        cfshare(`cfs') jbar(6) nmratio(1)
    local a5_`cfstag' = r(alpha_opt)
}

forvalues k = 1/`nout' {
    local oname : word `k' of `outnames'
    foreach t in end fup {
        local Jeff = scalar(J_`k'_`t')
        if `Jeff' == 0 continue
        local tname = cond("`t'"=="end","EL1","EL2")
        local nbh = scalar(n_bh_`k'_`t')

        display as result "`oname' `tname' (J=`Jeff', BH=`nbh'):"
        display as text "  Country     p1s      00  05  10  15  20  23  25  30  35  40  45  50  BH"
        display as text "  {hline 74}"

        * Collect valid p-values with country indices
        matrix _srt = J(`Jeff', 2, .)
        local nv = 0
        forvalues i = 1/6 {
            if P1s_`k'_`t'[`i',1] < . {
                local nv = `nv' + 1
                matrix _srt[`nv',1] = P1s_`k'_`t'[`i',1]
                matrix _srt[`nv',2] = `i'
            }
        }

        * Selection sort ascending by p1s
        forvalues a = 1/`=`nv'-1' {
            local minr = `a'
            local minv = _srt[`a',1]
            forvalues b = `=`a'+1'/`nv' {
                if _srt[`b',1] < `minv' {
                    local minr = `b'
                    local minv = _srt[`b',1]
                }
            }
            if `minr' != `a' {
                local s1 = _srt[`a',1]
                local s2 = _srt[`a',2]
                matrix _srt[`a',1] = _srt[`minr',1]
                matrix _srt[`a',2] = _srt[`minr',2]
                matrix _srt[`minr',1] = `s1'
                matrix _srt[`minr',2] = `s2'
            }
        }

        * Display each country row (sorted by p1s)
        forvalues r = 1/`nv' {
            local cidx = _srt[`r',2]
            local cn : word `cidx' of `cnames'
            local cnpad = substr("`cn'" + "          ", 1, 10)
            local p1s = _srt[`r',1]
            local bh_rej = BH_`k'_`t'[`cidx',1]
            local bhtag = cond(`bh_rej'==1, "  *", "  .")

            * Build grid: check p1s < alpha* at each cf_share
            local grid ""
            foreach cfs of local cfs_list {
                local cfstag = subinstr("`cfs'", ".", "p", .)
                local aopt = cond(`Jeff'==5, `a5_`cfstag'', `a6_`cfstag'')
                if `p1s' < `aopt' {
                    local grid "`grid'   *"
                }
                else {
                    local grid "`grid'   ."
                }
            }

            display as text "  `cnpad'" as result %7.5f `p1s' as text "`grid'`bhtag'"
        }
        display ""
    }
}

display ""
display as text "{hline 68}"
display as result "  PART 4 COMPLETE"
display as text "{hline 68}"

log close _part4

* Post-process: strip command echo from the log for readability
global clean_log_path "`root'/testing/full_analysis_case/part4_gradient_log.txt"
quietly run "`root'/stata/_clean_log.do"
