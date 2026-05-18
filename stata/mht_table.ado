*! version 1.1.0  2026-03-24
*! mht_table -- Display table of optimal test sizes
*! Based on Viviano, Wuthrich, and Niehaus (2026)

/*
    mht_table -- Reproduce Table 1 of Viviano, Wuthrich, and Niehaus (2026)

    Displays optimal test sizes on a grid of |J| (rows) and n/m ratios (columns),
    with optional Sidak benchmark columns.  Default arguments reproduce Table 1
    of v10 of the paper exactly, including the J = infinity row and the two
    Sidak correction columns (alpha_bar = 0.025 and 0.05).

    Syntax:
        mht_table [, alphabar(#) jrange(numlist) nmratios(numlist)
                     sidakbars(numlist) nosidak model(string) options]

    Options:
        alphabar(#)       : benchmark alpha for optimal columns (default 0.05)
        jrange(numlist)   : J values for rows (default 1 2 3 4 5 6 7 8 9)
                            The J = inf row is always appended automatically.
        nmratios(numlist) : n/m ratios for columns (default 0.5 1.0 1.5 2.0)
        sidakbars(numlist): alpha_bar values for Sidak benchmark columns
                            (default 0.025 0.05, matching Table 1 of v10)
        nosidak           : suppress Sidak columns
        model(string)     : linear (default) or cobbdouglas
        cfshare(#)        : fixed cost share (Linear; default 0.46)
        jbar(#)           : average subgroups (Linear; default 3)
        beta(#)           : arms elasticity (Cobb-Douglas; default 0.13)
        iota(#)           : size elasticity (Cobb-Douglas; default 0.075)
        noinf             : suppress the J = infinity row

    Stored results (r()):
        r(alpha_<j>_<nm>) : optimal alpha for J=j, n/m key (decimal -> p)
        r(sidak_<ab>_inf) : Sidak level at J=Inf (always 0)
        r(model)          : cost model used
        r(alpha_bar)      : benchmark alpha
*/

