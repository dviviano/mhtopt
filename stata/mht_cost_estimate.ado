*! version 1.0.0  2026-03-15
*! Estimate cost function parameters for MHT adjustment
*! Based on Viviano, Wuthrich, and Niehaus (2026)

/*
    mht_cost_estimate - Estimate cost function parameters from data on research costs

    Given data on project costs, number of treatment arms, and sample sizes,
    estimates the parameters of the cost function and computes implied optimal
    test sizes. Supports two models:

    1. Linear: C = c_f + c_v * |J| * n
       Estimated via OLS (levels regression) to recover c_f and c_v,
       then fixed-cost share = c_f / mean(C)

    2. Cobb-Douglas: log(C) = log(k) + beta * log(|J|) + iota * log(n)
       Estimated via OLS on log-linearized equation (as in Table 2 of the paper)

    The Cobb-Douglas model is estimated by default as it is the approach
    used in the J-PAL application (Appendix A).
*/

program define mht_cost_estimate, eclass
    version 14.0
    syntax varlist(min=3 max=3 numeric)  /// cost_var arms_var samplesize_var
           [if] [in],                    ///
           ALPHAbar(real)                /// Benchmark single-hypothesis size
           [                              ///
           MODel(string)                  /// "cobbdouglas" (default) or "linear_share"
           CONTROLs(varlist)              /// Additional controls for the regression
           Robust                         /// Use robust standard errors
           CLuster(varname)               /// Cluster variable for standard errors
           TABle                          /// Display critical value table
           ]

    // Parse variable names
    tokenize `varlist'
    local costvar `1'
    local armsvar `2'
    local sizevar `3'

    // Mark sample
    marksample touse
    qui count if `touse'
    local N = r(N)

    if `N' == 0 {
        display as error "No observations"
        exit 2000
    }

    // Default model
    if "`model'" == "" {
        local model "cobbdouglas"
    }

    if "`model'" == "cobbdouglas" {
        // ============================================================
        // Cobb-Douglas estimation: log(C) = const + beta*log(|J|) + iota*log(n) + controls
        // ============================================================
        tempvar log_cost log_arms log_size
        qui gen double `log_cost' = ln(`costvar') if `touse'
        qui gen double `log_arms' = ln(`armsvar') if `touse'
        qui gen double `log_size' = ln(`sizevar') if `touse'

        // Build regression command
        local regcmd "regress `log_cost' `log_arms' `log_size'"
        if "`controls'" != "" {
            local regcmd "`regcmd' `controls'"
        }
        local regcmd "`regcmd' if `touse'"
        if "`robust'" != "" {
            local regcmd "`regcmd', robust"
        }
        else if "`cluster'" != "" {
            local regcmd "`regcmd', cluster(`cluster')"
        }

        // Run regression
        display ""
        display as text "{hline 65}"
        display as result "  Cost Function Estimation (Cobb-Douglas)"
        display as text "  log(cost) = const + beta*log(arms) + iota*log(sample_size)"
        display as text "{hline 65}"
        display ""

        qui `regcmd'

        // Extract coefficients
        local beta_hat = _b[`log_arms']
        local iota_hat = _b[`log_size']
        local beta_se = _se[`log_arms']
        local iota_se = _se[`log_size']

        // Display regression output
        `regcmd'

        display ""
        display as text "{hline 65}"
        display as result "  Hypothesis Tests on Cost Parameters"
        display as text "{hline 65}"

        // Test beta = 0 (costs invariant to arms => Bonferroni)
        qui test `log_arms' = 0
        local p_beta0 = r(p)
        display as text "  H0: beta = 0 (Bonferroni appropriate):     " ///
                as result "p = " %6.4f `p_beta0'

        // Test beta = 1 (costs proportional => no adjustment)
        qui test `log_arms' = 1
        local p_beta1 = r(p)
        display as text "  H0: beta = 1 (no adjustment needed):       " ///
                as result "p = " %6.4f `p_beta1'

        // Test iota = 0 (costs invariant to sample size)
        qui test `log_size' = 0
        local p_iota0 = r(p)
        display as text "  H0: iota = 0 (costs invariant to n):       " ///
                as result "p = " %6.4f `p_iota0'

        // Test iota = 1 (costs proportional to n)
        qui test `log_size' = 1
        local p_iota1 = r(p)
        display as text "  H0: iota = 1 (costs proportional to n):    " ///
                as result "p = " %6.4f `p_iota1'

        display as text "{hline 65}"
        display ""

        // Implied critical values
        display as text "{hline 65}"
        display as result "  Implied Optimal Test Sizes"
        display as text "  alpha(|J|, n/m) = alpha_bar * |J|^(beta-1) * (n/m)^iota"
        display as text "  Using alpha_bar = " %6.4f `alphabar'
        display as text "  beta = " %6.3f `beta_hat' ", iota = " %6.3f `iota_hat'
        display as text "{hline 65}"
        display ""

        if "`table'" != "" {
            // Display table of critical values (like Table 1 / Table 3)
            display as text "  |J|     n/m=0.5    n/m=1.0    n/m=1.5    n/m=2.0"
            display as text "  {hline 50}"
            foreach j in 1 2 3 4 5 6 7 8 9 {
                local a50  = `alphabar' * `j'^(`beta_hat' - 1) * 0.5^`iota_hat'
                local a100 = `alphabar' * `j'^(`beta_hat' - 1) * 1.0^`iota_hat'
                local a150 = `alphabar' * `j'^(`beta_hat' - 1) * 1.5^`iota_hat'
                local a200 = `alphabar' * `j'^(`beta_hat' - 1) * 2.0^`iota_hat'
                display as text "  " %2.0f `j' _col(12) ///
                    as result %8.4f `a50' _col(23) %8.4f `a100' _col(34) %8.4f `a150' _col(45) %8.4f `a200'
            }
            display as text "  {hline 50}"
            display ""
        }

        // Return results
        ereturn scalar beta = `beta_hat'
        ereturn scalar iota = `iota_hat'
        ereturn scalar beta_se = `beta_se'
        ereturn scalar iota_se = `iota_se'
        ereturn scalar p_beta0 = `p_beta0'
        ereturn scalar p_beta1 = `p_beta1'
        ereturn scalar p_iota0 = `p_iota0'
        ereturn scalar p_iota1 = `p_iota1'
        ereturn scalar alpha_bar = `alphabar'
        ereturn scalar N = `N'
        ereturn local model = "cobbdouglas"
    }
    else if "`model'" == "linear_share" {
        // ============================================================
        // Linear fixed-cost-share approach
        // Estimate: fixed cost share = c_f / (c_f + c_v * mean(|J| * n))
        // This requires the user to provide cost data that can be decomposed
        // We estimate by regressing cost on |J|*n to get c_f and c_v
        // ============================================================
        tempvar jn_interact
        qui gen double `jn_interact' = `armsvar' * `sizevar' if `touse'

        display ""
        display as text "{hline 65}"
        display as result "  Cost Function Estimation (Linear Model)"
        display as text "  C = c_f + c_v * |J| * n"
        display as text "{hline 65}"
        display ""

        local regcmd "regress `costvar' `jn_interact'"
        if "`controls'" != "" {
            local regcmd "`regcmd' `controls'"
        }
        local regcmd "`regcmd' if `touse'"
        if "`robust'" != "" {
            local regcmd "`regcmd', robust"
        }
        else if "`cluster'" != "" {
            local regcmd "`regcmd', cluster(`cluster')"
        }

        qui `regcmd'
        `regcmd'

        local c_f = _b[_cons]
        local c_v = _b[`jn_interact']

        // Compute fixed cost share
        qui sum `costvar' if `touse', meanonly
        local mean_cost = r(mean)
        local cf_share = max(0, min(1, `c_f' / `mean_cost'))

        qui sum `armsvar' if `touse', meanonly
        local mean_J = r(mean)

        display ""
        display as text "{hline 65}"
        display as result "  Estimated Parameters"
        display as text "{hline 65}"
        display as text "  Fixed cost (c_f):        " as result %12.2f `c_f'
        display as text "  Variable cost (c_v):     " as result %12.4f `c_v'
        display as text "  Fixed cost share:        " as result %12.3f `cf_share'
        display as text "  Mean arms (J_bar):       " as result %12.1f `mean_J'
        display as text "{hline 65}"
        display ""

        if "`table'" != "" {
            local ratio = `cf_share' * `mean_J' / (1 - `cf_share')
            local denom = 1 + `ratio'

            display as text "  |J|     n/m=0.5    n/m=1.0    n/m=1.5    n/m=2.0"
            display as text "  {hline 50}"
            foreach j in 1 2 3 4 5 6 7 8 9 {
                foreach nm in 0.5 1.0 1.5 2.0 {
                    local nm_key = subinstr("`nm'", ".", "p", .)
                    local a_`j'_`nm_key' = `alphabar' * ((1 + `ratio'/`j') / `denom' + (`nm' - 1) / `denom')
                }
                display as text "  " %2.0f `j' _col(12) ///
                    as result %8.4f `a_`j'_0p5' _col(23) %8.4f `a_`j'_1p0' _col(34) %8.4f `a_`j'_1p5' _col(45) %8.4f `a_`j'_2p0'
            }
            display as text "  {hline 50}"
            display ""
        }

        // Return results
        ereturn scalar c_f = `c_f'
        ereturn scalar c_v = `c_v'
        ereturn scalar cf_share = `cf_share'
        ereturn scalar mean_J = `mean_J'
        ereturn scalar alpha_bar = `alphabar'
        ereturn scalar N = `N'
        ereturn local model = "linear_share"
    }
    else {
        display as error `"Model must be "cobbdouglas" or "linear_share""'
        exit 198
    }

end
