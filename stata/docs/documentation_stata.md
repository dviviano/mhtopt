# MHT Package — Stata Documentation

**Version 2.0.0 | Viviano, Wuthrich, and Niehaus (2026)**

> "A Model of Multiple Hypothesis Testing" — *arXiv:2104.13367v10*

---

## 1. Overview

The `mht` package implements the **economically optimal multiple hypothesis testing (MHT)** framework from Viviano, Wuthrich, and Niehaus (2026). The optimal per-test significance level is (Proposition 4.1):

```
alpha*(J) = C(J, Sigma) / (b * omega_bar(J))
```

This simplifies to closed-form expressions depending on the cost structure (Equations 26–27).

### Commands

| Command | Purpose |
|---|---|
| `mht_critical` | Compute optimal critical values (core formula) |
| `mht_test` | Test a variable of p-values with 5 procedures |
| `mht_est` | Postestimation: test J treatment coefficients |
| `mht_cost_estimate` | Estimate cost function parameters from data |
| `mht_table` | Generate reference tables of critical values |

---

## 2. Installation

```stata
adopath + "path/to/critique/stata"
```

---

## 3. `mht_est` — Postestimation

Works after any standard estimation command (`regress`, `ivregress`, `logit`, `areg`, `xtreg`, `reghdfe`, etc.).

```stata
mht_est, vars(varlist) alphabar(#)
        [model(string) cfshare(#) jbar(#) nmratio(#) mbar(#) beta(#) iota(#)
         onesided twosided]
```

### Options

| Option | Type | Default | Description |
|---|---|---|---|
| `vars(varlist)` | varlist | — | Names of coefficients to test (must match `e(b)`) |
| `alphabar(#)` | (0,1) | — | Benchmark significance level |
| `onesided` / `twosided` | flag | `onesided` | Direction of test; see Section 7 |
| `mbar(#)` | numeric | — | Benchmark per-arm sample size. Sets `nm_ratio = (e(N)/J) / mbar`. Overrides `nmratio`. |
| `model(string)` | string | `"linear"` | `"linear"` or `"cobbdouglas"` |
| `cfshare(#)` | (0,1) | 0.46 | Fixed cost share (Linear model) |
| `jbar(#)` | > 0 | 3 | Average arms per trial (Linear model) |
| `nmratio(#)` | > 0 | 1.0 | Study sample size / benchmark |
| `beta(#)` | real | 0.13 | Cost elasticity w.r.t. arms (Cobb-Douglas) |
| `iota(#)` | real | 0.075 | Cost elasticity w.r.t. sample size (Cobb-Douglas) |

### Stored results

**Scalars:** `r(alpha_opt)`, `r(alpha_bonf)`, `r(alpha_bar)`, `r(J)`, `r(nm_ratio)`, `r(n_reject_opt)`, `r(n_reject_bonf)`, `r(n_reject_holm)`, `r(n_reject_bh)`, `r(n_reject_unadj)`, `r(coef_<var>)`, `r(se_<var>)`, `r(t_<var>)`, `r(p_<var>)`, `r(rej_opt_<var>)`, `r(rej_bonf_<var>)`, `r(rej_holm_<var>)`, `r(rej_bh_<var>)` for each tested variable.

**Macros:** `r(model)`, `r(vars)`.

### Examples

```stata
* Basic usage
regress consumption treat1 treat2 treat3 baseline controls, cluster(hh_id)
mht_est, vars(treat1 treat2 treat3) alphabar(0.05)

* Cobb-Douglas calibration
mht_est, vars(treat1 treat2 treat3) alphabar(0.05) ///
         model(cobbdouglas) beta(0.13) iota(0.075)

* With benchmark sample size
mht_est, vars(treat1 treat2 treat3) alphabar(0.05) mbar(500)

* After areg with FE
areg consumption treat baseline controls, absorb(village) cluster(rand_unit)
mht_est, vars(treat) alphabar(0.05)

* Two-sided
logit adoption treat1 treat2, robust
mht_est, vars(treat1 treat2) alphabar(0.05) twosided
```

