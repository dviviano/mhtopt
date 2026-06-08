# mhtopt (R)

**Optimal Multiple Hypothesis Testing Corrections — R port**

R implementation of the optimal MHT correction from:

> Viviano, D., Wüthrich, K., and Niehaus, P. (2026). *A Model of Multiple Hypothesis Testing.* arXiv:[2104.13367](https://arxiv.org/abs/2104.13367).

Standard MHT corrections (Bonferroni, Holm, BH) are ad hoc. `mhtopt` derives the optimal per-test significance level α\* from the economic incentives of research production. The result sits between Bonferroni (too conservative) and unadjusted (too permissive), with the exact position determined by the study's cost structure.

Two cost models, both calibrated to real data:

- **Linear** (default): fixed-cost share 0.46 (Sertkaya et al. 2016)
- **Cobb-Douglas** (J-PAL, Table 2 of paper): β = 0.13, ι = 0.075

## Installation

```r
install.packages("mhtopt")
```

Requires base R only (`stats`). Suggested for full use: `fixest`, `estimatr` (extra model classes), `haven` (read `.dta` files for examples), `testthat` (run tests).

Development install:

```r
# install.packages("remotes")
remotes::install_github("dviviano/mhtopt", subdir = "r/mhtopt")
```

## Quick start

```r
library(mhtopt)

# Optimal critical value for 5 hypotheses
mht_critical(J = 5, alpha_bar = 0.05)        # alpha_opt = 0.0212

# Apply MHT adjustment to p-values
mht_test(p = c(0.003, 0.015, 0.048, 0.080), alpha_bar = 0.05)

# Postestimation after lm/glm/fixest/estimatr
fit <- lm(mpg ~ wt + hp + qsec + drat, data = mtcars)
mht_est(fit, vars = c("wt", "hp", "qsec", "drat"), alpha_bar = 0.05)
```

A full self-contained example:

```r
source("examples/mht_example.R")
```

## Five exported functions

| Function | Purpose |
|---|---|
| `mht_critical()` | Compute optimal critical value α\* |
| `mht_test()` | Apply MHT adjustment to a vector of p-values |
| `mht_est()` | Postestimation: test J coefficients from a fitted model |
| `mht_cost_estimate()` | Estimate cost-function parameters (β, ι) from project-level data |
| `mht_table()` | Generate reference tables (reproduces Tables 1 & 3 of the paper) |

Two cost models: `"linear"` (default, FDA calibration) and `"cobbdouglas"` (J-PAL calibration). Each function reports optimal, Bonferroni, Holm, BH, and unadjusted side by side.

## Worked example with real data

A walkthrough applying the package to Banerjee et al. (2015, *Science*) — a 6-country graduation-program RCT with 10 outcome families — is in [`testing/`](testing/):

```r
install.packages("haven")  # needed for .dta files
source("testing/test_mht_testdrive.R")
```

## Documentation

- Function-level: `?mht_critical`, `?mht_test`, etc.
- Full reference: [`docs/`](docs/)
- Paper: [arXiv:2104.13367](https://arxiv.org/abs/2104.13367)

## Citation

```r
citation("mhtopt")
```

## Other language ports

The same five functions are available in Stata (`ssc install mhtopt`) and Python (`pip install mhtopt`). See the [project repository](https://github.com/dviviano/mhtopt) for cross-language documentation.

## Reporting bugs

Open a [GitHub issue](https://github.com/dviviano/mhtopt/issues) and indicate `packageVersion("mhtopt")` and `R.version.string`.

## License

MIT — see [LICENSE](mhtopt/LICENSE).
