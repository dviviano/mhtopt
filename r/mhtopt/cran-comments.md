## Resubmission

This is a resubmission of mhtopt 1.0.0 (a new package). Thank you for the
review. In response to the comments received on 2026-07-17, I have made the
following changes:

* **All acronyms are now explained in the Description text.** "FDA" is written
  as "United States Food and Drug Administration (FDA)", "J-PAL" as "Abdul
  Latif Jameel Poverty Action Lab (J-PAL)", and "BH" as
  "Benjamini-Hochberg (BH)".

* **No example code is commented out any more.** The previously commented-out
  'estimatr' and 'fixest' examples in `?mht_est` are now real, executable code,
  wrapped in `if (requireNamespace("<pkg>", quietly = TRUE)) { ... }` so that
  they are run whenever the suggested package is available. All examples
  execute in well under 5 seconds, so `\donttest{}` was not needed. No other
  help page contains commented-out example code.

## Test environments

* win-builder, R-devel (win-builder.r-project.org)
* CRAN incoming pretest: r-devel-windows-x86_64 and
  r-devel-linux-x86_64-debian-gcc (both Status: 1 NOTE)
* Local Windows 10, R 4.3.3

## R CMD check results

0 errors | 0 warnings | 1 note

* checking CRAN incoming feasibility ... NOTE
  Maintainer: 'Erick Rosas Lopez <erosaslpez@ucsd.edu>'
  New submission
  Possibly misspelled words in DESCRIPTION

  - "New submission" is expected for a first-time submission.
  - The words flagged as possibly misspelled are all spelled correctly. They
    are proper nouns -- the author surnames of the cited paper (Viviano,
    Wuthrich, Niehaus), and the institutions now named in full per your
    request (United States Food and Drug Administration / FDA; Abdul Latif
    Jameel Poverty Action Lab / J-PAL) -- together with standard statistical
    terms (Bonferroni, Holm, Benjamini-Hochberg / BH, Cobb-Douglas).

The arXiv reference in the Description field is given in the arXiv DOI form
<doi:10.48550/arXiv.2104.13367>. The package URL/BugReports point to the public
repository https://github.com/dviviano/mhtopt.

(The local Windows check additionally reports a qpdf WARNING and "unable to
verify current time" / missing-'tidy' NOTEs; these are local-environment
artifacts and do not appear on win-builder or CRAN's servers.)

## Downstream dependencies

There are currently no downstream dependencies for this package.
