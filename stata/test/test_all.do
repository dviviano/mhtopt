/*******************************************************************************
    test_all.do
    Unit tests for the mht package (all five public commands)
    Viviano, Wuthrich, and Niehaus (2026)

    50 tests organised in six sections:
      1. mht_est            (20 tests)   postestimation MHT after any regression
      2. mht_critical       ( 8 tests)   core optimal critical value
      3. mht_test           ( 8 tests)   adjustment for a list of p-values
      4. mht_table          ( 4 tests)   reference table; default mode and custom
      5. mht_cost_estimate  ( 4 tests)   cost-function parameter estimation
      6. Numeric verification (6 tests)  paper Table 1 spot checks vs Eq. 27

    To run:
        adopath + "path/to/mhtopt/stata"
        do "path/to/mhtopt/stata/test/test_all.do"

    Or use the wrapper stata/test/run_tests.do for clean log output.

    Output: each test prints PASS or FAIL; final summary at the end.
*******************************************************************************/

set more off
clear all

local pass = 0
local fail = 0

display _newline(2) as result "=================================================="
display as result "  Unit tests for the mht package"
display as result "  Viviano, Wuthrich, and Niehaus (2026)"
display as result "=================================================="

// ===========================================================================
// SECTION 1: mht_est (postestimation)
// ===========================================================================
display _newline as text "--- mht_est tests ---"

// Setup: use Stata's built-in auto dataset
sysuse auto, clear

// --- TEST 1: Basic syntax -- runs after regress ---
display _newline as text "--- TEST 1: Basic run after regress ---"
capture {
    regress price mpg weight foreign, robust
    mht_est, vars(mpg weight foreign) alphabar(0.05)
}
if _rc == 0 {
    display as result "  PASS [TEST 1: runs without error after regress]"
    local pass = `pass' + 1
}
else {
    display as error "  FAIL [TEST 1: error _rc=" _rc "]"
    local fail = `fail' + 1
}

// --- TEST 2: r(J) is correct (3 variables) ---
display _newline as text "--- TEST 2: r(J) equals number of vars ---"
quietly regress price mpg weight foreign, robust
quietly mht_est, vars(mpg weight foreign) alphabar(0.05)
if r(J) == 3 {
    display as result "  PASS [TEST 2: r(J) = 3]"
    local pass = `pass' + 1
}
else {
    display as error "  FAIL [TEST 2: r(J) = " r(J) ", expected 3]"
    local fail = `fail' + 1
}

// --- TEST 3: alpha_opt is between alpha_bonf and alpha_bar (Linear, J>1) ---
display _newline as text "--- TEST 3: alpha_opt between Bonferroni and unadjusted ---"
quietly regress price mpg weight foreign, robust
quietly mht_est, vars(mpg weight foreign) alphabar(0.05)
if r(alpha_opt) > r(alpha_bonf) & r(alpha_opt) < 0.05 {
    display as result "  PASS [TEST 3: alpha_bonf < alpha_opt < alpha_bar]"
    local pass = `pass' + 1
}
else {
    display as error "  FAIL [TEST 3: alpha_bonf=" r(alpha_bonf) " alpha_opt=" r(alpha_opt) " alpha_bar=0.05]"
    local fail = `fail' + 1
}

// --- TEST 4: alpha_bonf = alpha_bar / J ---
display _newline as text "--- TEST 4: alpha_bonf = alpha_bar / J ---"
quietly regress price mpg weight foreign, robust
quietly mht_est, vars(mpg weight foreign) alphabar(0.05)
local expected_bonf = 0.05 / 3
if abs(r(alpha_bonf) - `expected_bonf') < 1e-8 {
    display as result "  PASS [TEST 4: alpha_bonf = 0.05/3]"
    local pass = `pass' + 1
}
else {
    display as error "  FAIL [TEST 4: alpha_bonf=" r(alpha_bonf) ", expected " `expected_bonf' "]"
    local fail = `fail' + 1
}

