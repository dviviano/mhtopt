* HOW TO RUN (either works):
*   cd "path/to/mhtopt"
*   do "testing/full_analysis_case/analysis_part3_calibration.do"
* or:
*   cd "path/to/mhtopt/testing/full_analysis_case"
*   do "analysis_part3_calibration.do"

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
            display as error "Please cd to mhtopt/ or its testing/full_analysis_case/ subfolder."
            exit 601
        }
    }
}
local datadir "`root'/testing/data"

adopath + "`root'/stata"

capture log close _part3
log using "`root'/testing/full_analysis_case/part3_calibration_log.txt", replace text name(_part3)

/* =========================================================================
   PART 3: Cost Calibration using Banerjee et al. Table 4 Panel A
   ========================================================================= */

display ""
display as text "{hline 70}"
display as result "  PART 3: Cost Calibration from Table 4, Panel A"
display as text "{hline 70}"

* ==========================================================================
* A. Get sample sizes per country arm from the actual data
* ==========================================================================

* --- HH data ---
use "`datadir'\pooled_hh.dta", clear
display ""
display as result "=== HH-level sample sizes ==="

* Total obs per country
forvalues i = 1/6 {
    qui count if country==`i'
    local n_all_`i' = r(N)
    qui count if country==`i' & treatment==1
    local n_treat_`i' = r(N)
    qui count if country==`i' & treatment==0
    local n_ctrl_`i' = r(N)
}

local cnames Ethiopia Ghana Honduras India Pakistan Peru
forvalues i = 1/6 {
    local cn : word `i' of `cnames'
    display as text "  `cn': Total=" as result `n_all_`i'' ///
        as text "  Treated=" as result `n_treat_`i'' ///
        as text "  Control=" as result `n_ctrl_`i''
}

* Total across countries
local N_total = 0
local N_treat_total = 0
forvalues i = 1/6 {
    local N_total = `N_total' + `n_all_`i''
    local N_treat_total = `N_treat_total' + `n_treat_`i''
}
display as text "  TOTAL: N=" as result `N_total' as text "  Treated=" as result `N_treat_total'

* --- MB data ---
use "`datadir'\pooled_mb.dta", clear
display ""
display as result "=== MB-level sample sizes ==="
forvalues i = 1/6 {
    qui count if country==`i'
    local mb_all_`i' = r(N)
    qui count if country==`i' & treatment==1
    local mb_treat_`i' = r(N)
}
forvalues i = 1/6 {
    local cn : word `i' of `cnames'
    display as text "  `cn': Total=" as result `mb_all_`i'' ///
        as text "  Treated=" as result `mb_treat_`i''
}

* ==========================================================================
* B. Table 4 Panel A costs (2014 USD PPP, per participant)
* ==========================================================================

display ""
display as result "=== Table 4 Panel A: Cost per Participant (2014 USD PPP) ==="
display ""

* Total Costs at beginning of year 0
local cost_pp_1 = 3591.24   /* Ethiopia */
local cost_pp_2 = 4672.05   /* Ghana */
local cost_pp_3 = 2669.65   /* Honduras */
local cost_pp_4 = 1256.75   /* India */
local cost_pp_5 = 5150.14   /* Pakistan */
local cost_pp_6 = 4959.76   /* Peru */

* Direct Transfer Costs per participant (clearly variable: assets + food)
local transfer_pp_1 = 1227.87  /* Ethiopia */
local transfer_pp_2 = 680.21   /* Ghana */
local transfer_pp_3 = 723.75   /* Honduras */
local transfer_pp_4 = 699.83   /* India */
local transfer_pp_5 = 2048.15  /* Pakistan */
local transfer_pp_6 = 1095.12  /* Peru */

* Supervision costs per participant (partially fixed per arm)
local super_pp_1 = 1899.54   /* Ethiopia */
local super_pp_2 = 2832.41   /* Ghana */
local super_pp_3 = 1632.56   /* Honduras */
local super_pp_4 = 406.83    /* India */
local super_pp_5 = .         /* Pakistan: missing ("-") */
local super_pp_6 = 3357.09   /* Peru */

* Indirect + Start-up per participant
local overhead_pp_1 = 420.62 + 43.21  /* Ethiopia */
local overhead_pp_2 = 1026.32 + 133.11 /* Ghana */
local overhead_pp_3 = 208.89 + 104.44  /* Honduras */
local overhead_pp_4 = 111.82 + 38.27   /* India */
local overhead_pp_5 = 470.36           /* Pakistan (startup missing) */
local overhead_pp_6 = 462.09 + 45.46   /* Peru */

