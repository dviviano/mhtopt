# Changelog

All notable changes to **mhtopt** (Stata, R, Python ports) are recorded here. Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/); this project follows [Semantic Versioning](https://semver.org/).

Per-language conventions: the R port also maintains `r/mhtopt/NEWS.md` (CRAN-readable); the entries here are the source of truth.

## [Unreleased]

## [1.0.0] — 2026-06-08

First public release. Implements the economically optimal multiple-hypothesis-testing correction of Viviano, Wüthrich, and Niehaus (2026), <arXiv:2104.13367>, with numerically aligned Stata, R, and Python ports.

### Added
- **Five commands/functions** in each port: `mht_critical`, `mht_test`, `mht_est`, `mht_cost_estimate`, `mht_table`.
- Two cost models: Linear (FDA calibration, `cf_share=0.46`, `J_bar=3`) and Cobb-Douglas (J-PAL calibration, `beta=0.13`, `iota=0.075`).
- **Stata**: `.ado` + `.sthlp` for all five commands; 50-test unit suite (`stata/test/`); SSC submission bundle.
- **R**: CRAN-ready package with vignette (`r/mhtopt/`), `testthat` tests, and `.Rd` help.
- **Python**: `mhtopt` package (`numpy`/`scipy`), `pytest` tests.
- **Real-data validation** (`testing/`) against Banerjee et al. (2015, *Science*): one outcome × J=6 country arms, Table 4 cost calibration (cf=0.23), and BH-divergence sensitivity. Data is not bundled — download from Harvard Dataverse DOI 10.7910/DVN/NHIXNT (see `testing/README.md`).

[Unreleased]: https://github.com/dviviano/mhtopt/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/dviviano/mhtopt/releases/tag/v1.0.0