program define mht_table, rclass
    version 14.0
    syntax [,                              ///
            ALPHAbar(real 0.05)            ///  benchmark alpha
            Jrange(numlist integer >0)     ///  J values for rows
            NMratios(numlist >0)           ///  n/m values for columns
            SIDAKbars(numlist >0 <=1)      ///  alpha_bar values for Sidak columns
            NOSidak                        ///  suppress Sidak columns
            NOInf                          ///  suppress J=infinity row
            MODel(string)                  ///  linear or cobbdouglas
            CFshare(real 0.46)             ///  Linear: fixed cost share
            Jbar(real 3)                   ///  Linear: avg subgroups
            BETA(real 0.13)                ///  Cobb-Douglas: arms elasticity
            IOTA(real 0.075)               ///  Cobb-Douglas: size elasticity
            ]

    // --- Defaults ---
    if "`model'" == "" local model "linear"
    if "`model'" != "linear" & "`model'" != "cobbdouglas" {
        display as error `"model() must be "linear" or "cobbdouglas""'
        exit 198
    }
    if `alphabar' <= 0 | `alphabar' >= 1 {
        display as error "alphabar() must be strictly between 0 and 1"
        exit 198
    }
    if "`jrange'"   == "" local jrange   1 2 3 4 5 6 7 8 9
    if "`nmratios'" == "" local nmratios 0.5 1.0 1.5 2.0

    // Sidak bars: default 0.025 0.05 unless nosidak specified
    if "`nosidak'" == "" & "`sidakbars'" == "" local sidakbars 0.025 0.05
    if "`nosidak'" != "" local sidakbars ""

    local model_str = cond("`model'" == "linear", "Linear (Eq. 27)", "Cobb-Douglas (App. A)")
    local n_nm      : word count `nmratios'
    local n_sid     : word count `sidakbars'

    // ------------------------------------------------------------------
    // Header
    // ------------------------------------------------------------------
    display ""
    display as text "{hline 72}"
    display as result "  Optimal Test Sizes  [Table 1, Viviano, Wuthrich & Niehaus 2026]"
    display as text "  Model: " as result "`model_str'"
    display as text "  Benchmark alpha: " as result %6.4f `alphabar'
    display as text "{hline 72}"
    display ""

    // Column headers
    local header "  |J|"
    forvalues k = 1/`n_nm' {
        local nm_k : word `k' of `nmratios'
        local nm_pct = string(round(`nm_k' * 100), "%3.0f") + "%"
        local header = "`header'" + "    n/m=" + "`nm_pct'"
    }
    if `n_sid' > 0 {
        forvalues k = 1/`n_sid' {
            local ab_k : word `k' of `sidakbars'
            local header = "`header'" + "  Sid(a=" + string(`ab_k') + ")"
        }
    }
    display as text "`header'"
    local hlen = 4 + 10*`n_nm' + 12*`n_sid'
    display as text "  {hline `hlen'}"

    // ------------------------------------------------------------------
    // Finite J rows
    // ------------------------------------------------------------------
    foreach j of numlist `jrange' {
        local row = "  " + string(`j', "%3.0f")
        forvalues k = 1/`n_nm' {
            local nm_k : word `k' of `nmratios'

            quietly mht_critical, jhypotheses(`j') alphabar(`alphabar') ///
                model(`model') cfshare(`cfshare') jbar(`jbar')          ///
                nmratio(`nm_k') beta(`beta') iota(`iota')

            local aopt   = r(alpha_opt)
            local nm_key = subinstr("`nm_k'", ".", "p", .)
            return scalar alpha_`j'_`nm_key' = `aopt'
            local row = "`row'" + "    " + string(`aopt', "%8.4f")
        }
        // Sidak columns
        if `n_sid' > 0 {
            forvalues k = 1/`n_sid' {
                local ab_k  : word `k' of `sidakbars'
                local sid   = 1 - (1 - `ab_k')^(1/`j')
                local ab_key = subinstr(string(`ab_k'), ".", "p", .)
                return scalar sidak_`ab_key'_`j' = `sid'
                local row = "`row'" + "  " + string(`sid', "%10.4f")
            }
        }
        display as result "`row'"
    }

    // ------------------------------------------------------------------
    // J = infinity row (limiting case)
    // Uses ratio/J -> 0 in linear model and J^(beta-1) -> 0 in Cobb-Douglas
    // Approximated via J = 999999 passed to mht_critical
    // ------------------------------------------------------------------
    if "`noinf'" == "" {
        local row = "  Inf"
        forvalues k = 1/`n_nm' {
            local nm_k : word `k' of `nmratios'

            quietly mht_critical, jhypotheses(999999) alphabar(`alphabar') ///
                model(`model') cfshare(`cfshare') jbar(`jbar')             ///
                nmratio(`nm_k') beta(`beta') iota(`iota')

            local aopt = r(alpha_opt)
            local nm_key = subinstr("`nm_k'", ".", "p", .)
            return scalar alpha_inf_`nm_key' = `aopt'
            local row = "`row'" + "    " + string(`aopt', "%8.4f")
        }
        // Sidak -> 0 at J = Inf
        if `n_sid' > 0 {
            forvalues k = 1/`n_sid' {
                local ab_k  : word `k' of `sidakbars'
                local ab_key = subinstr(string(`ab_k'), ".", "p", .)
                return scalar sidak_`ab_key'_inf = 0
                local row = "`row'" + "  " + string(0, "%10.4f")
            }
        }
        display as result "`row'"
    }

    display as text "  {hline `hlen'}"
    display ""

    // ------------------------------------------------------------------
    // Summary stored results
    // ------------------------------------------------------------------
    return local  model     = "`model'"
    return scalar alpha_bar = `alphabar'

end
