{smcl}
{* version 1.0.0  2026-03-15}{...}
{viewerjumpmarks Top Options Results References}{...}
{title:mht_table}

{pstd}
{bf:mht_table} — Display table of optimal MHT test sizes

{title:Syntax}

{p 8 16 2}
{cmd:mht_table} [{cmd:,} {it:options}]

{synoptset 24 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt alpha:bar(#)}}benchmark single-hypothesis significance level; default 0.05{p_end}
{synopt:{opt jr:ange(numlist)}}J values for table rows; default 1 2 3 4 5 6 7 8 9{p_end}
{synopt:{opt nmr:atios(numlist)}}n/m ratio values for columns; default 0.5 1.0 1.5 2.0{p_end}
{synopt:{opt mo:del(string)}}{cmd:linear} (default) or {cmd:cobbdouglas}{p_end}
{synopt:{opt cfs:hare(#)}}fixed cost share, Linear model; default 0.46{p_end}
{synopt:{opt jb:ar(#)}}average number of subgroups, Linear model; default 3{p_end}
{synopt:{opt beta(#)}}arms elasticity, Cobb-Douglas; default 0.13{p_end}
{synopt:{opt iota(#)}}size elasticity, Cobb-Douglas; default 0.075{p_end}
{synoptline}

{title:Description}

{pstd}
{cmd:mht_table} displays a grid of optimal test sizes alpha*(J, n/m) as defined
in Proposition 4.1 of Viviano, Wuthrich, and Niehaus (2026), varying the number
of hypotheses J (rows) and the sample-size ratio n/m (columns).  This reproduces
the layout of Tables 1 and 3 in the paper.

{pstd}
For each cell, the command calls {helpb mht_critical} internally and collects the
result.  The displayed table and all cell values are also stored in r().

{title:Options}

{phang}
{opt alphabar(#)} sets the benchmark single-hypothesis significance level.
Must be in (0,1).  Default is 0.05.

{phang}
{opt jrange(numlist)} specifies the J values used as table rows.
Default is {cmd:1 2 3 4 5 6 7 8 9}.

{phang}
{opt nmratios(numlist)} specifies the n/m ratios used as table columns.
Default is {cmd:0.5 1.0 1.5 2.0}.

{phang}
{opt model(string)} selects the cost model.  {cmd:linear} (default) uses the Linear
linear cost structure (Equation 26); {cmd:cobbdouglas} uses the Cobb-Douglas
structure (Equation 28) calibrated on J-PAL data.

{phang}
{opt cfshare(#)}, {opt jbar(#)} control the Linear model.
Defaults 0.46 and 3 replicate the paper's Table 1.

{phang}
{opt beta(#)}, {opt iota(#)} control the Cobb-Douglas model.
Defaults 0.13 and 0.075 replicate the paper's Table 3.

{title:Examples}

{pstd}Reproduce Table 1 from the paper (Linear model, alpha_bar=0.05):

{phang2}{cmd:. mht_table}

{pstd}Custom J range with Cobb-Douglas model:

{phang2}{cmd:. mht_table, model(cobbdouglas) jrange(1 3 5 9) nmratios(0.5 1.0 2.0)}

{pstd}Different benchmark alpha:

{phang2}{cmd:. mht_table, alphabar(0.10) jrange(1 2 3 4 5)}

{title:Stored results}

{pstd}
{cmd:mht_table} stores the following in {cmd:r()}:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:r(alpha_bar)}}benchmark alpha{p_end}
{synopt:{cmd:r(alpha_{it:j}_{it:nm})}}optimal alpha for J={it:j} and nm_ratio={it:nm}
(decimal point replaced by {cmd:p}; e.g. {cmd:r(alpha_3_1p0)} for J=3, nm=1.0){p_end}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Macros}{p_end}
{synopt:{cmd:r(model)}}cost model used ({cmd:linear} or {cmd:cobbdouglas}){p_end}

{title:References}

{pstd}
Viviano, D., K. Wuthrich, and P. Niehaus (2026).  A model of multiple hypothesis
testing.  {it:arXiv:2104.13367v10}.

{title:Also see}

{psee}
{helpb mht_critical}, {helpb mht_est}, {helpb mht_test}
{p_end}
