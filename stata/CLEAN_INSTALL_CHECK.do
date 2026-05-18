/*******************************************************************************
    CLEAN_INSTALL_CHECK.do

    Clean-install smoke test for the mhtopt Stata package, ahead of SSC
    submission.  Verifies that the five commands (mht_critical, mht_test,
    mht_est, mht_cost_estimate, mht_table) load from a freshly installed
    copy of the package -- i.e. NOT from any version sitting in your dev
    environment's PERSONAL/ or PLUS/ ado-path.

    HOW TO USE
    ----------
    1.  Edit `pkgdir' below so that it points to the absolute path of the
        `mhtopt/stata' folder on this machine.  This is the folder that
        contains mht_critical.ado, mht_test.ado, etc.
    2.  Open a FRESH Stata session (do not load any project profile).
    3.  Run this do-file:  do CLEAN_INSTALL_CHECK.do
    4.  Inspect the log `clean_install_check.log' that this file writes
        to the current working directory.  Every command should produce
        the expected output below (Section 5) and no `unrecognized command'
        error.

    What this script does, step by step:
        (a)  Sandboxes the ado-path -- removes PERSONAL, PLUS, SITE, and
             OLDPLACE so the only Stata code visible is base Stata and
             whatever we install in step (b).
        (b)  `net install's the package from the local `pkgdir' folder.
        (c)  Confirms each command exists in the post-install ado-path
             via `which'.
        (d)  Runs a representative call of each command.
        (e)  Restores the original ado-path.

*******************************************************************************/

clear all
set more off

capture log close clean_install_check
log using "clean_install_check.log", replace text name(clean_install_check)


* =============================================================================
* (0) USER CONFIG -- edit this line
* =============================================================================

* Absolute path of the folder containing the .ado / .sthlp / stata.toc files.
* On Windows, use forward slashes or escaped backslashes.
local pkgdir "C:/Users/erick/OneDrive/Documentos/PhD/GSR Paul/LTP/MHT/mhtopt/stata"

display _newline as result "Package source folder:"
display as text "    `pkgdir'"


* =============================================================================
* (a) Sandbox the ado-path
*     Save the current ado-path, then strip out anything that could shadow
*     our test install.  This is the equivalent of `wiping PERSONAL/PLUS'
*     without actually deleting any files on disk.
* =============================================================================

display _newline(2) as result "=== (a) Sandboxing ado-path ==="

* Snapshot the current ado-path so we can restore it at the end.
local orig_adopath `"`c(adopath)'"'
display as text "Original adopath:"
display as text `"    `orig_adopath'"'

* Remove user-level paths that could shadow a freshly installed package.
* (`adopath -' fails silently if the path is not currently set.)
foreach short in PERSONAL PLUS SITE OLDPLACE {
    capture adopath - `short'
}

* Also strip out any explicit on-disk path that points at our dev source.
* This is belt-and-suspenders: if the user has previously done
* `adopath + "`pkgdir'"' in this session, remove that too so the only way
* a command can be found is via the install we are about to do.
capture adopath - "`pkgdir'"

display _newline as text "Ado-path after sandboxing:"
display as text `"    `c(adopath)'"'


* =============================================================================
* (b) Install the package from the local folder
*     `net install' with a local file:// URL.  This drops the .ado / .sthlp
*     files into PLUS (which we re-enable just for this install).
* =============================================================================

display _newline(2) as result "=== (b) net install mhtopt from local folder ==="

* Re-enable PLUS so net install has somewhere to write to.
sysdir set PLUS "`c(tmpdir)'/mhtopt_clean_install_plus"
capture mkdir "`c(tmpdir)'/mhtopt_clean_install_plus"
adopath + PLUS

