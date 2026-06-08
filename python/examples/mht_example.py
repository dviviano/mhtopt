"""
MHT Package for Python -- Complete Example
Viviano, Wuthrich, and Niehaus (2026)

Demonstrates all five package functions using built-in and simulated data.

To run:
    cd python
    pip install -e .
    python examples/mht_example.py
"""

import numpy as np
from mhtopt import mht_critical, mht_test, mht_est, mht_cost_estimate, mht_table
from mhtopt.table import print_table

print()
print("=" * 70)
print("  MHT Package for Python -- Complete Example")
print("  Viviano, Wuthrich, and Niehaus (2026)")
print("=" * 70)

# --------------------------------------------------------------------------
# 1. mht_critical: Compute optimal critical values
# --------------------------------------------------------------------------
print("\n--- 1. mht_critical ---\n")

# Linear model (default): 5 hypotheses, benchmark alpha = 0.05
r1 = mht_critical(J=5, alpha_bar=0.05)
print(f"Linear model, J=5, alpha_bar=0.05:")
print(f"  alpha_opt = {r1['alpha_opt']:.6f}")
print(f"  t_star    = {r1['t_star']:.4f}")
print(f"  alpha_bonf = {r1['alpha_bonf']:.6f}")
print(f"  alpha_sidak = {r1['alpha_sidak']:.6f}")

# Cobb-Douglas model
r2 = mht_critical(J=5, alpha_bar=0.05, model="cobbdouglas")
print(f"\nCobb-Douglas model, J=5, alpha_bar=0.05:")
print(f"  alpha_opt = {r2['alpha_opt']:.6f}")
print(f"  t_star    = {r2['t_star']:.4f}")

# Larger sample
r3 = mht_critical(J=5, alpha_bar=0.05, nm_ratio=1.5)
print(f"\nLinear model, J=5, alpha_bar=0.05, nm_ratio=1.5:")
print(f"  alpha_opt = {r3['alpha_opt']:.6f}")

# --------------------------------------------------------------------------
# 2. mht_test: Test p-values directly
# --------------------------------------------------------------------------
print("\n--- 2. mht_test ---\n")

pvals = [0.003, 0.015, 0.030, 0.048, 0.120, 0.500]
print(f"Testing 6 p-values: {pvals}\n")

result = mht_test(p=pvals, alpha_bar=0.05)
print(f"  alpha_opt = {result['alpha_opt']:.6f}")
print(f"  Rejections: optimal={result['reject_optimal'].sum()}, "
      f"bonf={result['reject_bonferroni'].sum()}, "
      f"holm={result['reject_holm'].sum()}, "
      f"bh={result['reject_bh'].sum()}, "
      f"unadj={result['reject_unadjusted'].sum()}")
print()
for i, p in enumerate(pvals):
    print(f"  p={p:.3f}  opt={'*' if result['reject_optimal'][i] else '.'}  "
          f"bonf={'*' if result['reject_bonferroni'][i] else '.'}  "
          f"holm={'*' if result['reject_holm'][i] else '.'}  "
          f"bh={'*' if result['reject_bh'][i] else '.'}  "
          f"unadj={'*' if result['reject_unadjusted'][i] else '.'}")

# --------------------------------------------------------------------------
# 3. mht_est: Postestimation after a regression
# --------------------------------------------------------------------------
print("\n--- 3. mht_est ---\n")

# Simulate an RCT with 4 treatment arms
np.random.seed(123)
n = 500
treat1 = np.random.binomial(1, 0.2, n)
treat2 = np.random.binomial(1, 0.2, n)
treat3 = np.random.binomial(1, 0.2, n)
treat4 = np.random.binomial(1, 0.2, n)
x1 = np.random.randn(n)
y = 0.3 * treat1 + 0.1 * treat2 + 0.0 * treat3 - 0.05 * treat4 + 0.5 * x1 + np.random.randn(n)

# Manual OLS (no statsmodels dependency required)
X = np.column_stack([np.ones(n), treat1, treat2, treat3, treat4, x1])
beta_hat = np.linalg.lstsq(X, y, rcond=None)[0]
e = y - X @ beta_hat
s2 = np.sum(e**2) / (n - 6)
se = np.sqrt(s2 * np.diag(np.linalg.inv(X.T @ X)))
t_stats = beta_hat / se
from scipy.stats import t as t_dist
p_values = 2 * t_dist.sf(np.abs(t_stats), df=n - 6)

fit = {
    "index": ["const", "treat1", "treat2", "treat3", "treat4", "x1"],
    "params": beta_hat,
    "std_errors": se,
    "t_stats": t_stats,
    "p_values": p_values,
    "nobs": n,
}

print("Regression: y ~ treat1 + treat2 + treat3 + treat4 + x1")
print("Testing 4 treatment coefficients:\n")

mht_result = mht_est(fit, vars=["treat1", "treat2", "treat3", "treat4"],
                     alpha_bar=0.05)
print(f"  alpha_opt = {mht_result['alpha_opt']:.6f}")
print(f"  Rejections: optimal={mht_result['reject_optimal'].sum()}")
print()
for i, term in enumerate(mht_result["terms"]):
    print(f"  {term:>8}  coef={mht_result['estimates'][i]:7.4f}  "
          f"p={mht_result['p_values'][i]:.4f}  "
          f"opt={'*' if mht_result['reject_optimal'][i] else '.'}")

# --------------------------------------------------------------------------
# 4. mht_table: Generate reference tables
# --------------------------------------------------------------------------
print("\n--- 4. mht_table ---\n")

# Default: reproduces Table 1 of the paper
tbl = mht_table()
print_table(tbl)

# --------------------------------------------------------------------------
# 5. mht_cost_estimate: Estimate cost parameters from data
# --------------------------------------------------------------------------
print("\n--- 5. mht_cost_estimate ---\n")

np.random.seed(42)
n_projects = 300
arms_data = np.random.choice(range(1, 6), n_projects)
ss_data = np.random.choice(range(500, 5001), n_projects)
cost_data = np.exp(10 + 0.2 * np.log(arms_data) + 0.15 * np.log(ss_data) +
                   np.random.randn(n_projects) * 0.4)

print("Estimating Cobb-Douglas from 300 simulated projects:\n")
est = mht_cost_estimate(cost_data, arms_data, ss_data, alpha_bar=0.05)
print(f"  beta = {est['beta']:.4f} (se = {est['beta_se']:.4f})")
print(f"  iota = {est['iota']:.4f} (se = {est['iota_se']:.4f})")
print(f"  H0: beta=0, p = {est['p_beta0']:.4f}")
print(f"  H0: beta=1, p = {est['p_beta1']:.4f}")

# Use estimated parameters
r_est = mht_critical(J=5, alpha_bar=0.05, model="cobbdouglas",
                     beta=est["beta"], iota=est["iota"])
print(f"\n  Using estimated params for J=5: alpha_opt = {r_est['alpha_opt']:.6f}")

print()
print("=" * 70)
print("  Example complete.")
print("=" * 70)
