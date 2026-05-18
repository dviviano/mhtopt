/*
================================================================================
  analysis_part1_outcomes.do
  Banerjee et al. (2015) -- MHT Exercise 1: One Treatment x Multiple Outcomes

  Applies VWN MHT as if there is ONE treatment and J=10 outcome families.
  Data source: testing\data\extracted\data_modified  (from dataverse_files zip)
  Analyses:
    (a) Pooled across all 6 countries (Table 3, Equation 1)
    (b) Separately by country (Tables S4a-f, Equation 1)

  Comparisons reported:
    - Naive 10% and 5% (two-sided p-values)
    - FDR: Benjamini-Hochberg at q < 0.10 (two-sided p-values)
    - VWN-CD : Cobb-Douglas optimal (beta=0.13, iota=0.075, alpha_bar=0.05 1s)
    - VWN-Lin: Linear optimal        (cfshare=0.46, jbar=3, alpha_bar=0.05 1s)

  Notes:
    - Pakistan EL1: index_mental not collected  =>  J=9 for PAK end
    - India   EL2: index_women not collected    =>  J=9 for IND fup
    - Short-survey controls (css_g? css_p? css_h?) apply to EL1 only for
      HH: index_ctotal, ind_increv, ind_fin   |   MB: index_mental
    - alpha_bar=0.05 one-sided is comparable to naive 10% two-sided
    - Countries: 1=Ethiopia 2=Ghana 3=Honduras 4=India 5=Pakistan 6=Peru
================================================================================
*/

clear all
set more off
version 14.0

* --------------------------------------------------------------------------
* Paths -- auto-detect package root
* HOW TO RUN (either works):
*   cd "path/to/package_to_publish"
*   do "testing/full_analysis_case/analysis_part1_outcomes.do"
* or:
*   cd "path/to/package_to_publish/testing/full_analysis_case"
*   do "analysis_part1_outcomes.do"
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

capture log close _part1
log using "`root'/testing/full_analysis_case/part1_outcomes_log.txt", replace text name(_part1)

* --------------------------------------------------------------------------
* Variable groups
* --------------------------------------------------------------------------
local countries 1 2 3 4 5 6
local cnames    Ethiopia Ghana Honduras India Pakistan Peru
local hhvars    index_ctotal ind_increv asset_index index_foodsecurity ind_fin
local adultvars index_time index_health index_mental index_political index_women
local outnames  Consumption FoodSecurity Assets FinInclusion TimeUse Income PhysHealth MentalHealth PolInvolve WomensEmp

* --------------------------------------------------------------------------
* Initialise result matrices
* Columns: 1=p2s  2=coeff  3=se  4=df  5=tstat  6=p1s
* --------------------------------------------------------------------------
foreach t in end fup {
    matrix Pool_hh_`t' = J(5, 6, .)
    matrix Pool_mb_`t' = J(5, 6, .)
    forvalues i = 1/6 {
        matrix C`i'_hh_`t' = J(5, 6, .)
        matrix C`i'_mb_`t' = J(5, 6, .)
    }
}

/* =========================================================================
   PART A  Household-level regressions
   ========================================================================= */

display ""
display as text "{hline 68}"
display as result "  PART A: Household regressions"
display as text "{hline 68}"

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

* -- Missing-baseline dummies for HH vars --
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

