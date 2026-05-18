# mhtopt — Optimal Multiple Hypothesis Testing Corrections

Implementations in **Stata**, **R**, and **Python** of the optimal MHT correction from:

> Viviano, D., Wüthrich, K., and Niehaus, P. (2026). *A Model of Multiple Hypothesis Testing.* arXiv:2104.13367v10.

Standard MHT corrections (Bonferroni, Holm, BH) are ad hoc. This package derives the optimal correction from the economic incentives of research production: how costs scale with the number of hypotheses pins down how much to adjust. The result is a per-test significance level α\* that sits between Bonferroni (too conservative) and unadjusted (too permissive), with the exact position determined by the study's cost structure.

Two cost models, both calibrated to real data:

- **Linear** (default): fixed-cost share 0.46 (Sertkaya et al. 2016).
- **Cobb-Douglas**: β = 0.13 (cost scaling in arms), ι = 0.075 (cost scaling in surveys/arm), J-PAL calibration.

## Pick your language

| You write code in… | Install with | Get help with | Subdirectory |
|---|---|---|---|
| **Stata** | `ssc install mhtopt` | `help mht_critical` | [`stata/`](stata/) |
| **R** | `install.packages("mhtopt")` | `?mht_critical` | [`r/`](r/) |
| **Python** | `pip install mhtopt` | docstrings + [docs](python/docs/) | [`python/`](python/) |

The five exposed commands/functions are identical across ports:

| Name | Purpose |
|---|---|
| `mht_critical` | Compute optimal critical value α\* |
| `mht_test` | Apply MHT adjustment to a vector of p-values |
| `mht_est` | Postestimation: test J coefficients from a fitted model |
| `mht_cost_estimate` | Estimate cost-function parameters (β, ι) from project-level data |
| `mht_table` | Generate reference tables (reproduces Tables 1 & 3 of the paper) |

## Pre-release installs (from GitHub)

```stata
* Stata
net install mhtopt, from("https://raw.githubusercontent.com/OWNER/mhtopt/main/stata/")
```

```r
# R
remotes::install_github("OWNER/mhtopt", subdir = "r")
```

```bash
# Python
pip install "git+https://github.com/OWNER/mhtopt.git#subdirectory=python"
```

> Replace `OWNER` with the GitHub owner once the repo is public. See [`DECISIONS.md`](DECISIONS.md).

## Citation

If you use this package, please cite:

```bibtex
@article{viviano2026mht,
  title  = {A Model of Multiple Hypothesis Testing},
  author = {Viviano, Davide and W\"uthrich, Kaspar and Niehaus, Paul},
  year   = {2026},
  journal = {arXiv preprint},
  eprint = {2104.13367},
  archivePrefix = {arXiv},
  primaryClass  = {econ.EM},
}
```

See [`CITATION.cff`](CITATION.cff) for machine-readable metadata.

## License

MIT — see [`LICENSE`](LICENSE).

## Reporting bugs

File a [GitHub issue](../../issues) and indicate which port (Stata / R / Python) and version. We try to keep the three ports numerically identical; a discrepancy is itself a bug worth reporting.