display as text "  Country        Total/pp  Transfer/pp  Super/pp  Overhead/pp"
display as text "  {hline 62}"
forvalues i = 1/6 {
    local cn : word `i' of `cnames'
    local cnpad = "`cn'" + "              "
    local cnpad = substr("`cnpad'",1,14)
    display as result "  `cnpad'" %9.0f `cost_pp_`i'' "   " ///
        %9.0f `transfer_pp_`i'' "   " ///
        %9.0f `super_pp_`i'' "   " ///
        %9.0f `overhead_pp_`i''
}

* ==========================================================================
* C. Compute total program costs per arm
* ==========================================================================

display ""
display as result "=== Total Program Costs per Country Arm ==="
display as text "  (Cost per participant x N treated)"
display ""

local total_cost = 0
local total_transfer = 0
local total_treated = 0

display as text "  Country        N_treat  Cost/pp    Arm Cost     Transfer Cost"
display as text "  {hline 66}"
forvalues i = 1/6 {
    local cn : word `i' of `cnames'
    local cnpad = "`cn'" + "              "
    local cnpad = substr("`cnpad'",1,14)

    local arm_cost_`i' = `cost_pp_`i'' * `n_treat_`i''
    local arm_transfer_`i' = `transfer_pp_`i'' * `n_treat_`i''

    display as result "  `cnpad'" %6.0f `n_treat_`i'' "   $" ///
        %8.0f `cost_pp_`i'' "  $" %12.0f `arm_cost_`i'' ///
        "  $" %12.0f `arm_transfer_`i''

    local total_cost = `total_cost' + `arm_cost_`i''
    local total_transfer = `total_transfer' + `arm_transfer_`i''
    local total_treated = `total_treated' + `n_treat_`i''
}
display as text "  {hline 66}"
display as result "  TOTAL          " %6.0f `total_treated' ///
    "             $" %12.0f `total_cost' ///
    "  $" %12.0f `total_transfer'

* ==========================================================================
* D. Calibrate cf_share
* ==========================================================================

display ""
display as result "=== Cost Decomposition for cf_share Calibration ==="
display ""

* --- Cost categorization (Banerjee Table 4 Panel A line items) ---
* Following results_note.pdf, classify Table 4 Panel A costs as:
*   Variable with J (staff, assets, food, travel, materials)   ~ 66%
*   Per-arm, scales with J (training & start-up)                ~  8%
*   Ambiguous (indirect + other supervision) -- treated as      ~ 23%
*     FIXED as a CONSERVATIVE upper bound on the fixed share
*   Study-wide coordination (unobserved, small)                  J-fixed
*
* Conservative calibration: treat the ambiguous ~23% as fixed.
local cf_cal = 0.23

display as text "  Cost categorization (Table 4 Panel A; see results_note.pdf):"
display as text "    Variable with J (staff/assets/food/travel/materials): ~66%"
display as text "    Per-arm (training & start-up):                          ~8%"
display as text "    Ambiguous (indirect + supervision) -> treated as FIXED: ~23%"
display as text "    Study-wide coordination (unobserved):                   small"
display ""
display as text "  Conservative calibration (ambiguous items as fixed):"
display as text "    cf_share = " as result %4.2f `cf_cal' as text "  (upper bound on the fixed share)"
display ""

* Context: direct transfers (assets + food) are unambiguously variable
local transfer_share = `total_transfer' / `total_cost'
display as text "  (For reference, direct transfers alone = " as result %4.2f `transfer_share' ///
    as text " of total cost; clearly variable.)"

* Average cost per arm
local avg_arm_cost = `total_cost' / 6
display as text "  Average arm cost: $" as result %12.0f `avg_arm_cost'

display ""
display as result "=== Calibrated alpha_opt under Linear Model ==="
display as text "  J=6, alpha_bar=0.05, one-sided"
display ""

* Compute n_bar / m_bar ratio
* n_bar = average per-arm sample (total obs / 6)
* m_bar = benchmark single-arm experiment size
* For Banerjee: total N ≈ 10,000, so n_bar ≈ 1,667
* Benchmark: median J-PAL study has ~1000-2000 per arm (use n/m = 1 as default)

local n_bar = `N_total' / 6
display as text "  n_bar (avg obs per arm): " as result %8.0f `n_bar'
display ""

* Scenario analysis: vary cf_share
display as text "  cf_share   J_bar  alpha_opt(1s)  alpha_opt(2s)  Interpretation"
display as text "  {hline 72}"

foreach cfs in 0.00 0.05 0.10 0.15 0.20 0.23 0.30 0.46 {
    * Use J_bar = 6 (this study's own arm count as reference)
    qui mht_critical, jhypotheses(6) alphabar(0.05) model(linear) ///
        cfshare(`cfs') jbar(6) nmratio(1)
    local a1 = r(alpha_opt)
    local a2 = 2 * `a1'
    local interp = ""
    if `cfs' == 0    local interp "No fixed costs => no correction"
    if `cfs' == 0.05 local interp "~5% fixed (minimal coordination)"
    if `cfs' == 0.10 local interp "~10% fixed (moderate coordination)"
    if `cfs' == 0.15 local interp "~15% fixed (substantial coordination)"
    if `cfs' == 0.20 local interp "~20% fixed (generous upper bound)"
    if `cfs' == 0.23 local interp "CALIBRATED: ambiguous items as fixed"
    if `cfs' == 0.46 local interp "FDA pharma default"
    display as result "  " %5.2f `cfs' "      6     " %9.6f `a1' ///
        "      " %9.6f `a2' as text "  `interp'"
}