// --- TEST 5: r(alpha_bar) stored correctly ---
display _newline as text "--- TEST 5: r(alpha_bar) stored correctly ---"
quietly regress price mpg weight foreign, robust
quietly mht_est, vars(mpg weight foreign) alphabar(0.10)
if abs(r(alpha_bar) - 0.10) < 1e-10 {
    display as result "  PASS [TEST 5: r(alpha_bar) = 0.10]"
    local pass = `pass' + 1
}
else {
    display as error "  FAIL [TEST 5: r(alpha_bar) = " r(alpha_bar) "]"
    local fail = `fail' + 1
}

// --- TEST 6: Per-variable scalars are stored ---
display _newline as text "--- TEST 6: Per-variable r() scalars exist ---"
quietly regress price mpg weight foreign, robust
quietly mht_est, vars(mpg weight) alphabar(0.05)
capture {
    local _test_coef = r(coef_mpg)
    local _test_se   = r(se_mpg)
    local _test_t    = r(t_mpg)
    local _test_p    = r(p_mpg)
}
if _rc == 0 & `_test_se' > 0 {
    display as result "  PASS [TEST 6: r(coef_mpg), r(se_mpg), r(t_mpg), r(p_mpg) exist]"
    local pass = `pass' + 1
}
else {
    display as error "  FAIL [TEST 6: per-variable scalars missing or SE not positive]"
    local fail = `fail' + 1
}

// --- TEST 7: n_reject_unadj >= n_reject_opt >= n_reject_bonf ---
display _newline as text "--- TEST 7: rejection ordering (unadj >= opt >= bonf) ---"
quietly regress price mpg weight foreign, robust
quietly mht_est, vars(mpg weight foreign) alphabar(0.05)
if r(n_reject_unadj) >= r(n_reject_opt) & r(n_reject_opt) >= r(n_reject_bonf) {
    display as result "  PASS [TEST 7: n_unadj >= n_opt >= n_bonf]"
    local pass = `pass' + 1
}
else {
    display as error "  FAIL [TEST 7: ordering violated: unadj=" r(n_reject_unadj) " opt=" r(n_reject_opt) " bonf=" r(n_reject_bonf) "]"
    local fail = `fail' + 1
}

// --- TEST 8: Cobb-Douglas model runs and gives different alpha_opt than Linear ---
display _newline as text "--- TEST 8: Cobb-Douglas model ---"
quietly regress price mpg weight foreign, robust
quietly mht_est, vars(mpg weight foreign) alphabar(0.05)
local alpha_lin = r(alpha_opt)
quietly mht_est, vars(mpg weight foreign) alphabar(0.05) model(cobbdouglas)
local alpha_cd = r(alpha_opt)
if r(J) == 3 & abs(`alpha_lin' - `alpha_cd') > 1e-8 {
    display as result "  PASS [TEST 8: Cobb-Douglas runs and gives different alpha]"
    local pass = `pass' + 1
}
else {
    display as error "  FAIL [TEST 8: J=" r(J) " lin=" `alpha_lin' " cd=" `alpha_cd' "]"
    local fail = `fail' + 1
}

// --- TEST 9: Works after logit ---
display _newline as text "--- TEST 9: Works after logit ---"
capture {
    quietly logit foreign price mpg weight, robust
    quietly mht_est, vars(price mpg weight) alphabar(0.05) twosided
}
if _rc == 0 & r(J) == 3 {
    display as result "  PASS [TEST 9: works after logit]"
    local pass = `pass' + 1
}
else {
    display as error "  FAIL [TEST 9: _rc=" _rc " J=" r(J) "]"
    local fail = `fail' + 1
}

// --- TEST 10: Fails correctly when no estimation results in memory ---
display _newline as text "--- TEST 10: Fails without prior estimation ---"
discard
capture mht_est, vars(mpg) alphabar(0.05)
if _rc == 301 {
    display as result "  PASS [TEST 10: correct error 301 when no e() results]"
    local pass = `pass' + 1
}
else {
    display as error "  FAIL [TEST 10: expected _rc=301, got _rc=" _rc "]"
    local fail = `fail' + 1
}

// --- TEST 11: Fails correctly for bad variable name ---
display _newline as text "--- TEST 11: Fails for variable not in e(b) ---"
quietly sysuse auto, clear
quietly regress price mpg weight, robust
capture mht_est, vars(mpg NOTAVAR) alphabar(0.05)
if _rc == 198 {
    display as result "  PASS [TEST 11: correct error 198 for bad varname]"
    local pass = `pass' + 1
}
else {
    display as error "  FAIL [TEST 11: expected _rc=198, got _rc=" _rc "]"
    local fail = `fail' + 1
}

// --- TEST 12: Fails correctly for bad alpha_bar ---
display _newline as text "--- TEST 12: Fails for alphabar outside (0,1) ---"
quietly sysuse auto, clear
quietly regress price mpg weight, robust
capture mht_est, vars(mpg weight) alphabar(1.5)
if _rc == 198 {
    display as result "  PASS [TEST 12: correct error 198 for alphabar=1.5]"
    local pass = `pass' + 1
}
else {
    display as error "  FAIL [TEST 12: expected _rc=198, got _rc=" _rc "]"
    local fail = `fail' + 1
}

// --- TEST 13: nmratio > 1 gives less conservative threshold ---
display _newline as text "--- TEST 13: nmratio=2 gives larger alpha_opt than nmratio=1 ---"
quietly sysuse auto, clear
quietly regress price mpg weight foreign, robust
quietly mht_est, vars(mpg weight foreign) alphabar(0.05) nmratio(1.0)
local alpha_nm1 = r(alpha_opt)
quietly mht_est, vars(mpg weight foreign) alphabar(0.05) nmratio(2.0)
local alpha_nm2 = r(alpha_opt)
if `alpha_nm2' > `alpha_nm1' {
    display as result "  PASS [TEST 13: nmratio=2 -> larger alpha_opt]"
    local pass = `pass' + 1
}
else {
    display as error "  FAIL [TEST 13: nm1=" `alpha_nm1' " nm2=" `alpha_nm2' "]"
    local fail = `fail' + 1
}

// --- TEST 14: J=1 -> alpha_opt = alpha_bar ---
display _newline as text "--- TEST 14: J=1 single hypothesis ---"
quietly sysuse auto, clear
quietly regress price mpg, robust
quietly mht_est, vars(mpg) alphabar(0.05)
if abs(r(alpha_opt) - 0.05) < 1e-6 {
    display as result "  PASS [TEST 14: J=1 alpha_opt = alpha_bar]"
    local pass = `pass' + 1
}
else {
    display as error "  FAIL [TEST 14: J=1 alpha_opt=" r(alpha_opt) " (expected 0.05)]"
    local fail = `fail' + 1
}

// --- TEST 15: r(model) and r(vars) stored correctly ---
display _newline as text "--- TEST 15: r(model) and r(vars) macros ---"
quietly sysuse auto, clear
quietly regress price mpg weight, robust
quietly mht_est, vars(mpg weight) alphabar(0.05) model(cobbdouglas)
if `"`r(model)'"' == "cobbdouglas" & `"`r(vars)'"' == "mpg weight" {
    display as result "  PASS [TEST 15: r(model) and r(vars) correct]"
    local pass = `pass' + 1
}
else {
    display as error "  FAIL [TEST 15: model=`r(model)' vars=`r(vars)']"
    local fail = `fail' + 1
}

// --- TEST 16: Cross-validate against mht_critical (same alpha_opt) ---
display _newline as text "--- TEST 16: alpha_opt matches mht_critical ---"
quietly sysuse auto, clear
quietly regress price mpg weight foreign, robust
quietly mht_est, vars(mpg weight foreign) alphabar(0.05)
local est_alpha = r(alpha_opt)
quietly mht_critical, jhypotheses(3) alphabar(0.05)
local crit_alpha = r(alpha_opt)
if abs(`est_alpha' - `crit_alpha') < 1e-10 {
    display as result "  PASS [TEST 16: alpha_opt matches mht_critical for J=3]"
    local pass = `pass' + 1
}
else {
    display as error "  FAIL [TEST 16: mht_est=" `est_alpha' " mht_critical=" `crit_alpha' "]"
    local fail = `fail' + 1
}

// --- TEST 17: Twosided and onesided give different p-values ---
display _newline as text "--- TEST 17: onesided vs twosided differ when coefficients mixed sign ---"
quietly sysuse auto, clear
quietly regress price mpg weight, robust
quietly mht_est, vars(mpg weight) alphabar(0.05)
local p_mpg_one = r(p_mpg)
quietly mht_est, vars(mpg weight) alphabar(0.05) twosided
local p_mpg_two = r(p_mpg)
if `p_mpg_one' != `p_mpg_two' {
    display as result "  PASS [TEST 17: onesided and twosided give different p-values]"
    local pass = `pass' + 1
}
else {
    display as error "  FAIL [TEST 17: p-values identical (onesided=" `p_mpg_one' " twosided=" `p_mpg_two' ")]"
    local fail = `fail' + 1
}

// --- TEST 18: Works with areg (absorbed FE) ---
display _newline as text "--- TEST 18: Works after areg ---"
quietly sysuse auto, clear
capture {
    quietly areg price mpg weight, absorb(rep78) robust
    quietly mht_est, vars(mpg weight) alphabar(0.05)
}
if _rc == 0 & r(J) == 2 {
    display as result "  PASS [TEST 18: works after areg]"
    local pass = `pass' + 1
}
else {
    display as error "  FAIL [TEST 18: _rc=" _rc " J=" r(J) "]"
    local fail = `fail' + 1
}

// --- TEST 19: mbar option changes alpha_opt relative to default ---
display _newline as text "--- TEST 19: mbar changes alpha_opt in mht_est ---"
sysuse auto, clear
quietly regress price mpg weight foreign, robust
quietly mht_est, vars(mpg weight foreign) alphabar(0.05)
local a_default = r(alpha_opt)
quietly mht_est, vars(mpg weight foreign) alphabar(0.05) mbar(100)
local a_mbar = r(alpha_opt)
if `a_mbar' < `a_default' & r(nm_ratio) > 0 & r(nm_ratio) < 1 {
    display as result "  PASS [TEST 19: mbar makes alpha_opt more conservative; nm_ratio=" r(nm_ratio) "]"
    local pass = `pass' + 1
}
else {
    display as error "  FAIL [TEST 19: default=" `a_default' " mbar=" `a_mbar' " nm_ratio=" r(nm_ratio) "]"
    local fail = `fail' + 1
}

// --- TEST 20: Smaller mbar (larger relative study) gives larger alpha_opt ---
display _newline as text "--- TEST 20: smaller mbar => larger alpha_opt ---"
quietly regress price mpg weight foreign, robust
quietly mht_est, vars(mpg weight foreign) alphabar(0.05) mbar(500)
local a_big_m = r(alpha_opt)
quietly mht_est, vars(mpg weight foreign) alphabar(0.05) mbar(5)
local a_small_m = r(alpha_opt)
if `a_small_m' > `a_big_m' {
    display as result "  PASS [TEST 20: mbar=5 gives larger alpha_opt than mbar=500]"
    local pass = `pass' + 1
}
else {
    display as error "  FAIL [TEST 20: mbar=5 alpha=" `a_small_m' " mbar=500 alpha=" `a_big_m' "]"
    local fail = `fail' + 1
}

// ===========================================================================
// SECTION 2: mht_critical
// ===========================================================================
display _newline as text "--- mht_critical tests ---"

// --- C1: J=1 returns alpha_bar exactly ---
quietly mht_critical, jhypotheses(1) alphabar(0.05)
if abs(r(alpha_opt) - 0.05) < 1e-10 {
    display as result "  PASS [C1: J=1 returns alpha_bar]"
    local pass = `pass' + 1
}
else {
    display as error "  FAIL [C1: J=1 returns alpha_bar; got " %12.10f r(alpha_opt) "]"
    local fail = `fail' + 1
}

// --- C2: Linear J>1 gives alpha_opt < alpha_bar ---
quietly mht_critical, jhypotheses(5) alphabar(0.05)
if r(alpha_opt) < 0.05 {
    display as result "  PASS [C2: Linear J>1 alpha_opt < alpha_bar]"
    local pass = `pass' + 1
}
else {
    display as error "  FAIL [C2: Linear alpha_opt = " %12.6f r(alpha_opt) " not < 0.05]"
    local fail = `fail' + 1
}

// --- C3: Linear alpha_opt > alpha_bonf ---
quietly mht_critical, jhypotheses(5) alphabar(0.05)
if r(alpha_opt) > 0.05/5 {
    display as result "  PASS [C3: Linear alpha_opt > alpha_bonf]"
    local pass = `pass' + 1
}
else {
    display as error "  FAIL [C3: Linear alpha_opt = " %12.6f r(alpha_opt) " not > 0.01]"
    local fail = `fail' + 1
}

// --- C4: alpha monotonically (weakly) decreasing in J ---
local prev_alpha = 1
local mono = 1
forvalues j = 1/9 {
    quietly mht_critical, jhypotheses(`j') alphabar(0.05)
    if r(alpha_opt) > `prev_alpha' + 1e-10 local mono = 0
    local prev_alpha = r(alpha_opt)
}
if `mono' == 1 {
    display as result "  PASS [C4: alpha decreases (weakly) in J for J=1..9]"
    local pass = `pass' + 1
}
else {
    display as error "  FAIL [C4: alpha not monotonic in J]"
    local fail = `fail' + 1
}

// --- C5: Cobb-Douglas beta=0 -> Bonferroni ---
quietly mht_critical, jhypotheses(5) alphabar(0.05) model(cobbdouglas) beta(0) iota(0)
if abs(r(alpha_opt) - 0.01) < 1e-10 {
    display as result "  PASS [C5: CD beta=0 gives alpha_bar/J = 0.01]"
    local pass = `pass' + 1
}
else {
    display as error "  FAIL [C5: CD beta=0 alpha_opt = " %12.6f r(alpha_opt) " not 0.01]"
    local fail = `fail' + 1
}

// --- C6: Cobb-Douglas beta=1 -> unadjusted ---
quietly mht_critical, jhypotheses(5) alphabar(0.05) model(cobbdouglas) beta(1) iota(0)
if abs(r(alpha_opt) - 0.05) < 1e-10 {
    display as result "  PASS [C6: CD beta=1 gives alpha_bar = 0.05]"
    local pass = `pass' + 1
}
else {
    display as error "  FAIL [C6: CD beta=1 alpha_opt = " %12.6f r(alpha_opt) " not 0.05]"
    local fail = `fail' + 1
}

// --- C7: Larger nm_ratio gives larger alpha_opt (Linear) ---
quietly mht_critical, jhypotheses(5) alphabar(0.05) nmratio(0.5)
local a_small = r(alpha_opt)
quietly mht_critical, jhypotheses(5) alphabar(0.05) nmratio(2.0)
local a_large = r(alpha_opt)
if `a_large' > `a_small' {
    display as result "  PASS [C7: nm_ratio=2.0 gives larger alpha than nm=0.5]"
    local pass = `pass' + 1
}
else {
    display as error "  FAIL [C7: nm=0.5 alpha=" %8.6f `a_small' " nm=2.0 alpha=" %8.6f `a_large' "]"
    local fail = `fail' + 1
}

// --- C8: Input validation: alpha_bar=0 errors ---
capture noisily mht_critical, jhypotheses(5) alphabar(0)
if _rc != 0 {
    display as result "  PASS [C8: alphabar=0 raises error (rc=" _rc ")]"
    local pass = `pass' + 1
}
else {
    display as error "  FAIL [C8: alphabar=0 did not error]"
    local fail = `fail' + 1
}

// ===========================================================================
// SECTION 3: mht_test
// ===========================================================================
display _newline as text "--- mht_test tests ---"

// --- T1: Basic run with 6 p-values ---
clear
set obs 6
gen pval = .
replace pval = 0.003 in 1
replace pval = 0.015 in 2
replace pval = 0.030 in 3
replace pval = 0.048 in 4
replace pval = 0.120 in 5
replace pval = 0.500 in 6

quietly mht_test pval, alphabar(0.05)
if r(J) == 6 {
    display as result "  PASS [T1: J = 6]"
    local pass = `pass' + 1
}
else {
    display as error "  FAIL [T1: J = " r(J) ", expected 6]"
    local fail = `fail' + 1
}

// --- T2: Generated rejection variables exist ---
capture confirm variable mht_reject_opt
local rc1 = _rc
capture confirm variable mht_reject_bonf
local rc2 = _rc
capture confirm variable mht_reject_holm
local rc3 = _rc
capture confirm variable mht_reject_bh
local rc4 = _rc
capture confirm variable mht_reject_unadj
local rc5 = _rc
if `rc1'==0 & `rc2'==0 & `rc3'==0 & `rc4'==0 & `rc5'==0 {
    display as result "  PASS [T2: all 5 rejection variables generated]"
    local pass = `pass' + 1
}
else {
    display as error "  FAIL [T2: some generated vars missing]"
    local fail = `fail' + 1
}

// --- T3: n_reject_opt >= n_reject_bonf ---
quietly mht_test pval, alphabar(0.05) replace
if r(n_reject_opt) >= r(n_reject_bonf) {
    display as result "  PASS [T3: n_reject_opt >= n_reject_bonf]"
    local pass = `pass' + 1
}
else {
    display as error "  FAIL [T3: n_opt=" r(n_reject_opt) " < n_bonf=" r(n_reject_bonf) "]"
    local fail = `fail' + 1
}

// --- T4: n_reject_opt <= n_reject_unadj ---
if r(n_reject_opt) <= r(n_reject_unadj) {
    display as result "  PASS [T4: n_reject_opt <= n_reject_unadj]"
    local pass = `pass' + 1
}
else {
    display as error "  FAIL [T4: n_opt=" r(n_reject_opt) " > n_unadj=" r(n_reject_unadj) "]"
    local fail = `fail' + 1
}

// --- T5: Holm at least as powerful as Bonferroni ---
if r(n_reject_holm) >= r(n_reject_bonf) {
    display as result "  PASS [T5: n_reject_holm >= n_reject_bonf]"
    local pass = `pass' + 1
}
else {
    display as error "  FAIL [T5: n_holm=" r(n_reject_holm) " < n_bonf=" r(n_reject_bonf) "]"
    local fail = `fail' + 1
}

// --- T6: All tiny p-values rejected by all methods ---
clear
set obs 3
gen p = 0.001
quietly mht_test p, alphabar(0.05)
if r(n_reject_opt) == 3 & r(n_reject_bonf) == 3 & r(n_reject_unadj) == 3 {
    display as result "  PASS [T6: all 3 tiny p-values rejected by all methods]"
    local pass = `pass' + 1
}
else {
    display as error "  FAIL [T6: opt=" r(n_reject_opt) " bonf=" r(n_reject_bonf) " unadj=" r(n_reject_unadj) "]"
    local fail = `fail' + 1
}

// --- T7: All large p-values not rejected by any method ---
clear
set obs 3
gen p = 0.5
quietly mht_test p, alphabar(0.05)
if r(n_reject_opt) == 0 & r(n_reject_bonf) == 0 & r(n_reject_unadj) == 0 {
    display as result "  PASS [T7: no rejections for p=0.5 across the board]"
    local pass = `pass' + 1
}
else {
    display as error "  FAIL [T7: opt=" r(n_reject_opt) " bonf=" r(n_reject_bonf) " unadj=" r(n_reject_unadj) "]"
    local fail = `fail' + 1
}

// --- T8: z-stat input gives same rejections as p-value input ---
clear
set obs 6
gen pval = .
replace pval = 0.003 in 1
replace pval = 0.015 in 2
replace pval = 0.030 in 3
replace pval = 0.048 in 4
replace pval = 0.120 in 5
replace pval = 0.500 in 6
gen zstat = invnormal(1 - pval)

quietly mht_test pval, alphabar(0.05) replace
local n_from_p = r(n_reject_opt)
quietly mht_test zstat, alphabar(0.05) zstat generate(z) replace
local n_from_z = r(n_reject_opt)
if `n_from_p' == `n_from_z' {
    display as result "  PASS [T8: z-stat and p-value inputs give same n_reject_opt]"
    local pass = `pass' + 1
}
else {
    display as error "  FAIL [T8: from p: `n_from_p', from z: `n_from_z']"
    local fail = `fail' + 1
}

// ===========================================================================
// SECTION 4: mht_table
// ===========================================================================
display _newline as text "--- mht_table tests ---"

// --- B1: Default mode runs and stores model macro ---
quietly mht_table
if "`r(model)'" == "linear" {
    display as result "  PASS [B1: default mode runs, r(model) = linear]"
    local pass = `pass' + 1
}
else {
    display as error "  FAIL [B1: r(model) = `r(model)']"
    local fail = `fail' + 1
}

// --- B2: Default mode reproduces paper Table 1 spot-check (J=5, n/m=100%, alphabar=0.05) ---
quietly mht_table
local got = r(alpha_5_100_0p05)
* Paper Table 1: J=5, alphabar=0.05, n/m=100% should give ~0.0213
if abs(`got' - 0.0213) < 0.0005 {
    display as result "  PASS [B2: r(alpha_5_100_0p05) = " %8.4f `got' " matches paper Table 1]"
    local pass = `pass' + 1
}
else {
    display as error "  FAIL [B2: got " %8.4f `got' ", expected ~0.0213]"
    local fail = `fail' + 1
}

// --- B3: Cobb-Douglas mode runs ---
capture quietly mht_table, model(cobbdouglas)
if _rc == 0 & "`r(model)'" == "cobbdouglas" {
    display as result "  PASS [B3: model(cobbdouglas) runs and stores model]"
    local pass = `pass' + 1
}
else {
    display as error "  FAIL [B3: rc=" _rc ", model=`r(model)']"
    local fail = `fail' + 1
}

// --- B4: Custom mode runs and stores alpha_bar ---
quietly mht_table, alphabar(0.10) jrange(1 3 5) nmratios(0.5 1.0 2.0)
if abs(r(alpha_bar) - 0.10) < 1e-10 {
    display as result "  PASS [B4: custom mode runs, r(alpha_bar) = 0.10]"
    local pass = `pass' + 1
}
else {
    display as error "  FAIL [B4: r(alpha_bar) = " r(alpha_bar) "]"
    local fail = `fail' + 1
}

// ===========================================================================
// SECTION 5: mht_cost_estimate
// ===========================================================================
display _newline as text "--- mht_cost_estimate tests ---"

// Setup: simulate cost data with known DGP (per-arm)
clear
set seed 42
set obs 300
gen arms = ceil(runiform()*5)
gen ss = ceil(100 + runiform()*900)
gen cost = exp(10 + 0.2*ln(arms) + 0.15*ln(ss) + rnormal(0, 0.4))

// --- E1: Cobb-Douglas recovers beta within 0.1 of true 0.20 ---
quietly mht_cost_estimate cost arms ss, alphabar(0.05) robust
if abs(e(beta) - 0.20) < 0.10 {
    display as result "  PASS [E1: estimated beta = " %6.3f e(beta) " (true 0.20)]"
    local pass = `pass' + 1
}
else {
    display as error "  FAIL [E1: estimated beta = " %6.3f e(beta) ", expected ~0.20]"
    local fail = `fail' + 1
}

// --- E2: Cobb-Douglas recovers iota within 0.1 of true 0.15 ---
if abs(e(iota) - 0.15) < 0.10 {
    display as result "  PASS [E2: estimated iota = " %6.3f e(iota) " (true 0.15)]"
    local pass = `pass' + 1
}
else {
    display as error "  FAIL [E2: estimated iota = " %6.3f e(iota) ", expected ~0.15]"
    local fail = `fail' + 1
}

// --- E3: beta significantly different from 0 ---
if e(p_beta0) < 0.05 {
    display as result "  PASS [E3: p-value beta=0 is < 0.05 (got " %6.4f e(p_beta0) ")]"
    local pass = `pass' + 1
}
else {
    display as error "  FAIL [E3: p_beta0 = " %6.4f e(p_beta0) "]"
    local fail = `fail' + 1
}

// --- E4: Linear share model returns valid cf_share in (0,1) ---
quietly mht_cost_estimate cost arms ss, alphabar(0.05) model(linear_share) robust
if e(cf_share) > 0 & e(cf_share) < 1 {
    display as result "  PASS [E4: linear_share cf_share = " %6.3f e(cf_share) " in (0,1)]"
    local pass = `pass' + 1
}
else {
    display as error "  FAIL [E4: cf_share = " %6.3f e(cf_share) " outside (0,1)]"
    local fail = `fail' + 1
}

// ===========================================================================
// SECTION 6: Numeric verification of paper Table 1 spot-checks
// ===========================================================================
display _newline as text "--- Numeric verification: paper Table 1 spot-checks ---"

* Paper's Eq. 27 ratio: ratio = 0.46 * 3 / (1 - 0.46) = 2.55556
local ratio = 0.46 * 3 / 0.54

// --- N1-N4: alpha_opt at (J, alpha_bar=0.05, nm=1) for J in {1,3,5,9} ---
foreach j of numlist 1 3 5 9 {
    quietly mht_critical, jhypotheses(`j') alphabar(0.05)
    local got = r(alpha_opt)
    local expected = 0.05 * (1 + `ratio'/`j') / (1 + `ratio')
    if abs(`got' - `expected') < 1e-8 {
        display as result "  PASS [N: J=`j', alphabar=0.05: alpha_opt = " %8.6f `got' "]"
        local pass = `pass' + 1
    }
    else {
        display as error "  FAIL [N: J=`j' got " %12.10f `got' " expected " %12.10f `expected' "]"
        local fail = `fail' + 1
    }
}

// --- N5: J=2, alpha_bar=0.025: paper says 0.016 ---
quietly mht_critical, jhypotheses(2) alphabar(0.025)
local got = r(alpha_opt)
if abs(`got' - 0.016) < 0.001 {
    display as result "  PASS [N5: J=2, alphabar=0.025 -> " %6.4f `got' " ~= paper 0.016]"
    local pass = `pass' + 1
}
else {
    display as error "  FAIL [N5: got " %8.5f `got' " expected ~0.016]"
    local fail = `fail' + 1
}

// --- N6: J=infinity (approx via J=999999), alpha_bar=0.025: paper says 0.007 ---
quietly mht_critical, jhypotheses(999999) alphabar(0.025)
local got = r(alpha_opt)
if abs(`got' - 0.007) < 0.001 {
    display as result "  PASS [N6: J=Inf, alphabar=0.025 -> " %6.4f `got' " ~= paper 0.007]"
    local pass = `pass' + 1
}
else {
    display as error "  FAIL [N6: got " %8.5f `got' " expected ~0.007]"
    local fail = `fail' + 1
}

// ===========================================================================
// SUMMARY
// ===========================================================================
display _newline(2) as result "=================================================="
display as result "  TEST SUMMARY"
display as result "=================================================="
display as result "  PASSED: " `pass'
if `fail' > 0 {
    display as error "  FAILED: " `fail'
}
else {
    display as result "  FAILED: 0"
    display as result "  All tests passed."
}
display as result "=================================================="
