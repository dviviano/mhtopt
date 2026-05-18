# MHT Package for R -- Documentation

**Viviano, Wuthrich, and Niehaus (2026)**
*"A Model of Multiple Hypothesis Testing"* -- arXiv:2104.13367v10

---

## Overview

This package implements the optimal multiple hypothesis testing correction from Proposition 4.1 of Viviano, Wuthrich, and Niehaus (2026). The key insight: the appropriate severity of MHT correction depends on the *cost structure* of the study. Fixed costs favor strict corrections (Bonferroni); proportional costs favor no adjustment; intermediate cost structures yield intermediate corrections.

The optimal per-test significance level is:

```
alpha*(J, Sigma) = C(J, Sigma) / (b * omega_bar(J))
```

where C is the cost function, b is the benefit of a true positive, and omega_bar is the average prior probability of a true effect.

---

## Functions

### `mht_critical(J, alpha_bar, ...)`

Computes the optimal per-test significance level alpha* for J hypotheses.

**Arguments:**
- `J` -- Number of hypotheses (integer or `Inf`)
- `alpha_bar` -- Benchmark single-hypothesis test size (e.g., 0.05)
- `model` -- `"linear"` (default) or `"cobbdouglas"`
- `cf_share` -- Fixed cost share (Linear model). Default 0.46
- `J_bar` -- Average subgroups (Linear model). Default 3
- `nm_ratio` -- Sample size ratio n_bar/m_bar. Default 1.0
- `beta` -- Arms elasticity (Cobb-Douglas). Default 0.13
- `iota` -- Sample size elasticity (Cobb-Douglas). Default 0.075

**Returns:** List with `alpha_opt`, `t_star`, `alpha_bonf`, `t_bonf`, `alpha_sidak`, `t_sidak`, etc.

**Linear formula (Eq. 27):**
```
alpha* = alpha_bar * [(1 + ratio/J) / (1 + ratio) + (nm_ratio - 1) / (1 + ratio)]
where ratio = cf_share * J_bar / (1 - cf_share)
```

**Cobb-Douglas formula (Appendix A):**
```
alpha* = alpha_bar * J^(beta - 1) * nm_ratio^iota
```

---

### `mht_test(p, alpha_bar, ...)`

Applies MHT adjustment to a vector of p-values. Reports rejection decisions under 5 procedures.

**Arguments:**
- `p` -- Numeric vector of one-sided p-values (provide `p` or `z`, not both)
- `z` -- Numeric vector of z-statistics (converted to p via `1 - pnorm(z)`)
- `alpha_bar` -- Benchmark test size
- All `mht_critical` parameters (model, cf_share, etc.)

**Returns:** Data frame with columns `p_value`, `reject_optimal`, `reject_bonferroni`, `reject_holm`, `reject_bh`, `reject_unadjusted`.

---

### `mht_est(fit, vars, alpha_bar, ...)`

Postestimation: extracts coefficients from a fitted model and applies MHT adjustment.

**Arguments:**
- `fit` -- Fitted model object (lm, glm, fixest, estimatr)
- `vars` -- Character vector of coefficient names to test. If NULL, all non-intercept coefficients.
- `alpha_bar` -- Benchmark test size
- `onesided` -- Logical. Default TRUE (one-sided in positive direction, per Remark 6)
- `mbar` -- Benchmark per-arm sample size. If supplied, `nm_ratio = (nobs/J) / mbar`
- All `mht_critical` parameters

**Returns:** Data frame with `term`, `estimate`, `std_error`, `t_stat`, `p_value`, and 5 rejection columns.

**Supported model classes:**
- `lm`, `glm` (base R)
- `lm_robust`, `iv_robust` (estimatr)
- `feols`, `fepois`, `feglm` (fixest)
- Any class where `coef(summary(fit))` returns a standard coefficient matrix

**One-sided vs. two-sided:**
- One-sided (default): grounded in Remark 6 -- status quo holds when no finding; negative effects never lead to rejection
- Two-sided (`onesided = FALSE`): appropriate when policymaker may act even without positive recommendation (Appendix B.2, Proposition 9)

---

### `mht_cost_estimate(cost, arms, sample_size, alpha_bar, ...)`

Estimates cost function parameters from project-level data.