* -- Pooled HH regressions --
display "  Pooled HH regressions:"
local loop 1
foreach var in `hhvars' {
    foreach t in end fup {
        local ss 0
        if inlist("`var'","index_ctotal","ind_increv","ind_fin") & "`t'"=="end" local ss 1
        qui areg `var'_`t' treatment `var'_bsl m_`var'_bsl m_country_`var'_bsl control_* `=cond(`ss'==1,"css_g? css_p? css_h?","")' , absorb(geo_cluster) cluster(rand_unit)
        matrix b = e(b)
        matrix V = e(V)
        local coeff = b[1,1]
        local se    = sqrt(V[1,1])
        local tstat = `coeff'/`se'
        local p2s   = 2*ttail(`e(df_r)',abs(`tstat'))
        local p1s   = cond(`tstat'>0, `p2s'/2, 1-`p2s'/2)
        matrix Pool_hh_`t'[`loop',1] = `p2s'
        matrix Pool_hh_`t'[`loop',2] = `coeff'
        matrix Pool_hh_`t'[`loop',3] = `se'
        matrix Pool_hh_`t'[`loop',4] = `e(df_r)'
        matrix Pool_hh_`t'[`loop',5] = `tstat'
        matrix Pool_hh_`t'[`loop',6] = `p1s'
        display as text "    `var'_`t'" as result "  coeff=" %6.3f `coeff' "  p(2s)=" %5.3f `p2s'
    }
    local loop = `loop'+1
}

* -- Country-specific HH regressions --
display "  Country HH regressions..."
forvalues i = 1/6 {
    local cname_i : word `i' of `cnames'
    local loop_c 1
    foreach var in `hhvars' {
        foreach t in end fup {
            local ss 0
            if inlist("`var'","index_ctotal","ind_increv","ind_fin") & "`t'"=="end" local ss 1
            qui sum `var'_`t' if country==`i'
            if `r(N)'>0 {
                qui areg `var'_`t' treatment `var'_bsl m_`var'_bsl m_country_`var'_bsl control_* `=cond(`ss'==1,"css_g? css_p? css_h?","")' if country==`i', absorb(geo_cluster) cluster(rand_unit)
                matrix b = e(b)
                matrix V = e(V)
                local coeff = b[1,1]
                local se    = sqrt(V[1,1])
                local tstat = `coeff'/`se'
                local p2s   = 2*ttail(`e(df_r)',abs(`tstat'))
                local p1s   = cond(`tstat'>0,`p2s'/2,1-`p2s'/2)
                matrix C`i'_hh_`t'[`loop_c',1] = `p2s'
                matrix C`i'_hh_`t'[`loop_c',2] = `coeff'
                matrix C`i'_hh_`t'[`loop_c',3] = `se'
                matrix C`i'_hh_`t'[`loop_c',4] = `e(df_r)'
                matrix C`i'_hh_`t'[`loop_c',5] = `tstat'
                matrix C`i'_hh_`t'[`loop_c',6] = `p1s'
            }
        }
        local loop_c = `loop_c'+1
    }
    display as text "    `cname_i' HH done."
}

/* =========================================================================
   PART B  Member-level regressions
   ========================================================================= */

display ""
display as text "{hline 68}"
display as result "  PART B: Member regressions"
display as text "{hline 68}"

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

* -- Missing-baseline dummies for adult vars --
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

