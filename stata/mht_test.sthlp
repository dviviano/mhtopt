{smcl}
{* *! version 1.0.0  2026-03-15}{...}
{viewerjumpto "Syntax" "mht_test##syntax"}{...}
{viewerjumpto "Description" "mht_test##description"}{...}
{viewerjumpto "Options" "mht_test##options"}{...}
{viewerjumpto "Examples" "mht_test##examples"}{...}
{viewerjumpto "Stored results" "mht_test##stored"}{...}
{title:Title}

{phang}
{bf:mht_test} {hline 2} Perform hypothesis tests with optimal MHT adjustment


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:mht_test}
{it:varname}
{ifin}
{cmd:,} {opt alpha:bar(#)}
[{it:options}]

{synoptset 25 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Required}
{synopt:{it:varname}}variable containing p-values (or z-statistics with {opt zstat}){p_end}
{synopt:{opt alpha:bar(#)}}benchmark single-hypothesis test size{p_end}

{syntab:Input}
{synopt:{opt zstat}}input variable contains z-statistics rather than p-values{p_end}

{syntab:Cost model}
{synopt:{opt mod:el(string)}}{bf:linear} (default) or {bf:cobbdouglas}{p_end}
{synopt:{opt cfs:hare(#)}}fixed cost share (Linear); default {bf:0.46}{p_end}
{synopt:{opt jbar(#)}}average subgroups (Linear); default {bf:3}{p_end}
{synopt:{opt nmr:atio(#)}}sample size ratio; default {bf:1.0}{p_end}
{synopt:{opt beta(#)}}arms elasticity (Cobb-Douglas); default {bf:0.13}{p_end}
{synopt:{opt iota(#)}}sample elasticity (Cobb-Douglas); default {bf:0.075}{p_end}

{syntab:Output}
{synopt:{opt gen:erate(string)}}prefix for generated variables; default {bf:mht}{p_end}
{synopt:{opt replace}}replace existing generated variables{p_end}
{synoptline}


{marker description}{...}
{title:Description}

{pstd}
{cmd:mht_test} applies the optimal MHT adjustment from Viviano, Wuthrich, and
Niehaus (2026) to a set of hypothesis tests. Given a variable containing p-values
(one-sided) or z-statistics, it computes rejection decisions under:

{phang2}1. The {bf:optimal model-based} procedure (Proposition 4.1){p_end}
{phang2}2. {bf:Bonferroni} correction{p_end}
{phang2}3. {bf:Holm} step-down procedure{p_end}
{phang2}4. {bf:Benjamini-Hochberg} (FDR control){p_end}
{phang2}5. {bf:Unadjusted} testing{p_end}

{pstd}
The number of hypotheses |J| is determined automatically from the number of
observations in the sample.


{marker examples}{...}
{title:Examples}

{pstd}Setup: Create example p-values{p_end}
{phang2}{cmd:. clear}{p_end}
{phang2}{cmd:. set obs 6}{p_end}
{phang2}{cmd:. gen pval = .}{p_end}
{phang2}{cmd:. replace pval = 0.003 in 1}{p_end}
{phang2}{cmd:. replace pval = 0.015 in 2}{p_end}
{phang2}{cmd:. replace pval = 0.030 in 3}{p_end}
{phang2}{cmd:. replace pval = 0.048 in 4}{p_end}
{phang2}{cmd:. replace pval = 0.120 in 5}{p_end}
{phang2}{cmd:. replace pval = 0.500 in 6}{p_end}

{pstd}Apply MHT adjustment with linear calibration:{p_end}
{phang2}{cmd:. mht_test pval, alphabar(0.05)}{p_end}

{pstd}View results:{p_end}
{phang2}{cmd:. list pval mht_reject_opt mht_reject_bonf mht_reject_bh mht_reject_unadj}{p_end}

{pstd}With z-statistics instead:{p_end}
{phang2}{cmd:. gen zstat = invnormal(1 - pval)}{p_end}
{phang2}{cmd:. mht_test zstat, alphabar(0.05) zstat generate(z) replace}{p_end}


{marker stored}{...}
{title:Stored results}

{pstd}
{cmd:mht_test} stores the following in {cmd:r()}:

{synoptset 25 tabbed}{...}
{p2col 5 25 29 2: Scalars}{p_end}
{synopt:{cmd:r(alpha_opt)}}optimal test size{p_end}
{synopt:{cmd:r(alpha_bonf)}}Bonferroni test size{p_end}
{synopt:{cmd:r(alpha_bar)}}benchmark alpha{p_end}
{synopt:{cmd:r(J)}}number of hypotheses{p_end}
{synopt:{cmd:r(n_reject_opt)}}rejections (optimal){p_end}
{synopt:{cmd:r(n_reject_bonf)}}rejections (Bonferroni){p_end}
{synopt:{cmd:r(n_reject_holm)}}rejections (Holm){p_end}
{synopt:{cmd:r(n_reject_bh)}}rejections (BH){p_end}
{synopt:{cmd:r(n_reject_unadj)}}rejections (unadjusted){p_end}

{pstd}
{cmd:mht_test} also creates the following variables (with prefix {it:generate}):

{phang2}{it:prefix}_reject_opt - Optimal model-based rejection{p_end}
{phang2}{it:prefix}_reject_bonf - Bonferroni rejection{p_end}
{phang2}{it:prefix}_reject_holm - Holm rejection{p_end}
{phang2}{it:prefix}_reject_bh - BH/FDR rejection{p_end}
{phang2}{it:prefix}_reject_unadj - Unadjusted rejection{p_end}
{phang2}{it:prefix}_alpha_opt - Optimal test size{p_end}


{marker references}{...}
{title:References}

{phang}
Viviano, D., K. Wuthrich, and P. Niehaus (2026).
A model of multiple hypothesis testing.
{it:arXiv:2104.13367v10}.
{p_end}