**Arguments:**
- `cost` -- Total project costs
- `arms` -- Number of treatment arms
- `sample_size` -- Sample size
- `alpha_bar` -- Benchmark test size
- `model` -- `"cobbdouglas"` (default) or `"linear_share"`
- `controls` -- Optional data frame of control variables
- `robust` -- Use HC1 robust standard errors. Default TRUE

**Returns (Cobb-Douglas):** `beta`, `iota`, standard errors, p-values for H0: beta=0, beta=1, iota=0, iota=1.

**Returns (Linear):** `c_f` (fixed cost), `c_v` (variable cost), `cf_share`.

---

### `mht_table(alpha_bar, J_range, nm_ratios, ...)`

Generates a table of optimal critical values. Default arguments reproduce Table 1 of the paper.

**Arguments:**
- `alpha_bar` -- Vector of benchmark sizes. Default `c(0.025, 0.05, 0.1, 0.15)`
- `J_range` -- Vector of hypothesis counts. Default `c(1:9, Inf)`
- `nm_ratios` -- Vector of sample size ratios. Default `c(0.5, 1.0, 1.5, 2.0)`
- `sidak_bars` -- Alpha values for Sidak benchmark columns. Default `c(0.025, 0.05)`
- `model` -- `"linear"` or `"cobbdouglas"`

**Returns:** Data frame (class `mht_table`) with custom print method.

---

## Cost Models

### Linear (FDA calibration, default)

Based on Sertkaya et al. (2016) cost data for FDA clinical trials.

- `cf_share = 0.46`: 46% of total trial cost is fixed (protocol design, site setup)
- `J_bar = 3`: average number of treatment arms/subgroups across trials

**Interpretation:** Each additional hypothesis adds proportional variable cost, so the correction depends on the ratio of fixed to variable costs. Higher `cf_share` => more conservative (closer to Bonferroni).

### Cobb-Douglas (J-PAL calibration)

Based on Column 4 of Table 2 in the paper (J-PAL RCT cost data, most-controlled specification).

- `beta = 0.13`: cost elasticity w.r.t. number of arms (a 10% increase in arms raises cost by 1.3%)
- `iota = 0.075`: cost elasticity w.r.t. sample size per arm

**Interpretation:** `beta` close to 0 means adding arms is nearly free (costs are mostly fixed) => correction is severe (near Bonferroni). `beta` close to 1 means adding arms costs proportionally => no correction needed.

---

## Default Parameter Values

| Parameter | Default | Source |
|---|---|---|
| `cf_share` | 0.46 | Sertkaya et al. (2016), FDA trial cost survey |
| `J_bar` | 3 | Pocock et al. (2002), survey of RCT practice |
| `beta` | 0.13 | Table 2 Column 4 (J-PAL data, most-controlled) |
| `iota` | 0.075 | Table 2 Column 4 |
| `alpha_bar` | -- | User must specify |
| `nm_ratio` | 1.0 | Study has same per-arm N as benchmark |

---

## Comparison of Procedures

| Procedure | When appropriate | This package |
|---|---|---|
| Bonferroni | All costs fixed (cf_share = 1) | Always reported |
| Holm | Same as Bonferroni but less conservative | Always reported |
| BH (FDR) | Control false discovery rate | Always reported |
| Unadjusted | All costs proportional (cf_share = 0) | Always reported |
| **Optimal** | **Real cost structure (intermediate)** | **Main result** |

---

## Examples

### Minimal: compute alpha* for 5 hypotheses
```r
mht_critical(J = 5, alpha_bar = 0.05)
```

### After a regression
```r
fit <- lm(y ~ treat1 + treat2 + treat3 + x1 + x2, data = mydata)
mht_est(fit, vars = c("treat1", "treat2", "treat3"), alpha_bar = 0.05)
```

### With Cobb-Douglas and mbar
```r
mht_est(fit, vars = c("treat1", "treat2", "treat3"),
        alpha_bar = 0.05, model = "cobbdouglas", mbar = 200)
```

### From p-values directly
```r
pvals <- c(0.003, 0.015, 0.048, 0.120)
mht_test(p = pvals, alpha_bar = 0.05)
```

### Generate Table 1
```r
mht_table()  # reproduces paper Table 1 exactly
```

### Estimate cost parameters
```r
est <- mht_cost_estimate(cost_data, arms_data, n_data, alpha_bar = 0.05)
mht_critical(J = 5, alpha_bar = 0.05, model = "cobbdouglas",
             beta = est$beta, iota = est$iota)
```
