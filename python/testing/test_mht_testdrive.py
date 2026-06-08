"""
MHT Test Drive: Banerjee et al. (Science 2015)
Viviano, Wuthrich, and Niehaus (2026), "A Model of Multiple Hypothesis Testing"

One outcome x J=6 country arms (reproduces the results in results_note.pdf).

To run (needs pandas):
    cd python
    pip install pandas        # plus numpy, scipy
    python testing/test_mht_testdrive.py

Data: place the Banerjee files in the repo's top-level testing/data/
(see testing/README.md; Harvard Dataverse DOI 10.7910/DVN/NHIXNT).
"""

import os
import sys
import numpy as np
import pandas as pd

# Some country arms have degenerate/collinear designs (e.g. all-missing for an
# outcome), which yield NaN standard errors. That is expected for this simple
# showcase; silence the resulting numpy warnings to keep the log readable.
np.seterr(invalid="ignore", divide="ignore")

# Auto-detect package root (the python/ directory containing src/mhtopt/)
if os.path.exists("src/mhtopt/__init__.py"):          # run from python/
    root = os.getcwd()
elif os.path.exists("../src/mhtopt/__init__.py"):     # run from python/testing/
    root = os.path.abspath("..")
else:
    raise RuntimeError("Please run from the python/ directory or python/testing/")
sys.path.insert(0, os.path.join(root, "src"))

from mhtopt import mht_critical, mht_test, mht_est, mht_table
from mhtopt.table import print_table

# Shared validation data lives at the repo's top-level testing/data/
dta_path = os.path.join(root, "..", "testing", "data")

print()
print("=" * 70)
print("  MHT Test Drive: Banerjee et al. (Science 2015)")
print("  Viviano, Wuthrich, and Niehaus (2026)")
print("=" * 70)

# ============================================================================
# Reference table
# ============================================================================
print("\n--- Reference table ---\n")
tbl = mht_table(alpha_bar=[0.05], J_range=[1, 2, 3, 5, 6, 10],
                nm_ratios=[0.5, 1.0, 2.0])
print_table(tbl)

# ============================================================================
# Load data (shared by the country-arms analysis below)
# ============================================================================
hh_data = pd.read_stata(os.path.join(dta_path, "index_hh_vars.dta"))
control_hh = [c for c in hh_data.columns if c.startswith("control_")]

# ============================================================================
# One outcome x 6 country arms (J=6)
# ============================================================================
print("\n\n" + "=" * 50)
print("  One outcome x 6 country arms (J=6)")
print("  Reference: Figure 3, Table 4, Banerjee et al. (2015)")
print("=" * 50)

hh_all = hh_data.copy()
for c in range(1, 7):
    hh_all[f"treat_c{c}"] = ((hh_all["treatment"] == 1) & (hh_all["country"] == c)).astype(float)

treat_vars = [f"treat_c{c}" for c in range(1, 7)]


def run_country_mht(data, outcome_var, label, control_cols, alpha_bar=0.05):
    """Run 6-country regression and apply mht_est."""
    end_var = f"{outcome_var}_end"
    bsl_var = f"{outcome_var}_bsl"
    m_bsl = f"m_{outcome_var}_bsl"

    for aux in [bsl_var, m_bsl]:
        if aux not in data.columns:
            data[aux] = 0.0

    rhs_cols = treat_vars + [bsl_var, m_bsl] + control_cols
    rhs_cols = [c for c in rhs_cols if c in data.columns]

    y = pd.to_numeric(data[end_var], errors="coerce").values.astype(float)
    X_data = data[rhs_cols].apply(pd.to_numeric, errors="coerce").values.astype(float)
    X = np.column_stack([np.ones(len(y)), X_data])

    mask = ~(np.isnan(y) | np.any(np.isnan(X), axis=1))
    y, X = y[mask], X[mask]

    n_obs = len(y)
    k = X.shape[1]
    beta_hat = np.linalg.lstsq(X, y, rcond=None)[0]
    e = y - X @ beta_hat
    s2 = np.sum(e**2) / (n_obs - k)
    se = np.sqrt(s2 * np.diag(np.linalg.pinv(X.T @ X)))

    from scipy.stats import t as t_dist
    t_stats = beta_hat / se
    p_values = 2 * t_dist.sf(np.abs(t_stats), df=n_obs - k)

    # Build dict fit for treat_vars (indices 1..6 after intercept)
    all_names = ["const"] + rhs_cols
    fit = {
        "index": all_names,
        "params": beta_hat,
        "std_errors": se,
        "t_stats": t_stats,
        "p_values": p_values,
        "nobs": n_obs,
    }

    print(f"\n--- {label}: 6 country-specific treatments ---")
    print("    (1=Ethiopia, 2=Ghana, 3=Honduras, 4=India, 5=Pakistan, 6=Peru)")

    r = mht_est(fit, vars=treat_vars, alpha_bar=alpha_bar)
    print(f"\n  FDA default (cf_share=0.46): alpha_opt = {r['alpha_opt']:.6f}")
    for i, term in enumerate(r["terms"]):
        print(f"    {term}  coef={r['estimates'][i]:7.4f}  "
              f"p={r['p_values'][i]:.4f}  "
              f"opt={'*' if r['reject_optimal'][i] else '.'}")

    r2 = mht_est(fit, vars=treat_vars, alpha_bar=alpha_bar, cf_share=0.23, J_bar=6)
    print(f"\n  Study-specific (cf_share=0.23, J_bar=6): alpha_opt = {r2['alpha_opt']:.6f}")
    for i, term in enumerate(r2["terms"]):
        print(f"    {term}  coef={r2['estimates'][i]:7.4f}  "
              f"p={r2['p_values'][i]:.4f}  "
              f"opt={'*' if r2['reject_optimal'][i] else '.'}")


run_country_mht(hh_all, "index_ctotal", "Consumption", control_hh)
run_country_mht(hh_all, "ind_increv", "Income & revenues", control_hh)
run_country_mht(hh_all, "asset_index", "Assets", control_hh)
run_country_mht(hh_all, "index_foodsecurity", "Food security", control_hh)
run_country_mht(hh_all, "ind_fin", "Financial inclusion", control_hh)


# ============================================================================
# Summary
# ============================================================================
print("\n\n" + "=" * 50)
print("  SUMMARY: One outcome x 6 country arms")
print("=" * 50)
print()
print("  Cost structure: adding a country arm is EXPENSIVE (cf_share ~ 0.10-0.23)")
print("  => Minimal correction needed (alpha* ~ 0.02-0.04, near unadjusted)")
print("  => VWN-Lin retains country effects that BH's step-up rule discards")
print()
print("  Correction cuts both ways: it can remove marginally-significant results")
print("  or restore ones that FDR procedures discard. See results_note.pdf.")
print("\nDone.")
