# Real-data validation — Banerjee et al. (2015)

This folder validates `mhtopt` against a published six-country RCT and shows what
the economically optimal MHT correction changes in practice. It is **developer/
reviewer material — it is not shipped in the installable Stata, R, or Python
packages** (those build only from `stata/`, `r/`, and `python/`).

> Banerjee, A., E. Duflo, N. Goldberg, D. Karlan, R. Osei, W. Parienté, J. Shapiro,
> B. Thuysbaert, and C. Udry (2015). "A Multifaceted Program Causes Lasting Progress
> for the Very Poor: Evidence from Six Countries." *Science* 348(6236), 1260799.
> DOI: [10.1126/science.1260799](https://doi.org/10.1126/science.1260799)

## The data is NOT included — download it from Dataverse

The replication data is redistributed under the authors' Harvard Dataverse record,
**not** in this repository (it is ~55 MB and carries its own terms):

- **Dataverse DOI:** [`10.7910/DVN/NHIXNT`](https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/NHIXNT)

> ⚠️ **Guestbook gate:** Harvard Dataverse requires you to fill out a short
> guestbook (name / email / purpose) before downloading. The files therefore
> cannot be fetched by a plain `wget`/`curl`; download them through the website.

### Steps

1. Open the Dataverse record above and download **`data_modified.zip`**
   (15,359,382 bytes). *(Downloading the whole `dataverse_files.zip` bundle also
   works — `data_modified.zip` is inside it.)*
2. Extract it. You will get a `data_modified/` folder.
3. Copy these **four** files into [`testing/data/`](data/) (next to this README):

   | File | Used by | Size |
   |---|---|---|
   | `pooled_hh.dta` | `full_analysis_case/` | 9.5 MB |
   | `pooled_mb.dta` | `full_analysis_case/` | 15.9 MB |
   | `index_hh_vars.dta` | `test_mht_stata_testdrive.do` | 11 MB |
   | `index_mb_vars.dta` | `test_mht_stata_testdrive.do` | 16.9 MB |

   The `full_analysis_case/` scripts build their indices internally and need only
   the two `pooled_*` files; the testdrive uses the two pre-built `index_*` files.

### Integrity (SHA-256)

The files we validated against (from `data_modified.zip` at the DOI above):

```
pooled_hh.dta      b687fed13933a76e3eb259e9e83cbf1ab6138a431d503ccf455b7bba7af6e6b8
pooled_mb.dta      120acd88609187d61526d04d15820b0a07a0aa3670b163267279fbdc98e4ccd9
index_hh_vars.dta  d2d99d0a647d45ed14660e4e5fc4e6f2273e4e5c801fa59678d45a2053ebcc29
index_mb_vars.dta  3587e5d7dea2b877678ba5decea30ed7a11bbc04ead244060a51635f5b855735
```

## Run it

From the repository root (the folder containing `stata/`, `r/`, `python/`):

```stata
cd "path/to/mhtopt"
do "testing/full_analysis_case/run_all.do"
```

This runs the three parts and writes clean logs alongside the scripts:

| Part | What | Log |
|---|---|---|
| 2 | One outcome × 6 country arms (J=6) | `part2_treatments_log.txt` |
| 3 | Cost calibration from Table 4 (cf=0.23) | `part3_calibration_log.txt` |
| 4 | Sensitivity to fixed-cost share (BH divergence) | `part4_gradient_log.txt` |

The note these results back is
[`full_analysis_case/results_note.pdf`](full_analysis_case/results_note.pdf).

### Spot checks (so you know it reproduced)

| Quantity | Expected |
|---|---|
| VWN threshold, J=6 (Cobb-Douglas / Linear, one-sided) | 0.010519 / 0.020052 |
| Calibrated Linear threshold (cf=0.23, J_bar=6, one-sided) | 0.023256 (≈ 0.047 two-sided) |
| Part 2 country-arm counts (Consumption EL1, Naive/BH/CD/Lin) | 4 / 4 / 3 / 4 |
| Part 4 BH divergence at cf=0.23 (cells where L≠BH, out of 20) | 2 (Physical health EL2, Income EL2) |

> The two per-language testdrives (`stata/testing/`, `r/testing/`, `python/testing/`)
> are lighter showcases of the same J=6 country-arms framing.

## Reproducing the derived files from scratch (optional)

`index_hh_vars.dta` / `index_mb_vars.dta` are **already** in `data_modified.zip`,
so you do not need to build them. They are produced by the authors' own
`3_index_analysis_tables_3&S4.do` (run after `1_set_globals.do` and
`2_preanalysis.do`) from the raw `data_original.zip` files. See
`full_analysis_case/` script headers and the authors' `1 - Readme - main.docx`
in the Dataverse bundle for the full pipeline.
