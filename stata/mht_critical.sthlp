{smcl}
{* *! version 1.0.0  2026-03-15}{...}
{viewerjumpto "Syntax" "mht_critical##syntax"}{...}
{viewerjumpto "Description" "mht_critical##description"}{...}
{viewerjumpto "Options" "mht_critical##options"}{...}
{viewerjumpto "Examples" "mht_critical##examples"}{...}
{viewerjumpto "Stored results" "mht_critical##stored"}{...}
{viewerjumpto "References" "mht_critical##references"}{...}
{title:Title}

{phang}
{bf:mht_critical} {hline 2} Compute optimal critical values for multiple hypothesis testing


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:mht_critical}
{cmd:,} {opt j:hypotheses(#)} {opt alpha:bar(#)}
[{it:options}]

{synoptset 25 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Required}
{synopt:{opt j:hypotheses(#)}}number of hypotheses |J|{p_end}
{synopt:{opt alpha:bar(#)}}benchmark single-hypothesis test size{p_end}

{syntab:Cost model}
{synopt:{opt mod:el(string)}}cost model: {bf:linear} (default) or {bf:cobbdouglas}{p_end}

{syntab:Linear model parameters}
{synopt:{opt cfs:hare(#)}}fixed cost share; default is {bf:0.46}{p_end}
{synopt:{opt jbar(#)}}average number of subgroups; default is {bf:3}{p_end}
{synopt:{opt nmr:atio(#)}}ratio of per-arm sample size to benchmark; default is {bf:1.0}{p_end}

{syntab:Cobb-Douglas model parameters}
{synopt:{opt beta(#)}}elasticity with respect to |J|; default is {bf:0.13}{p_end}
{synopt:{opt iota(#)}}elasticity with respect to sample size; default is {bf:0.075}{p_end}
{synoptline}


{marker description}{...}
{title:Description}

{pstd}
{cmd:mht_critical} computes optimal critical values for multiple hypothesis testing
based on the model in Viviano, Wuthrich, and Niehaus (2026). The command implements
Proposition 4.1 of the paper, which shows that the optimal per-test significance level is

{pmore}
alpha(J, Sigma) = C(J, Sigma) / (b * omega_bar(J))

{pstd}
where C is the cost function, b is the per-unit benefit, and omega_bar is the sum
of treatment weights. Two cost models are supported:

{pstd}
{bf:Linear model} (Equation 26): Uses the fixed-plus-variable cost structure
C = c_f + c_v * |J| * n, calibrated using data from Sertkaya et al. (2016).

{pstd}
{bf:Cobb-Douglas model} (Equation 28): Uses C = k * |J|^beta * n^iota,
calibrated using data from J-PAL economic experiments.


{marker examples}{...}
{title:Examples}

{pstd}Basic usage with linear calibration:{p_end}
{phang2}{cmd:. mht_critical, jhypotheses(5) alphabar(0.05)}{p_end}

{pstd}With Cobb-Douglas model using J-PAL parameters:{p_end}
{phang2}{cmd:. mht_critical, jhypotheses(5) alphabar(0.05) model(cobbdouglas) beta(0.13) iota(0.075)}{p_end}

{pstd}Linear model with non-benchmark sample size:{p_end}
{phang2}{cmd:. mht_critical, jhypotheses(3) alphabar(0.025) nmratio(1.5)}{p_end}

{pstd}Loop to reproduce Table 1:{p_end}
{phang2}{cmd:. forvalues j = 1/9 {c -(}}{p_end}
{phang2}{cmd:.     mht_critical, jhypotheses(`j') alphabar(0.05) model(linear)}{p_end}
{phang2}{cmd:.     display "J=`j': alpha_opt = " r(alpha_opt)}{p_end}
{phang2}{cmd:. {c )-}}{p_end}


{marker stored}{...}
{title:Stored results}

{pstd}
{cmd:mht_critical} stores the following in {cmd:r()}:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:r(alpha_opt)}}optimal test size{p_end}
{synopt:{cmd:r(t_star)}}optimal z-threshold{p_end}
{synopt:{cmd:r(alpha_bonf)}}Bonferroni test size{p_end}
{synopt:{cmd:r(t_bonf)}}Bonferroni z-threshold{p_end}
{synopt:{cmd:r(alpha_bar)}}benchmark alpha{p_end}
{synopt:{cmd:r(J)}}number of hypotheses{p_end}
{synopt:{cmd:r(nm_ratio)}}sample size ratio{p_end}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Macros}{p_end}
{synopt:{cmd:r(model)}}cost model used{p_end}


{marker references}{...}
{title:References}

{phang}
Viviano, D., K. Wuthrich, and P. Niehaus (2026).
A model of multiple hypothesis testing.
{it:arXiv:2104.13367v10}.

{phang}
Sertkaya, A., H.-H. Wong, A. Jessup, and T. Beleche (2016).
Key cost drivers of pharmaceutical clinical trials in the United States.
{it:Clinical Trials} 13(2), 117-126.
{p_end}
