# MHT Package for R -- User Testing

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
- Works after any standard R estimation command (lm, glm, fixest, estimatr)
- Reports optimal, Bonferroni, Holm, BH, and unadjusted results side by side
- One-sided tests by default (grounded in Remark 6); two-sided option available
- mbar option benchmarks the study's sample size against a reference
- mht_cost_estimate estimates beta and iota from project-level cost data
- mht_table reproduces Tables 1 and 3 of the paper for any parameter values
- Full roxygen2 documentation and testthat unit tests

---

## Quick Start

```r
# Option 1: Install as a package
# install.packages("mht", repos = NULL, type = "source")
# library(mht)

# Option 2: Source files directly (no installation needed)
for (f in list.files("mht/R", full.names = TRUE, pattern = "\\.R$")) source(f)

# Run the full example
source("examples/mht_example.R")
```

---

## What to Try

### 1. Run the full simulated workflow

The example script demonstrates all five functions using built-in and simulated data:

```r
source("examples/mht_example.R")
```

This covers: `mht_est`, `mht_test`, `mht_table`, `mht_critical`, and `mht_cost_estimate`.

### 2. Use your own data

```r
# After running a regression with multiple treatment arms:
fit <- lm(outcome ~ treat1 + treat2 + treat3 + controls, data = mydata)
mht_est(fit, vars = c("treat1", "treat2", "treat3"), alpha_bar = 0.05)

# Or with a vector of p-values:
mht_test(p = my_pvalues, alpha_bar = 0.05)
```

### 3. Try with published data

If you don't have your own data, these papers have public replication data and rich multiple-testing structures:

- **Finkelstein et al. (2012, QJE)** -- *The Oregon Health Insurance Experiment*. Data: https://www.nber.org/research/data/oregon-health-insurance-experiment-data
- **Casey, Glennerster, and Miguel (2012, QJE)** -- *Reshaping Institutions*. Data: https://emiguel.econ.berkeley.edu/research/reshaping-institutions-evidence-on-aid-impacts-using-a-preanalysis-plan/
- **Banerjee, Duflo, Glennerster, and Kinnan (2015, AEJ:Applied)** -- *The Miracle of Microfinance?* Data: https://www.openicpsr.org/openicpsr/project/113599

### 4. Explore our worked example

We applied the package to Banerjee et al. (2015, Science) -- a 6-country graduation program RCT with 10 outcome families:

```r
# Requires haven package for reading .dta files
# install.packages("haven")
source("testing/test_mht_testdrive.R")
```

---

## Package Functions

| Function | Purpose | Example |
|---|---|---|
| `mht_critical` | Compute optimal critical value | `mht_critical(J = 5, alpha_bar = 0.05)` |
| `mht_test` | Test a vector of p-values | `mht_test(p = pvals, alpha_bar = 0.05)` |
| `mht_est` | Postestimation: test J coefficients | `mht_est(fit, vars = c("x1", "x2"), alpha_bar = 0.05)` |
| `mht_cost_estimate` | Estimate cost parameters from data | `mht_cost_estimate(cost, arms, n, alpha_bar = 0.05)` |
| `mht_table` | Generate reference tables | `mht_table(alpha_bar = 0.05)` |

Two cost models: `"linear"` (default, FDA calibration) and `"cobbdouglas"` (J-PAL calibration).

---

## Installation

### From source (no CRAN submission yet)

```r
# From the package directory:
install.packages("mht", repos = NULL, type = "source")

# Or use devtools:
# devtools::install("mht")

# Or just source the files directly (no installation):
for (f in list.files("mht/R", full.names = TRUE, pattern = "\\.R$")) source(f)
```

### Dependencies

- **Required:** None beyond base R (stats)
- **Suggested:** `haven` (for .dta files in examples), `testthat` (for running tests), `fixest` and `estimatr` (supported model classes)

---

## Running Tests

```r
# If package is installed:
testthat::test_package("mht")

# Or source and run manually:
for (f in list.files("mht/R", full.names = TRUE, pattern = "\\.R$")) source(f)
testthat::test_dir("mht/tests/testthat")
```

---

## Feedback

We would appreciate your feedback on:
- **Usability:** Was anything confusing? Did the functions work as expected?
- **Documentation:** Was the help sufficient? What was missing?
- **Features:** What would make the package more useful for your work?
- **Bugs:** Did anything break? Please share the error message and what you were trying to do.

Thank you!
