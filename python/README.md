# MHT Package for Python -- User Testing

**Viviano, Wuthrich, and Niehaus (2026)**
*"A Model of Multiple Hypothesis Testing"* -- arXiv:2104.13367v10

Please use the package and give us your feedback!


## What The Package Does
Standard MHT corrections (Bonferroni, Holm, BH) are ad hoc. This package derives the optimal correction from the economic incentives of research production: how costs scale with the number of hypotheses determines how much to adjust. The result is a per-test significance level alpha* that lies between Bonferroni (too conservative) and unadjusted (too permissive), with the exact position pinned down by the cost structure of the study.

Two cost models are supported, both calibrated to real data:

- Linear (default): fixed-cost share = 0.46 (Sertkaya et al. 2016)
- Cobb-Douglas (J-PAL data, Table 2 of paper):
    - beta = 0.13 -- how cost scales with treatment arms
    - iota = 0.075 -- how it scales with surveys per arm


### Key Features
- Works with statsmodels, linearmodels, or any dict of regression results
- Reports optimal, Bonferroni, Holm, BH, and unadjusted results side by side
- One-sided tests by default (grounded in Remark 6); two-sided option available
- mbar option benchmarks the study's sample size against a reference
- mht_cost_estimate estimates beta and iota from project-level cost data
- mht_table reproduces Tables 1 and 3 of the paper for any parameter values
- Full pytest test suite

---

## Quick Start

```bash
cd mht_package_python_042826
pip install -e .
```

```python
from mht import mht_critical, mht_test, mht_est, mht_cost_estimate, mht_table

# Compute optimal alpha* for 5 hypotheses
r = mht_critical(J=5, alpha_bar=0.05)
print(f"alpha* = {r['alpha_opt']:.4f}")

# Test a list of p-values
result = mht_test(p=[0.003, 0.015, 0.048], alpha_bar=0.05)

# Run the full example
# python examples/mht_example.py
```

---

## What to Try

### 1. Run the full simulated workflow

```bash
python examples/mht_example.py
```

This covers: `mht_est`, `mht_test`, `mht_table`, `mht_critical`, and `mht_cost_estimate`.

### 2. Use your own data

```python
import statsmodels.api as sm
from mht import mht_est

# After running a regression:
fit = sm.OLS(y, X).fit()
result = mht_est(fit, vars=["treat1", "treat2", "treat3"], alpha_bar=0.05)

# Or with p-values directly:
from mht import mht_test
result = mht_test(p=my_pvalues, alpha_bar=0.05)
```

### 3. Explore our worked example

We applied the package to Banerjee et al. (2015, Science):

```bash
pip install pandas  # needed for .dta files
python testing/test_mht_testdrive.py
```

---

## Package Functions

| Function | Purpose | Example |
|---|---|---|
| `mht_critical` | Compute optimal critical value | `mht_critical(J=5, alpha_bar=0.05)` |
| `mht_test` | Test a list of p-values | `mht_test(p=pvals, alpha_bar=0.05)` |
| `mht_est` | Postestimation: test J coefficients | `mht_est(fit, vars=[...], alpha_bar=0.05)` |
| `mht_cost_estimate` | Estimate cost parameters | `mht_cost_estimate(cost, arms, n, alpha_bar=0.05)` |
| `mht_table` | Generate reference tables | `mht_table(alpha_bar=[0.05])` |

Two cost models: `"linear"` (default, FDA calibration) and `"cobbdouglas"` (J-PAL calibration).

---

## Installation

```bash
# From the package directory:
pip install -e .

# Or without installation, add src/ to your path:
import sys; sys.path.insert(0, "src")
from mht import mht_critical
```

### Dependencies

- **Required:** numpy (>= 1.20), scipy (>= 1.7)
- **Optional:** pandas (for .dta files in examples), pytest (for tests), statsmodels (supported model class)

---

## Running Tests

```bash
cd mht_package_python_042826
pip install -e ".[dev]"
pytest
```

---

## Feedback

We would appreciate your feedback on:
- **Usability:** Was anything confusing? Did the functions work as expected?
- **Documentation:** Was the help sufficient? What was missing?
- **Features:** What would make the package more useful for your work?
- **Bugs:** Did anything break? Please share the error message and what you were trying to do.

Thank you!