---

## 4. `mht_critical` — Compute Optimal Critical Values

Computes the optimal per-test significance level for a given number of hypotheses and cost model. Called internally by `mht_est`.

```stata
mht_critical, jhypotheses(#) alphabar(#)
             [model(string) cfshare(#) jbar(#) nmratio(#) beta(#) iota(#)]
```

### Options

| Option | Type | Default | Description |
|---|---|---|---|
| `jhypotheses(#)` | Integer >= 1 | — | Number of hypotheses |
| `alphabar(#)` | (0,1) | — | Benchmark significance level |
| `model(string)` | string | `"linear"` | `"linear"` (Eq. 26) or `"cobbdouglas"` |
| `cfshare(#)` | (0,1) | 0.46 | Fixed cost share |
| `jbar(#)` | > 0 | 3 | Average arms per trial |
| `nmratio(#)` | > 0 | 1.0 | Study sample size / benchmark |
| `beta(#)` | real | 0.13 | Cost elasticity w.r.t. arms |
| `iota(#)` | real | 0.075 | Cost elasticity w.r.t. sample size |

### Stored results

**Scalars:** `r(alpha_opt)`, `r(t_star)`, `r(alpha_bonf)`, `r(t_bonf)`.

### Examples

```stata
mht_critical, jhypotheses(5) alphabar(0.05)
display "Optimal alpha: " r(alpha_opt) "  Bonferroni: " r(alpha_bonf)

mht_critical, jhypotheses(5) alphabar(0.05) model(cobbdouglas)
```

---

## 5. `mht_test` — Test a Variable of P-Values

Applies MHT adjustment to a pre-computed variable of p-values already in memory.

```stata
mht_test varname [if] [in], alphabar(#)
        [model(string) zstat generate(string) replace
         cfshare(#) jbar(#) nmratio(#) beta(#) iota(#)]
```

### Options

| Option | Description |
|---|---|
| `varname` | Variable with one-sided p-values (or z-stats with `zstat`) |
| `alphabar(#)` | Benchmark significance level |
| `zstat` | Treat input as z-statistics |
| `generate(prefix)` | Prefix for output variables (default: `mht`) |
| `replace` | Replace existing output variables |

### Generated variables

`{prefix}_reject_opt`, `{prefix}_reject_bonf`, `{prefix}_reject_holm`, `{prefix}_reject_bh`, `{prefix}_reject_unadj`, `{prefix}_alpha_opt`.

---

## 6. `mht_cost_estimate` — Estimate Cost Function Parameters

Estimates research cost function from data on project costs, arms, and sample sizes.

```stata
mht_cost_estimate costvar armsvar sizevar, alphabar(#)
                 [model(string) controls(varlist) robust cluster(varname) table]
```

### Models

**Cobb-Douglas (default):** `log(C) = const + beta * log(J) + iota * log(n) + controls`

**Linear:** Estimates `C = c_f + c_v * J * n` to recover `cf_share = c_f / mean(C)`.

### Stored results

**Scalars:** `e(beta)`, `e(iota)`, `e(se_beta)`, `e(se_iota)`, `e(p_beta_0)`, `e(p_beta_1)`, `e(cf_share)` (Linear), `e(N)`.

### Example

```stata
mht_cost_estimate proj_cost n_arms n_obs, alphabar(0.05) robust table
local beta_est = e(beta)
local iota_est = e(iota)

regress outcome treat1 treat2, cluster(hh_id)
mht_est, vars(treat1 treat2) alphabar(0.05) ///
         model(cobbdouglas) beta(`beta_est') iota(`iota_est')