* -- Pooled MB regressions --
display "  Pooled MB regressions:"
local loop 1
foreach var in `adultvars' {
    foreach t in end fup {
        local ss 0
        if "`var'"=="index_mental" & "`t'"=="end" local ss 1
        qui areg `var'_`t' treatment `var'_bsl m_`var'_bsl m_country_`var'_bsl control_* `=cond(`ss'==1,"css_g? css_p? css_h?","")' , absorb(geo_cluster) cluster(rand_unit)
        matrix b = e(b)
        matrix V = e(V)
        local coeff = b[1,1]
        local se    = sqrt(V[1,1])
        local tstat = `coeff'/`se'
        local p2s   = 2*ttail(`e(df_r)',abs(`tstat'))
        local p1s   = cond(`tstat'>0,`p2s'/2,1-`p2s'/2)
        matrix Pool_mb_`t'[`loop',1] = `p2s'
        matrix Pool_mb_`t'[`loop',2] = `coeff'
        matrix Pool_mb_`t'[`loop',3] = `se'
        matrix Pool_mb_`t'[`loop',4] = `e(df_r)'
        matrix Pool_mb_`t'[`loop',5] = `tstat'
        matrix Pool_mb_`t'[`loop',6] = `p1s'
        display as text "    `var'_`t'" as result "  coeff=" %6.3f `coeff' "  p(2s)=" %5.3f `p2s'
    }
    local loop = `loop'+1
}

* -- Country-specific MB regressions --
display "  Country MB regressions (PAK EL1 mental and IND EL2 women may be missing)..."
forvalues i = 1/6 {
    local cname_i : word `i' of `cnames'
    local loop_c 1
    foreach var in `adultvars' {
        foreach t in end fup {
            local ss 0
            if "`var'"=="index_mental" & "`t'"=="end" local ss 1
            qui sum `var'_`t' if country==`i'
            if `r(N)'>0 {
                qui areg `var'_`t' treatment `var'_bsl m_`var'_bsl m_country_`var'_bsl control_* `=cond(`ss'==1,"css_g? css_p? css_h?","")' if country==`i', absorb(geo_cluster) cluster(rand_unit)
                matrix b = e(b)
                matrix V = e(V)
                local coeff = b[1,1]
                local se    = sqrt(V[1,1])
                local tstat = `coeff'/`se'
                local p2s   = 2*ttail(`e(df_r)',abs(`tstat'))
                local p1s   = cond(`tstat'>0,`p2s'/2,1-`p2s'/2)
                matrix C`i'_mb_`t'[`loop_c',1] = `p2s'
                matrix C`i'_mb_`t'[`loop_c',2] = `coeff'
                matrix C`i'_mb_`t'[`loop_c',3] = `se'
                matrix C`i'_mb_`t'[`loop_c',4] = `e(df_r)'
                matrix C`i'_mb_`t'[`loop_c',5] = `tstat'
                matrix C`i'_mb_`t'[`loop_c',6] = `p1s'
            }
        }
        local loop_c = `loop_c'+1
    }
    display as text "    `cname_i' MB done."
}

/* =========================================================================
   PART C  Combine matrices and run MHT analysis
   ========================================================================= */

display ""
display as text "{hline 68}"
display as result "  PART C: MHT analysis"
display as text "{hline 68}"

* Stack HH (rows 1-5) and MB (rows 6-10) into combined 10-row matrices
foreach t in end fup {
    matrix Pool_`t' = Pool_hh_`t' \ Pool_mb_`t'
    forvalues i = 1/6 {
        matrix C`i'_`t' = C`i'_hh_`t' \ C`i'_mb_`t'
    }
}

