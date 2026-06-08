"""
MHT Test Drive: Banerjee et al. (Science 2015)
Viviano, Wuthrich, and Niehaus (2026), "A Model of Multiple Hypothesis Testing"

Requires: pandas (for reading .dta files)

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
from scipy.stats import norm

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
# VERSION A: 10 Outcomes, India
# ============================================================================
print()
print("=" * 50)
print("  VERSION A: 10 Outcomes, India")
print("  Reference: Table 3, Banerjee et al. (2015)")
print("=" * 50)

hh_outcomes = ["index_ctotal", "ind_increv", "asset_index",
               "index_foodsecurity", "ind_fin"]
mb_outcomes = ["index_time", "index_health", "index_mental",
               "index_political", "index_women"]
outcome_labels = ["Consumption", "Income", "Assets", "FoodSec", "Finance",
                  "TimeUse", "PhysHealth", "MentHealth", "Political", "WomenEmp"]

# Load data
hh_data = pd.read_stata(os.path.join(dta_path, "index_hh_vars.dta"))
hh_india = hh_data[hh_data["country"] == 4].copy()

mb_data = pd.read_stata(os.path.join(dta_path, "index_mb_vars.dta"))
mb_india = mb_data[mb_data["country"] == 4].copy()

control_hh = [c for c in hh_india.columns if c.startswith("control_")]
control_mb = [c for c in mb_india.columns if c.startswith("control_")]


def run_regression_collect_pval(data, outcome_var, control_cols):
    """Run OLS and return one-sided p-value for treatment coefficient."""
    end_var = f"{outcome_var}_end"
    bsl_var = f"{outcome_var}_bsl"
    m_bsl = f"m_{outcome_var}_bsl"
    m_country_bsl = f"m_country_{outcome_var}_bsl"

    # Ensure baseline vars exist
    for aux in [bsl_var, m_bsl, m_country_bsl]:
        if aux not in data.columns:
            data[aux] = 0.0

    rhs_cols = ["treatment", bsl_var, m_bsl, m_country_bsl] + control_cols
    rhs_cols = [c for c in rhs_cols if c in data.columns]

    y = pd.to_numeric(data[end_var], errors="coerce").values.astype(float)
    X = data[rhs_cols].apply(pd.to_numeric, errors="coerce").values.astype(float)
    X = np.column_stack([np.ones(len(y)), X])

    # Drop rows with NaN
    mask = ~(np.isnan(y) | np.any(np.isnan(X), axis=1))
    y, X = y[mask], X[mask]

    beta_hat = np.linalg.lstsq(X, y, rcond=None)[0]
    e = y - X @ beta_hat
    n_obs = len(y)
    k = X.shape[1]
    s2 = np.sum(e**2) / (n_obs - k)
    se = np.sqrt(s2 * np.diag(np.linalg.pinv(X.T @ X)))

    # treatment is column index 1 (after intercept)
    coef = beta_hat[1]
    se_val = se[1]
    t_val = coef / se_val

    # One-sided p-value (positive direction)
    if t_val >= 0:
        p_one = 1 - norm.cdf(t_val)
    else:
        p_one = 1 - (1 - norm.cdf(abs(t_val))) / 2

    return coef, se_val, t_val, p_one


# Collect results
results = []
for var in hh_outcomes:
    coef, se, t, p = run_regression_collect_pval(hh_india, var, control_hh)
    results.append((var, coef, se, t, p))
for var in mb_outcomes:
    coef, se, t, p = run_regression_collect_pval(mb_india, var, control_mb)
    results.append((var, coef, se, t, p))

p_all = np.array([r[4] for r in results])

print("\nRegression summary (India, treatment, one-sided p):")
print(f"  {'Outcome':>12}  {'Coef':>8}  {'SE':>8}  {'t':>8}  {'p':>10}")
for i, (var, coef, se, t, p) in enumerate(results):
    print(f"  {outcome_labels[i]:>12}  {coef:8.4f}  {se:8.4f}  {t:8.3f}  {p:10.6f}")

# --- mht_test: Linear model ---
print("\n--- mht_test: Linear model (cf_share=0.46), alpha_bar=0.05 ---\n")
r_lin = mht_test(p=p_all, alpha_bar=0.05)
print(f"  alpha_opt = {r_lin['alpha_opt']:.6f}")
print(f"  Rejections: opt={r_lin['reject_optimal'].sum()}, "
      f"bonf={r_lin['reject_bonferroni'].sum()}, "
      f"holm={r_lin['reject_holm'].sum()}, "
      f"bh={r_lin['reject_bh'].sum()}, "
      f"unadj={r_lin['reject_unadjusted'].sum()}")

# --- mht_test: Cobb-Douglas ---
print("\n--- mht_test: Cobb-Douglas (beta=0.13, iota=0.075) ---\n")
r_cd = mht_test(p=p_all, alpha_bar=0.05, model="cobbdouglas")
print(f"  alpha_opt = {r_cd['alpha_opt']:.6f}")
print(f"  Rejections: opt={r_cd['reject_optimal'].sum()}")

# --- Study-specific calibration ---
print("\n--- Study-specific calibration (Table 4 cost data) ---")
J = 10
for cf in [0.46, 0.75, 0.82, 0.90]:
    r = mht_critical(J=J, alpha_bar=0.05, cf_share=cf)
    print(f"  cf_share={cf:.2f}: alpha* = {r['alpha_opt']:.5f}")
print(f"  Bonferroni:     alpha* = {0.05/J:.5f}")


# ============================================================================
# VERSION B: 6 Countries as 6 Treatments
# ============================================================================
print("\n\n" + "=" * 50)
print("  VERSION B: 6 Countries as 6 Treatments")
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

    r2 = mht_est(fit, vars=treat_vars, alpha_bar=alpha_bar, cf_share=0.10)
    print(f"\n  Study-specific (cf_share=0.10): alpha_opt = {r2['alpha_opt']:.6f}")
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
print("  SUMMARY: Version A vs Version B")
print("=" * 50)
print()
print("  Version A (10 outcomes, India):")
print("    Cost structure: adding outcomes is CHEAP (cf_share ~ 0.82)")
print("    => Strict correction needed (alpha* ~ 0.008, near Bonferroni)")
print("    => Confirms 5 core results; physical health is borderline")
print()
print("  Version B (6 countries, pooled):")
print("    Cost structure: adding a country is EXPENSIVE (cf_share ~ 0.10)")
print("    => Minimal correction needed (alpha* ~ 0.040, near unadjusted)")
print("    => Retains effects that Bonferroni would discard")
print()
print("  Same data, two framings, opposite corrections.")
print("  This is the core insight of VWN (2026).")
print("\nDone.")
