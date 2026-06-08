# mhtopt

**Optimal Multiple Hypothesis Testing Corrections (R port)**

R implementation of the optimal MHT correction from:

> Viviano, D., Wüthrich, K., and Niehaus, P. (2026). *A Model of Multiple Hypothesis Testing.* arXiv:2104.13367.

Standard MHT corrections (Bonferroni, Holm, BH) are ad hoc. `mhtopt` derives the optimal per-test significance level α\* from the economic incentives of research production, sitting between Bonferroni (too conservative) and unadjusted (too permissive), with position determined by the study's cost structure.

## Installation

```r
install.packages("mhtopt")
```

Development version:

```r
# install.packages("remotes")
remotes::install_github("dviviano/mhtopt", subdir = "r")
```

## Quick start

```r
library(mhtopt)

# Optimal critical value for 5 hypotheses
mht_critical(J = 5, alpha_bar = 0.05)

# Apply MHT adjustment to p-values
mht_test(p = c(0.003, 0.015, 0.048, 0.080), alpha_bar = 0.05)

# Postestimation: test J coefficients in a fitted model
fit <- lm(mpg ~ wt + hp + qsec + drat, data = mtcars)
mht_est(fit, vars = c("wt", "hp", "qsec", "drat"), alpha_bar = 0.05)
```

## Five exported functions

| Function | Purpose |
|---|---|
| `mht_critical()` | Compute optimal critical value α\* |
| `mht_test()` | Apply MHT adjustment to a vector of p-values |
| `mht_est()` | Postestimation: test J coefficients from a fitted model |
| `mht_cost_estimate()` | Estimate cost-function parameters (β, ι) from data |
| `mht_table()` | Generate reference tables (reproduces Tables 1 & 3 of the paper) |

Two cost models: `"linear"` (default, FDA calibration) and `"cobbdouglas"` (J-PAL calibration).

## Citation

```r
citation("mhtopt")
```

## Other language ports

The same five functions are available in Stata (`ssc install mhtopt`) and Python (`pip install mhtopt`). See the [project repository](https://github.com/dviviano/mhtopt) for cross-language documentation.

## License

MIT — see [LICENSE](LICENSE).