display as text "  {hline 72}"
display as text "  Bonferroni:             " %9.6f 0.05/6
display as text "  Unadjusted:             " %9.6f 0.05
display ""

* Also show what happens with J_bar = 3 (J-PAL average)
display as result "=== Sensitivity: J_bar = 3 (J-PAL average) ==="
display as text "  cf_share   J_bar  alpha_opt(1s)  alpha_opt(2s)"
display as text "  {hline 55}"
foreach cfs in 0.00 0.05 0.10 0.15 0.20 0.46 {
    qui mht_critical, jhypotheses(6) alphabar(0.05) model(linear) ///
        cfshare(`cfs') jbar(3) nmratio(1)
    local a1 = r(alpha_opt)
    display as result "  " %5.2f `cfs' "      3     " %9.6f `a1' ///
        "      " %9.6f 2*`a1'
}
display as text "  {hline 55}"

* ==========================================================================
* E. Re-run Exercise 2 with calibrated linear model (cf_share = 0.10)
* ==========================================================================

display ""
display as text "{hline 70}"
display as result "  Exercise 2 with CALIBRATED Linear Model (cf_share=0.23, J_bar=6)"
display as text "{hline 70}"
display ""

* Preferred calibration: cf_share = 0.23 (results_note.pdf).
* Rationale: treat the ambiguous ~23% (indirect + supervision) as FIXED, a
* conservative upper bound; the remaining ~74% (variable + per-arm training)
* scales with J. At J=6 this gives alpha* ~ 0.023 one-sided (0.047 two-sided).

local cal_cfs = `cf_cal'
local cal_jbar = 6

* --- Load HH data ---
use "`datadir'\pooled_hh.dta", clear

local hhvars    index_ctotal ind_increv asset_index index_foodsecurity ind_fin
local adultvars index_time index_health index_mental index_political index_women
local allvars   `hhvars' `adultvars'
local outnames  Consumption Income Assets FoodSecurity FinInclusion TimeUse PhysHealth MentalHealth PolInvolve WomensEmp
local countries 1 2 3 4 5 6

* Build indices (same as part2)
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

cap drop index_ctotal*
foreach t in bsl end fup {
    gen index_ctotal_`t' = .
    forvalues i = 1/6 {
        qui sum ctotal_pcmonth_`t' if treatment==0 & country==`i' `=cond("`t'"=="bsl","& m_ctotal_pcmonth_`t'==0","")'
        if `r(N)'>0 replace index_ctotal_`t' = (ctotal_pcmonth_`t'-`r(mean)')/`r(sd)' if country==`i' `=cond("`t'"=="bsl","& m_ctotal_pcmonth_`t'==0","")'
    }
}

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

forvalues i = 1/6 {
    gen byte treat_c`i' = (treatment==1 & country==`i')
}

* Storage: 10 outcomes x 2 periods x 8 cols
local nout : word count `allvars'
forvalues k = 1/`nout' {
    foreach t in end fup {
        matrix R`k'_`t' = J(6, 10, .)
        * cols: 1=coef 2=se 3=t 4=p2s 5=p1s 6=rej_cd 7=rej_lin_default 8=rej_bh 9=rej_lin_cal 10=rej_cd_cal
    }
}