```

---

## 7. `mht_table` — Reference Table of Critical Values

```stata
mht_table [, alphabar(#) jrange(numlist) nmratios(numlist) model(string)
             cfshare(#) jbar(#) beta(#) iota(#)]
```

### Examples

```stata
mht_table                           * Table 1 (Linear, alpha_bar=0.05)
mht_table, model(cobbdouglas) jrange(1 3 5 9) nmratios(0.5 1.0 2.0)
mht_table, alphabar(0.10) jrange(1 2 3 4 5)
```

---

## 8. One-Sided vs. Two-Sided Tests

All commands default to **one-sided tests** (positive direction). This follows from the paper's model: the status quo remains when no positive finding is reported (Remark 4.1).

Use `twosided` when there is uncertainty about the policymaker's default action (Appendix B.1).

| Setting | Correct test |
|---|---|
| Drug approval, scale-up | `onesided` (default) |
| Policymaker may act without recommendation | `twosided` |

**One-sided p-value convention:** t >= 0 gives p = p_two/2; t < 0 gives p = 1 - p_two/2 (> 0.5, never rejected).

---

## 9. Interpreting Results

```
------------------------------------------------------------------------
  MHT Postestimation Results
  Viviano, Wuthrich, and Niehaus (2026)
  After: regress
------------------------------------------------------------------------
  Hypotheses tested:    3
  Benchmark alpha:      0.0500
  Cost model:           Linear (Eq. 26)
  P-values:             one-sided (positive direction)

----------------------------------------------------------
  Procedure              Test size    Rejections
----------------------------------------------------------
  Optimal (model-based)  0.028571             2
  Bonferroni             0.016667             1
  Holm (step-down)       step-wise            2
  BH (FDR control)       step-wise            2
  Unadjusted             0.050000             3
----------------------------------------------------------
```

The optimal alpha* lies between Bonferroni and unadjusted. More fixed costs => closer to Bonferroni; more variable costs => closer to unadjusted.

---

## 10. Parameter Reference

### Linear Model

| Parameter | Option | Default | Source |
|---|---|---|---|
| Fixed cost share | `cfshare(#)` | 0.46 | Sertkaya et al. (2016) |
| Avg. arms per trial | `jbar(#)` | 3 | Pocock et al. (2002) |

### Cobb-Douglas (J-PAL)

| Parameter | Option | Default | Source |
|---|---|---|---|
| Cost elasticity (arms) | `beta(#)` | 0.13 | Paper, Appendix A |
| Cost elasticity (sample) | `iota(#)` | 0.075 | Paper, Appendix A |

**beta = 0** => Bonferroni optimal; **beta = 1** => no adjustment; **beta = 0.13** => intermediate.

---

## 11. Complete Workflow

```stata
adopath + "path/to/critique/stata"

* Step 1: Reference table
mht_table, alphabar(0.05) jrange(1 2 3 5 10)

* Step 2: Regression with multiple treatments
use hh_data.dta, clear
local arms "treat_cash treat_inkind treat_training"
areg consumption `arms' baseline_consumption controls, ///
     absorb(village) cluster(hh_id)
mht_est, vars(`arms') alphabar(0.05)

* Step 3: Data-driven calibration (if cost data available)
use jpal_costs.dta, clear
mht_cost_estimate total_cost n_arms sample_size, alphabar(0.05) robust table
local est_beta = e(beta)
local est_iota = e(iota)

use hh_data.dta, clear
areg consumption `arms' baseline_consumption controls, ///
     absorb(village) cluster(hh_id)
mht_est, vars(`arms') alphabar(0.05) model(cobbdouglas) ///
         beta(`est_beta') iota(`est_iota')
```

---

## 12. References

Viviano, D., K. Wuthrich, and P. Niehaus (2026). A model of multiple hypothesis testing. *arXiv:2104.13367v10*.

Sertkaya, A., H. H. Wong, A. Jessup, and T. Beleche (2016). Key cost drivers of pharmaceutical clinical trials in the United States. *Clinical Trials*, 13(2), 117-126.
