{smcl}
{* *! version 1.0.0  2026-03-15}{...}
{viewerjumpto "Syntax" "mht_cost_estimate##syntax"}{...}
{viewerjumpto "Description" "mht_cost_estimate##description"}{...}
{viewerjumpto "Options" "mht_cost_estimate##options"}{...}
{viewerjumpto "Examples" "mht_cost_estimate##examples"}{...}
{viewerjumpto "Stored results" "mht_cost_estimate##stored"}{...}
{title:Title}

{phang}
{bf:mht_cost_estimate} {hline 2} Estimate cost function parameters for MHT adjustment


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:mht_cost_estimate}
{it:costvar} {it:armsvar} {it:sizevar}
{ifin}
{cmd:,} {opt alpha:bar(#)}
[{it:options}]

{synoptset 25 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Required}
{synopt:{it:costvar}}variable containing project/trial costs{p_end}
{synopt:{it:armsvar}}variable containing number of treatment arms{p_end}
{synopt:{it:sizevar}}variable containing sample size (per arm or total){p_end}
{synopt:{opt alpha:bar(#)}}benchmark single-hypothesis test size{p_end}

{syntab:Model}
{synopt:{opt mod:el(string)}}{bf:cobbdouglas} (default) or {bf:linear_share}{p_end}

{syntab:Regression options}
{synopt:{opt con:trols(varlist)}}additional control variables{p_end}
{synopt:{opt r:obust}}use robust standard errors{p_end}
{synopt:{opt cl:uster(varname)}}cluster standard errors{p_end}

{syntab:Output}
{synopt:{opt tab:le}}display table of implied critical values{p_end}
{synoptline}


{marker description}{...}
{title:Description}

{pstd}
{cmd:mht_cost_estimate} estimates the parameters of the research cost function
from data on project costs, number of treatment arms, and sample sizes. Two
models are supported:

{pstd}
{bf:Cobb-Douglas} (default, as in Table 2 / Appendix A):
Estimates log(C) = const + beta*log(|J|) + iota*log(n) via OLS.
This is the approach used in the J-PAL application.

{pstd}
{bf:Linear} ({opt model(linear_share)}):
Estimates C = c_f + c_v * |J| * n via OLS to decompose fixed and variable costs,
as in the linear calibration of Section 6.1.

{pstd}
The command also tests whether beta = 0 (Bonferroni appropriate),
beta = 1 (no adjustment needed), iota = 0, and iota = 1.


{marker examples}{...}
{title:Examples}

{pstd}Cobb-Douglas estimation with simulated data:{p_end}
{phang2}{cmd:. clear}{p_end}
{phang2}{cmd:. set obs 200}{p_end}
{phang2}{cmd:. gen arms = ceil(runiform() * 5)}{p_end}
{phang2}{cmd:. gen sample_size = ceil(runiform() * 1000) + 100}{p_end}
{phang2}{cmd:. gen cost = exp(10 + 0.2*ln(arms) + 0.15*ln(sample_size) + rnormal(0, 0.5))}{p_end}
{phang2}{cmd:. mht_cost_estimate cost arms sample_size, alphabar(0.05) table robust}{p_end}

{pstd}With additional controls:{p_end}
{phang2}{cmd:. gen project_type = ceil(runiform() * 3)}{p_end}
{phang2}{cmd:. mht_cost_estimate cost arms sample_size, alphabar(0.05) controls(i.project_type) robust table}{p_end}


{marker stored}{...}
{title:Stored results}

{pstd}
{cmd:mht_cost_estimate} stores the following in {cmd:e()}:

{pstd}For {bf:cobbdouglas}:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:e(beta)}}estimated elasticity wrt arms{p_end}
{synopt:{cmd:e(iota)}}estimated elasticity wrt sample size{p_end}
{synopt:{cmd:e(beta_se)}}standard error of beta{p_end}
{synopt:{cmd:e(iota_se)}}standard error of iota{p_end}
{synopt:{cmd:e(p_beta0)}}p-value for H0: beta = 0{p_end}
{synopt:{cmd:e(p_beta1)}}p-value for H0: beta = 1{p_end}
{synopt:{cmd:e(p_iota0)}}p-value for H0: iota = 0{p_end}
{synopt:{cmd:e(p_iota1)}}p-value for H0: iota = 1{p_end}

{pstd}For {bf:linear_share}:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:e(c_f)}}estimated fixed cost{p_end}
{synopt:{cmd:e(c_v)}}estimated variable cost per subject{p_end}
{synopt:{cmd:e(cf_share)}}estimated fixed cost share{p_end}
{synopt:{cmd:e(mean_J)}}mean number of arms{p_end}


{marker references}{...}
{title:References}

{phang}
Viviano, D., K. Wuthrich, and P. Niehaus (2026).
A model of multiple hypothesis testing.
{it:arXiv:2104.13367v10}.
{p_end}
