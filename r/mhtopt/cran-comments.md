## Submission type

This is a new submission. mhtopt 1.0.0 is the first release of this package
to CRAN.

## Test environments

* win-builder, R-devel (win-builder.r-project.org) — Status: 1 NOTE
* Local Windows 10, R 4.3.3

## R CMD check results

win-builder (R-devel) returns **1 NOTE**:

* checking CRAN incoming feasibility ... NOTE
  Maintainer: 'Erick Rosas Lopez <erosaslpez@ucsd.edu>'
  New submission
  Possibly misspelled words in DESCRIPTION:
    BH, Bonferroni, Holm, Niehaus, Viviano, Wuthrich

  - "New submission" is expected for a first-time submission.
  - The flagged words are all spelled correctly: Viviano, Wuthrich (Wuethrich),
    and Niehaus are the author surnames of the cited paper; BH (for
    Benjamini-Hochberg), Bonferroni, and Holm are standard names of
    multiple-testing procedures.

The arXiv reference in the Description field is given in the arXiv DOI form
<doi:10.48550/arXiv.2104.13367>. The package URL/BugReports point to the public
repository https://github.com/dviviano/mhtopt.

(The local Windows check additionally reports a qpdf WARNING and "unable to
verify current time" / missing-'tidy' NOTEs; these are local-environment
artifacts and do not appear on win-builder or CRAN's servers.)

## Downstream dependencies

There are currently no downstream dependencies for this package.