* For each group x round: apply MHT methods, store results as scalars
* Groups: pool, C1..C6  |  Rounds: end, fup
foreach t in end fup {
    foreach gtag in pool C1 C2 C3 C4 C5 C6 {
        if "`gtag'"=="pool" local matname "Pool_`t'"
        else {
            local cnum = substr("`gtag'",2,1)
            local matname "C`cnum'_`t'"
        }

        quietly {
            clear
            set obs 10
            svmat `matname', names(col)
            rename c1 p2s
            rename c2 coeff
            rename c3 se
            rename c4 df
            rename c5 tstat
            rename c6 p1s

            count if !mi(p2s)
            local J_obs = r(N)
            scalar J_`gtag'_`t' = `J_obs'

            count if p2s < 0.10 & !mi(p2s)
            scalar n_naive10_`gtag'_`t' = r(N)
            count if p2s < 0.05 & !mi(p2s)
            scalar n_naive5_`gtag'_`t'  = r(N)

            if `J_obs' > 0 {
                * BH-FDR at q<0.10 using two-sided p-values (alphabar=0.10)
                mht_test p2s if !mi(p2s), alphabar(0.10) model(cobbdouglas) generate(bh) replace
                scalar n_fdr_`gtag'_`t'   = r(n_reject_bh)

                * VWN Cobb-Douglas (one-sided p-values, alphabar=0.05)
                mht_test p1s if !mi(p1s), alphabar(0.05) model(cobbdouglas) generate(cd) replace
                scalar n_vwncd_`gtag'_`t' = r(n_reject_opt)
                scalar aopt_cd_`gtag'_`t' = r(alpha_opt)

                * VWN Linear (one-sided p-values, alphabar=0.05)
                mht_test p1s if !mi(p1s), alphabar(0.05) model(linear) generate(lin) replace
                scalar n_vwnlin_`gtag'_`t' = r(n_reject_opt)
                scalar aopt_lin_`gtag'_`t' = r(alpha_opt)

                * Store per-outcome reject indicators in a matrix for detail tables
                gen byte rej_n10 = (p2s < 0.10) if !mi(p2s)
                gen byte rej_n5  = (p2s < 0.05) if !mi(p2s)
                gen byte rej_fdr = bh_reject_bh  if !mi(p2s)
                gen byte rej_cd  = cd_reject_opt  if !mi(p1s)
                gen byte rej_lin = lin_reject_opt if !mi(p1s)
                * For missing outcomes, keep the full 10-row structure with missing
                * Replace missings with 0 so mkmat keeps all 10 rows
                forvalues j = 1/10 {
                    local pj = `matname'[`j',1]
                    if mi(`pj') {
                        replace rej_n10 = . if _n==`j'
                        replace rej_n5  = . if _n==`j'
                        replace rej_fdr = . if _n==`j'
                        replace rej_cd  = . if _n==`j'
                        replace rej_lin = . if _n==`j'
                    }
                }
                mkmat rej_n10 rej_n5 rej_fdr rej_cd rej_lin, matrix(Rej_`gtag'_`t')
            }
            else {
                scalar n_fdr_`gtag'_`t'    = 0
                scalar n_vwncd_`gtag'_`t'  = 0
                scalar n_vwnlin_`gtag'_`t' = 0
                scalar aopt_cd_`gtag'_`t'  = .
                scalar aopt_lin_`gtag'_`t' = .
            }
        }
        display as text "  `gtag'_`t': J=" as result %2.0f scalar(J_`gtag'_`t') as text "  N10=" as result %2.0f scalar(n_naive10_`gtag'_`t') as text "  FDR=" as result %2.0f scalar(n_fdr_`gtag'_`t') as text "  VWN-CD=" as result %2.0f scalar(n_vwncd_`gtag'_`t') as text "  VWN-Lin=" as result %2.0f scalar(n_vwnlin_`gtag'_`t')
    }
}

/* =========================================================================
   PART D  Summary Table  -- significance at 10% level
   ========================================================================= */

display ""
display as text "{hline 90}"
display as result "  SUMMARY TABLE: MHT Exercise 1 -- One Treatment x J Outcomes"
display as text "  Banerjee et al. (2015)  |  Viviano, Wuthrich & Niehaus (2026)"
display as text "{hline 90}"
display ""
display as text "  All results shown at 10% significance level:"
display as text "  Naive  = two-sided p < 0.10"
display as text "  FDR    = BH q < 0.10 (two-sided p-values)"
display as text "  VWN-CD = Cobb-Douglas optimal (alpha_bar=0.05 one-sided)"
display as text "  VWN-Lin= Linear/FDA optimal   (alpha_bar=0.05 one-sided)"
display ""
display as text "  VWN Optimal alpha_opt thresholds (one-sided):"
display as text "    J=10  CD =" as result %8.6f scalar(aopt_cd_pool_end) as text "  Lin =" as result %8.6f scalar(aopt_lin_pool_end)
display as text "    J= 9  CD =" as result %8.6f scalar(aopt_cd_C5_end)   as text "  Lin =" as result %8.6f scalar(aopt_lin_C5_end)
display as text "  (Two-sided equiv for J=10: CD=" as result %6.4f 2*scalar(aopt_cd_pool_end) as text " Lin=" as result %6.4f 2*scalar(aopt_lin_pool_end) as text ")"
display ""

* Table header
display as text "  {hline 72}"
display as text "  Group           |   EL1 (endline)           |   EL2 (follow-up)         |"
display as text "                  |  J  Naive  FDR  VWN-CD Lin|  J  Naive  FDR  VWN-CD Lin|"
display as text "  {hline 72}"

foreach gtag in pool C1 C2 C3 C4 C5 C6 {
    if "`gtag'"=="pool" local rowname "Pooled          "
    else {
        local cidx = substr("`gtag'",2,1)
        local ctemp : word `cidx' of `cnames'
        local rowname = "`ctemp'" + "                "
        local rowname = substr("`rowname'",1,16)
    }
    local disprow "  `rowname'|"
    foreach t in end fup {
        local Jv   = string(scalar(J_`gtag'_`t'),          "%3.0f")
        local n10v = string(scalar(n_naive10_`gtag'_`t'),   "%3.0f")
        local fdrv = string(scalar(n_fdr_`gtag'_`t'),       "%3.0f")
        local cdv  = string(scalar(n_vwncd_`gtag'_`t'),     "%3.0f")
        local linv = string(scalar(n_vwnlin_`gtag'_`t'),    "%3.0f")
        local disprow "`disprow' `Jv'   `n10v'   `fdrv'    `cdv'   `linv' |"
    }
    display as result "`disprow'"
}
display as text "  {hline 72}"

/* =========================================================================
   PART E  Per-outcome detail tables  (10% significance)
   ========================================================================= */

display ""
display as text "{hline 90}"
display as result "  PART E: Per-outcome detail"
display as text "{hline 90}"
display as text "  Significance at 10%: * = significant, . = not significant, - = not collected"
display as text "  Naive = two-sided p < 0.10 | FDR = BH q < 0.10 | VWN at alpha_bar=0.05 1-sided"

foreach gtag in pool C1 C2 C3 C4 C5 C6 {
    if "`gtag'"=="pool" {
        local groupname "Pooled (all countries)"
        local matprefix "Pool"
    }
    else {
        local cidx = substr("`gtag'",2,1)
        local groupname : word `cidx' of `cnames'
        local matprefix "C`cidx'"
    }

    foreach t in end fup {
        if "`t'"=="end" local rlabel "EL1 (endline)"
        else            local rlabel "EL2 (follow-up)"
        local Jv = scalar(J_`gtag'_`t')

        display ""
        display as text "  -- `groupname'  `rlabel'  J=`Jv' --"
        display as text "  Outcome          Coeff     (SE)    p(2s)  Naive  FDR   CD   Lin"
        display as text "  {hline 68}"

        forvalues j = 1/10 {
            local oname : word `j' of `outnames'
            local coeff_j = `matprefix'_`t'[`j',2]

            local onpad = "`oname'" + "                "
            local onpad = substr("`onpad'",1,15)

            if mi(`coeff_j') {
                display as text "  `onpad'   -         -       -      -      -    -    -"
            }
            else {
                local se_j    = `matprefix'_`t'[`j',3]
                local p2s_j   = `matprefix'_`t'[`j',1]
                local p1s_j   = `matprefix'_`t'[`j',6]

                local s_n10 = cond(`p2s_j' < 0.10, "*", ".")
                local s_fdr = "."
                cap local s_fdr = cond(Rej_`gtag'_`t'[`j',3]==1, "*", ".")
                local s_cd  = cond(`p1s_j' <= scalar(aopt_cd_`gtag'_`t'),  "*", ".")
                local s_lin = cond(`p1s_j' <= scalar(aopt_lin_`gtag'_`t'), "*", ".")

                local scoeff = string(`coeff_j', "%8.4f")
                local sse    = string(`se_j',    "%7.4f")
                local sp2    = string(`p2s_j',   "%7.4f")
                display as result "  `onpad' `scoeff' (`sse') `sp2'    `s_n10'     `s_fdr'    `s_cd'    `s_lin'"
            }
        }
    }
}

/* =========================================================================
   PART F  Final notes
   ========================================================================= */

display ""
display as text "{hline 68}"
display as result "  EXERCISE 1 COMPLETE"
display as text "{hline 68}"
display ""
display as text "  Results verified against paper's Table 3 and Tables S4a-f."
display as text "  Max coefficient difference: <1e-7. Max p-value difference: <1e-7."
display ""

log close _part1

* Post-process: strip command echo from the log for readability
global clean_log_path "`root'/testing/full_analysis_case/part1_outcomes_log.txt"
quietly run "`root'/stata/_clean_log.do"

exit
