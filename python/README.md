# mhtopt

**Optimal Multiple Hypothesis Testing Corrections (Python port)**

Python implementation of the optimal MHT correction from:

> Viviano, D., Wüthrich, K., and Niehaus, P. (2026). *A Model of Multiple Hypothesis Testing.* arXiv:[2104.13367](https://arxiv.org/abs/2104.13367).

Standard MHT corrections (Bonferroni, Holm, BH) are ad hoc. `mhtopt` derives the optimal per-test significance level α\* from the economic incentives of research production: how costs scale with the number of hypotheses determines how much to adjust. The result sits between Bonferroni (too conservative) and unadjusted (too permissive), with the exact position pinned down by the study's cost structure.

Two cost models, both calibrated to real data:

- **Linear** (default): fixed-cost share 0.46 (Sertkaya et al. 2016)
- **Cobb-Douglas** (J-PAL, Table 2 of paper): β = 0.13, ι = 0.075

## Installation

```bash
pip install mhtopt
```

Requires Python ≥ 3.9; depends on `numpy ≥ 1.20` and `scipy ≥ 1.7`.

Development install:

```bash
pip install "git+https://github.com/dviviano/mhtopt.git#subdirectory=python"
```

## Quick start

```python
from mhtopt import mht_critical, mht_test, mht_est, mht_cost_estimate, mht_table

# Optimal critical value for 5 hypotheses
r = mht_critical(J=5, alpha_bar=0.05)
print(f"alpha* = {r['alpha_opt']:.4f}")     # alpha* = 0.0212

# Apply MHT adjustment to a list of p-values
mht_test(p=[0.003, 0.015, 0.048], alpha_bar=0.05)

# Postestimation: test J coefficients from a fitted model
import statsmodels.api as sm
fit = sm.OLS(y, X).fit()
mht_est(fit, vars=["treat1", "treat2", "treat3"], alpha_bar=0.05)
```

A full self-contained example:

```bash
python -m mhtopt.examples  # if installed, or:
python examples/mht_example.py
```

## Five exported functions

| Function | Purpose |
|---|---|
| `mht_critical()` | Compute optimal critical value α\* |
| `mht_test()` | Apply MHT adjustment to a list of p-values |
| `mht_est()` | Postestimation: test J coefficients from a fitted model |
| `mht_cost_estimate()` | Estimate cost-function parameters (β, ι) from project-level data |
| `mht_table()` | Generate reference tables (reproduces Tables 1 & 3 of the paper) |

Each reports optimal, Bonferroni, Holm, Benjamini-Hochberg, and unadjusted results side by side.

`mht_est` supports any fitted model exposing `.params` and `.pvalues` (e.g. `statsmodels`, `linearmodels`) or a dict of regression results.

## Worked example with real data

A walkthrough applying the package to Banerjee et al. (2015, *Science*) — a 6-country graduation-program RCT with 10 outcome families — is in [`testing/`](testing/):

```bash
pip install pandas  # needed for .dta files
python testing/test_mht_testdrive.py
```

## Documentation

- Function-level: docstrings on every public function
- Full reference: [`docs/`](docs/)
- Paper: [arXiv:2104.13367](https://arxiv.org/abs/2104.13367)

## Citation

Please cite the paper — copy whichever format you prefer:

**APA**

> Viviano, D., Wüthrich, K., & Niehaus, P. (2026). *A model of multiple hypothesis testing* (arXiv:2104.13367). arXiv. https://doi.org/10.48550/arXiv.2104.13367

**BibTeX**

```bibtex
@article{viviano2026mht,
  title  = {A Model of Multiple Hypothesis Testing},
  author = {Viviano, Davide and W\"uthrich, Kaspar and Niehaus, Paul},
  year   = {2026},
  journal = {arXiv preprint},
  eprint = {2104.13367},
}
```

## Other language ports

The same five functions are available in Stata (`ssc install mhtopt`) and R (`install.packages("mhtopt")`). See the [project repository](https://github.com/dviviano/mhtopt) for cross-language documentation.

## Reporting bugs

Open a [GitHub issue](https://github.com/dviviano/mhtopt/issues) and indicate the package version (`mhtopt.__version__`) and Python version.

## License

MIT — see [LICENSE](LICENSE).