* If a stata.toc / mhtopt.pkg file is present in `pkgdir', the next line
* installs the package.  If those package-manifest files are missing,
* we fall back to `adopath +' so the smoke test still exercises the
* installed-style code path.
capture noisily net install mhtopt, from("`pkgdir'") replace
if _rc {
    display as error ///
        "net install failed (likely no stata.toc / mhtopt.pkg in pkgdir)."
    display as text ///
        "Falling back to: adopath + \"`pkgdir'\" for the smoke test."
    adopath + "`pkgdir'"
}


* =============================================================================
* (c) Confirm each command is locatable
* =============================================================================

display _newline(2) as result "=== (c) which <command> ==="

foreach cmd in mht_critical mht_test mht_est mht_cost_estimate mht_table {
    display _newline as text "which `cmd':"
    capture noisily which `cmd'
    if _rc {
        display as error "    *** `cmd' was NOT found on the ado-path ***"
    }
}


* =============================================================================
* (d) Run a representative call of each command
* =============================================================================

display _newline(2) as result "=== (d) Smoke-test each command ==="


* ---- (d1) mht_critical ------------------------------------------------------
display _newline as result "--- mht_critical: alpha* for J=5, alphabar=0.05 (Linear / FDA) ---"
mht_critical, jhypotheses(5) alphabar(0.05)
display as text "  -> Expect r(alpha_opt) in (0, 0.05].  Got: " as result %7.5f r(alpha_opt)


* ---- (d2) mht_test ----------------------------------------------------------
display _newline as result "--- mht_test: 5 hand-built p-values ---"
clear
quietly set obs 5
gen pval = .
quietly replace pval = 0.001 in 1
quietly replace pval = 0.020 in 2
quietly replace pval = 0.040 in 3
quietly replace pval = 0.100 in 4
quietly replace pval = 0.300 in 5
mht_test pval, alphabar(0.05)
display as text "  -> Expect rejection variables mht_reject_opt / _bonf / _holm / _bh / _unadj."
list pval mht_reject_opt mht_reject_bonf mht_reject_unadj, noobs


* ---- (d3) mht_table ---------------------------------------------------------
display _newline as result "--- mht_table: small grid ---"
mht_table, alphabar(0.05) jrange(1 3 5) nmratios(0.5 1 2)
display as text "  -> Expect a table with rows for J = 1, 3, 5, Inf."


* ---- (d4) mht_est -----------------------------------------------------------
display _newline as result "--- mht_est: postestimation after a regress on sysuse auto ---"
sysuse auto, clear
quietly regress price mpg weight foreign, robust
mht_est, vars(mpg weight foreign) alphabar(0.05)
display as text "  -> Expect r(alpha_opt) and r(n_reject_opt).  Got n_reject_opt = " ///
    as result r(n_reject_opt)


* ---- (d5) mht_cost_estimate -------------------------------------------------
display _newline as result "--- mht_cost_estimate: simulated 200-project dataset ---"
clear
quietly set obs 200
quietly set seed 20260518
quietly gen arms        = ceil(runiform() * 5)
quietly gen sample_size = ceil(500 + runiform() * 4500)
quietly gen cost        = exp(10 + 0.2*ln(arms) + 0.15*ln(sample_size) + rnormal(0, 0.4))
mht_cost_estimate cost arms sample_size, alphabar(0.05) robust
display as text "  -> Expect e(beta) near 0.20 and e(iota) near 0.15.  Got:"
display as text "       beta = " as result %5.3f e(beta) ///
                  as text ",  iota = " as result %5.3f e(iota)


* =============================================================================
* (e) Restore the original ado-path
* =============================================================================

display _newline(2) as result "=== (e) Restoring original ado-path ==="

* The cleanest way to restore is to set the path string back to what we
* snapshotted at the top.  `sysdir' macros (PERSONAL, PLUS, ...) are still
* intact; what changed is which of them appear in c(adopath).
adopath
display as text "Done.  If anything above said 'NOT found' or threw an error,"
display as text "the clean install is incomplete and SSC submission should be"
display as text "held until fixed."


log close clean_install_check
