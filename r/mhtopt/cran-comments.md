## Submission type

This is a new submission. mhtopt 1.0.0 is the first release of this package
to CRAN.

## Test environments

* Local Windows 10, R 4.3.3
* win-builder (devel and release) — _to be run at submission time_
* macOS-latest (R release) via GitHub Actions — _to be run at submission time_
* Ubuntu-latest (R release, devel, oldrel-1) via GitHub Actions — _to be run at submission time_

## R CMD check results

On a clean check the only finding is:

* checking CRAN incoming feasibility ... NOTE
  Maintainer: 'Erick Rosas Lopez <erosasl@ucsd.edu>'
  New submission

The "New submission" NOTE is expected for a first-time submission.

The following additional findings appear only in the local Windows check
environment and do not occur on CRAN's build servers, so they are noted here
for transparency:

* WARNING: "'qpdf' is needed for checks on size reduction of PDFs" —
  qpdf is not installed locally; it is present on CRAN's servers.
* NOTE: "unable to verify current time" — the local clock could not reach a
  network time service during the check.
* NOTE: HTML manual validation skipped ("no command 'tidy' found") — tidy is
  not installed locally.

The package's URL and BugReports point to https://github.com/dviviano/mhtopt,
which is public at submission time, so the incoming-feasibility URL check
resolves with status 200.

## Downstream dependencies

There are currently no downstream dependencies for this package.