* --- HH regressions ---
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

            * Default CD
            qui mht_est, vars(`tvars') alphabar(0.05) model(cobbdouglas) onesided
            local n_cd = r(n_reject_opt)
            local n_bh = r(n_reject_bh)
            forvalues i = 1/6 {
                cap scalar _tmp = r(rej_opt_treat_c`i')
                if !_rc matrix R`loop'_`t'[`i',6] = scalar(_tmp)
                cap scalar _tmp = r(rej_bh_treat_c`i')
                if !_rc matrix R`loop'_`t'[`i',8] = scalar(_tmp)
            }

            * Default Linear
            qui mht_est, vars(`tvars') alphabar(0.05) model(linear) onesided
            local n_lin_def = r(n_reject_opt)
            scalar aopt_lindef_`loop'_`t' = r(alpha_opt)
            forvalues i = 1/6 {
                cap scalar _tmp = r(rej_opt_treat_c`i')
                if !_rc matrix R`loop'_`t'[`i',7] = scalar(_tmp)
            }

            * CALIBRATED Linear (cf_share=0.10, J_bar=6)
            qui mht_est, vars(`tvars') alphabar(0.05) model(linear) ///
                cfshare(`cal_cfs') jbar(`cal_jbar') onesided
            local n_lin_cal = r(n_reject_opt)
            scalar aopt_lincal_`loop'_`t' = r(alpha_opt)
            forvalues i = 1/6 {
                cap scalar _tmp = r(rej_opt_treat_c`i')
                if !_rc matrix R`loop'_`t'[`i',9] = scalar(_tmp)
            }

            * Count naive
            local n_n10 0
            forvalues i = 1/6 {
                if R`loop'_`t'[`i',4] < . {
                    if R`loop'_`t'[`i',4] < 0.10 local n_n10 = `n_n10' + 1
                }
            }

            scalar J_`loop'_`t'         = `J_eff'
            scalar n_n10_`loop'_`t'     = `n_n10'
            scalar n_bh_`loop'_`t'      = `n_bh'
            scalar n_cd_`loop'_`t'      = `n_cd'
            scalar n_lindef_`loop'_`t'  = `n_lin_def'
            scalar n_lincal_`loop'_`t'  = `n_lin_cal'

            display as text "    `oname'_`t': J=`J_eff'  N10=`n_n10'  BH=`n_bh'  CD=`n_cd'  Lin_def=`n_lin_def'  Lin_cal=`n_lin_cal'"
        }
        else {
            scalar J_`loop'_`t' = 0
            scalar n_n10_`loop'_`t' = 0
            scalar n_bh_`loop'_`t' = 0
            scalar n_cd_`loop'_`t' = 0
            scalar n_lindef_`loop'_`t' = 0
            scalar n_lincal_`loop'_`t' = 0
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

            qui mht_est, vars(`tvars') alphabar(0.05) model(cobbdouglas) onesided
            local n_cd = r(n_reject_opt)
            local n_bh = r(n_reject_bh)
            forvalues i = 1/6 {
                cap scalar _tmp = r(rej_opt_treat_c`i')
                if !_rc matrix R`loop'_`t'[`i',6] = scalar(_tmp)
                cap scalar _tmp = r(rej_bh_treat_c`i')
                if !_rc matrix R`loop'_`t'[`i',8] = scalar(_tmp)
            }

            qui mht_est, vars(`tvars') alphabar(0.05) model(linear) onesided
            local n_lin_def = r(n_reject_opt)
            scalar aopt_lindef_`loop'_`t' = r(alpha_opt)
            forvalues i = 1/6 {
                cap scalar _tmp = r(rej_opt_treat_c`i')
                if !_rc matrix R`loop'_`t'[`i',7] = scalar(_tmp)
            }

            qui mht_est, vars(`tvars') alphabar(0.05) model(linear) ///
                cfshare(`cal_cfs') jbar(`cal_jbar') onesided
            local n_lin_cal = r(n_reject_opt)
            scalar aopt_lincal_`loop'_`t' = r(alpha_opt)
            forvalues i = 1/6 {
                cap scalar _tmp = r(rej_opt_treat_c`i')
                if !_rc matrix R`loop'_`t'[`i',9] = scalar(_tmp)
            }

            local n_n10 0
            forvalues i = 1/6 {
                if R`loop'_`t'[`i',4] < . {
                    if R`loop'_`t'[`i',4] < 0.10 local n_n10 = `n_n10' + 1
                }
            }

            scalar J_`loop'_`t'         = `J_eff'
            scalar n_n10_`loop'_`t'     = `n_n10'
            scalar n_bh_`loop'_`t'      = `n_bh'
            scalar n_cd_`loop'_`t'      = `n_cd'
            scalar n_lindef_`loop'_`t'  = `n_lin_def'
            scalar n_lincal_`loop'_`t'  = `n_lin_cal'

            display as text "    `oname'_`t': J=`J_eff'  N10=`n_n10'  BH=`n_bh'  CD=`n_cd'  Lin_def=`n_lin_def'  Lin_cal=`n_lin_cal'"
        }
        else {
            scalar J_`loop'_`t' = 0
            scalar n_n10_`loop'_`t' = 0
            scalar n_bh_`loop'_`t' = 0
            scalar n_cd_`loop'_`t' = 0
            scalar n_lindef_`loop'_`t' = 0
            scalar n_lincal_`loop'_`t' = 0
        }
    }
    local loop = `loop' + 1
}

* ==========================================================================
* F. Summary comparison table
* ==========================================================================

display ""
display as text "{hline 90}"
display as result "  SUMMARY: Default vs Calibrated Linear Model"
display as text "  Default: cf_share=0.46, J_bar=3 (FDA pharma)"
display as text "  Calibrated: cf_share=0.23, J_bar=6 (Banerjee et al. costs)"
display as text "{hline 90}"
display ""

* Show thresholds
display as text "  Thresholds (one-sided, alpha_bar=0.05, J=6):"
qui mht_critical, jhypotheses(6) alphabar(0.05) model(linear) cfshare(0.46) jbar(3)
display as text "    Default Lin (0.46/3):   " as result %9.6f r(alpha_opt)
qui mht_critical, jhypotheses(6) alphabar(0.05) model(linear) cfshare(0.23) jbar(6)
display as text "    Calibrated Lin (0.23/6):" as result %9.6f r(alpha_opt)
qui mht_critical, jhypotheses(6) alphabar(0.05) model(cobbdouglas)
display as text "    Default CD:             " as result %9.6f r(alpha_opt)
display as text "    Bonferroni:             " as result %9.6f 0.05/6
display as text "    Unadjusted:             " as result %9.6f 0.05
display ""

display as text "  {hline 82}"
display as text "  Outcome        |   EL1 (endline)              |   EL2 (follow-up)            |"
display as text "                 |  J  Naive  BH  CD  L_def L_cal|  J  Naive  BH  CD  L_def L_cal|"
display as text "  {hline 82}"

forvalues k = 1/`nout' {
    local oname : word `k' of `outnames'
    local rowname = "`oname'" + "                "
    local rowname = substr("`rowname'",1,15)
    local disprow "  `rowname' |"
    foreach t in end fup {
        local Jv    = string(scalar(J_`k'_`t'),         "%3.0f")
        local n10v  = string(scalar(n_n10_`k'_`t'),     "%3.0f")
        local bhv   = string(scalar(n_bh_`k'_`t'),      "%3.0f")
        local cdv   = string(scalar(n_cd_`k'_`t'),      "%3.0f")
        local ldefv = string(scalar(n_lindef_`k'_`t'),   "%3.0f")
        local lcalv = string(scalar(n_lincal_`k'_`t'),   "%3.0f")
        local disprow "`disprow' `Jv'   `n10v'   `bhv'   `cdv'   `ldefv'   `lcalv' |"
    }
    display as result "`disprow'"
}
display as text "  {hline 82}"
display ""
display as text "  L_def = Linear default (cf_share=0.46, J_bar=3)"
display as text "  L_cal = Linear calibrated (cf_share=0.23, J_bar=6)"

display ""
display as text "{hline 68}"
display as result "  PART 3 COMPLETE"
display as text "{hline 68}"

log close _part3

* Post-process: strip command echo from the log for readability
global clean_log_path "`root'/testing/full_analysis_case/part3_calibration_log.txt"
quietly run "`root'/stata/_clean_log.do"
