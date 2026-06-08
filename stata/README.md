# mhtopt (Stata)

**Optimal Multiple Hypothesis Testing Corrections — Stata port**

Stata implementation of the optimal MHT correction from:

> Viviano, D., Wüthrich, K., and Niehaus, P. (2026). *A Model of Multiple Hypothesis Testing.* arXiv:[2104.13367](https://arxiv.org/abs/2104.13367).

Standard MHT corrections (Bonferroni, Holm, BH) are ad hoc. `mhtopt` derives the optimal per-test significance level α\* from the economic incentives of research production. The result sits between Bonferroni (too conservative) and unadjusted (too permissive), with the exact position determined by the study's cost structure.

Two cost models, both calibrated to real data:

- **Linear** (default): fixed-cost share 0.46 (Sertkaya et al. 2016)
- **Cobb-Douglas** (J-PAL, Table 2 of paper): β = 0.13, ι = 0.075

## Installation

```stata
ssc install mhtopt
```

Requires Stata 14 or later. No SSC dependencies.

Development install (latest unreleased version from GitHub):

```stata
net install mhtopt, from("https://raw.githubusercontent.com/dviviano/mhtopt/main/stata/")
```

## Quick start

```stata
* Optimal critical value for 5 hypotheses
mht_critical, jhypotheses(5) alphabar(0.05)

* Apply MHT adjustment to a variable of p-values
mht_test pval_variable, alphabar(0.05)

* Postestimation: test J treatment coefficients
regress y treat1 treat2 treat3 controls, cluster(cluster_id)
mht_est, vars(treat1 treat2 treat3) alphabar(0.05)
```

A full self-contained example (uses `sysuse auto` and simulated data — no external files):

```stata
do "examples/mht_example.do"
```

## Five commands

| Command | Purpose |
|---|---|
| `mht_critical` | Compute optimal critical value α\* |
| `mht_test` | Apply MHT adjustment to a variable of p-values |
| `mht_est` | Postestimation: test J coefficients from any Stata regression |
| `mht_cost_estimate` | Estimate cost-function parameters (β, ι) from project-level data |
| `mht_table` | Generate reference tables (reproduces Tables 1 & 3 of the paper) |

Each command reports optimal, Bonferroni, Holm, BH, and unadjusted results side by side. Per-command help: `help mht_critical`, `help mht_est`, etc.

## Worked example with real data

A walkthrough applying the package to Banerjee et al. (2015, *Science*) — a
6-country graduation-program RCT, framed as one outcome tested across J=6
country-specific treatment arms — is in this folder's `testing/` and the repo's
top-level [`testing/`](../testing/). Run the Stata testdrive (from the repo root):

```stata
do "stata/testing/test_mht_stata_testdrive.do"
```

The full analysis — reproducing `testing/full_analysis_case/results_note.pdf` —
lives in the repo's **top-level** `testing/full_analysis_case/`:

| Part | Script | Pre-generated log |
|---|---|---|
| 2. One outcome × 6 country arms (J=6) | `analysis_part2_treatments.do` | `part2_treatments_log.txt` |
| 3. Cost calibration from Table 4 (cf=0.23) | `analysis_part3_calibration.do` | `part3_calibration_log.txt` |
| 4. Sensitivity to fixed-cost share | `analysis_part4_gradient.do` | `part4_gradient_log.txt` |

Run all three with `do "testing/full_analysis_case/run_all.do"`. The Banerjee data
is **not** bundled — see [`testing/README.md`](../testing/README.md) for the
one-time Harvard Dataverse download (DOI 10.7910/DVN/NHIXNT).

## Documentation

- Per-command: `help mht_critical`, `help mht_test`, etc.
- Full reference: [`docs/documentation_stata.pdf`](docs/documentation_stata.pdf)
- Paper: [arXiv:2104.13367](https://arxiv.org/abs/2104.13367)

## Citation

A formatted reference appears in `help mht_critical` (References section) and at the bottom of every `.sthlp` file.

## Other language ports

The same five commands are available in R (`install.packages("mhtopt")`) and Python (`pip install mhtopt`). See the [project repository](https://github.com/dviviano/mhtopt) for cross-language documentation.

## Reporting bugs

Open a [GitHub issue](https://github.com/dviviano/mhtopt/issues) and include the output of `which mht_critical` (package version) and `version` (Stata version).

## License

MIT — see [LICENSE](../LICENSE).
