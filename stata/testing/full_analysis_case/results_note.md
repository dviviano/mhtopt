# MHT Testing v2: Banerjee et al. (2015) Exercises

**Date:** March 24, 2026
**Package:** Viviano, Wuthrich & Niehaus (2026), Stata implementation
**Data:** Banerjee et al. (2015) "A multifaceted program causes lasting progress for the very poor" (Science)

---

## Regression Specification

Both exercises use the same regression as the paper's Equation 1:

```
areg Y_it  [treatment vars]  Y_bsl  m_Y_bsl  m_country_Y_bsl  control_*  [css_*],
     absorb(geo_cluster) cluster(rand_unit)
```

- **Dependent variable:** standardized outcome index (z-scored within country to control group)
- **Baseline controls:** lagged outcome, missing-baseline dummies, country-specific controls
- **Short-survey controls** (`css_*`): included for consumption, income, financial inclusion at EL1, and mental health at EL1
- **Fixed effects:** `geo_cluster` (village/cluster level, absorbs country FEs)
- **Standard errors:** clustered at `rand_unit` (unit of randomization)

Exercise 1 uses a single `treatment` dummy. Exercise 2 replaces it with 6 country-specific treatment dummies (`treat_c = treatment * I(country==c)`). Everything else is identical.

### Verification

Part 1 results verified against the paper's stored `pooled_family_matrix.dta` (Table 3) and `country_family_matrix.dta` (Tables S4a-f):
- Max coefficient difference: < 1e-7
- Max p-value difference: < 1e-7

---

## Exercise 1: One Treatment x Multiple Outcomes (J=10)

**Setup:** For each country (and pooled), test a single treatment indicator against J=10 outcome family indices.

**Code:** `v2/code/analysis_part1_outcomes.do`
**Log:** `v2/output/part1_analysis.log`

### VWN Optimal thresholds (one-sided, alpha_bar=0.05)

| J  | Cobb-Douglas | Linear/FDA | Two-sided equiv (CD) | Two-sided equiv (Lin) |
|----|-------------|------------|---------------------|-----------------------|
| 10 | 0.006745    | 0.017656   | 0.0135              | 0.0353                |
| 9  | 0.007392    | 0.018056   | 0.0148              | 0.0361                |

### Summary: Significant outcomes out of J (10% level)

| Group    | EL1 J | Naive | FDR | VWN-CD | VWN-Lin | EL2 J | Naive | FDR | VWN-CD | VWN-Lin |
|----------|-------|-------|-----|--------|---------|-------|-------|-----|--------|---------|
| Pooled   | 10    | 10    | 10  | 8      | 8       | 10    | 8     | 8   | 8      | 8       |
| Ethiopia | 10    | 6     | 6   | 5      | 6       | 10    | 7     | 7   | 6      | 7       |
| Ghana    | 10    | 7     | 7   | 5      | 6       | 10    | 6     | 4   | 4      | 4       |
| Honduras | 10    | 6     | 5   | 5      | 5       | 10    | 4     | 2   | 1      | 2       |
| India    | 10    | 7     | 6   | 5      | 6       | 9     | 7     | 7   | 7      | 7       |
| Pakistan | 9     | 6     | 6   | 4      | 5       | 10    | 4     | 2   | 2      | 2       |
| Peru     | 10    | 3     | 2   | 1      | 2       | 10    | 4     | 1   | 1      | 2       |

Naive = two-sided p < 0.10. FDR = BH q < 0.10 (two-sided). VWN-CD/Lin = optimal threshold at alpha_bar = 0.05 one-sided.

**Key findings:**
- Pooled EL1: all 10 outcomes significant at 10% and under FDR; VWN knocks out 2 (physical health, women's empowerment)
- Pooled EL2: 8/10 significant under all methods (physical health and women's empowerment drop out at the naive level already)
- Country-level: Peru is weakest (only 3 naive at EL1); Honduras weakest at EL2
- VWN-CD is always weakly more conservative than VWN-Lin
- In Exercise 1, VWN never rejects more than FDR for any group or round

---

## Exercise 2: One Outcome x Multiple Treatments (J=6)

**Setup:** For each outcome family, run a single pooled regression with 6 country-specific treatment dummies, then apply MHT with J=6 across the country arms.

**Code:** `v2/code/analysis_part2_treatments.do`
**Log:** `v2/output/part2_analysis.log`

### VWN Optimal thresholds (one-sided, alpha_bar=0.05)

| J | Cobb-Douglas | Linear/FDA | Two-sided equiv (CD) | Two-sided equiv (Lin) |
|---|-------------|------------|---------------------|-----------------------|
| 6 | 0.010519    | 0.020052   | 0.0210              | 0.0401                |
| 5 | 0.012369    | 0.021988   | 0.0247              | 0.0440                |

### Summary: Significant countries out of J (10% level)

| Outcome       | EL1 J | Naive | BH | VWN-CD | VWN-Lin | EL2 J | Naive | BH | VWN-CD | VWN-Lin |
|---------------|-------|-------|----|--------|---------|-------|-------|----|--------|---------|
| Consumption   | 6     | 4     | 4  | 3      | 4       | 6     | 5     | 3  | 3      | 3       |
| Income        | 6     | 5     | 5  | 5      | 5       | 6     | 6     | 6  | 4      | 4       |
| Assets        | 6     | 5     | 5  | 5      | 5       | 6     | 5     | 4  | 4      | 4       |
| FoodSecurity  | 6     | 4     | 4  | 2      | 4       | 6     | 4     | 2  | 2      | 2       |
| FinInclusion  | 6     | 4     | 3  | 3      | 3       | 6     | 3     | 3  | 3      | 3       |
| TimeUse       | 6     | 3     | 3  | 3      | 3       | 6     | 2     | 2  | 2      | 2       |
| PhysHealth    | 6     | 5     | 3  | 1      | 2       | 6     | 1     | 0  | 0      | **1**   |
| MentalHealth  | 5     | 2     | 2  | 2      | 2       | 6     | 2     | 2  | 2      | 2       |
| PolInvolve    | 6     | 2     | 2  | 2      | 2       | 6     | 4     | 3  | 2      | 3       |
| WomensEmp     | 6     | 1     | 1  | 1      | 1       | 5     | 0     | 0  | 0      | 0       |

Naive = two-sided p < 0.10. BH = BH/FDR (one-sided, alpha_bar=0.05). VWN-CD/Lin = optimal threshold at alpha_bar = 0.05 one-sided.

**Key findings:**
- Income and Assets are the most robust: 5/6 countries significant at EL1 under all methods
- Physical Health is the most sensitive to corrections: EL1 drops from 5 (naive) to 1 (CD)
- Women's Empowerment: only Pakistan significant at EL1; zero countries at EL2
- MentalHealth EL1 has J=5 (Pakistan not collected); WomensEmp EL2 has J=5 (India not collected)
- J=6 yields less severe corrections than J=10: CD threshold is 0.0105 vs 0.0067

### VWN can reject more than BH

**PhysHealth EL2** is a case where VWN-Lin rejects 1 country but BH rejects 0. The detail:

| Country  | Coeff  | (SE)   | p(2s)  | Naive | BH | CD | Lin |
|----------|--------|--------|--------|-------|----|----|-----|
| Ethiopia | 0.0393 | 0.0506 | 0.4382 | .     | .  | .  | .   |
| Ghana    | -0.0136| 0.0547 | 0.8036 | .     | .  | .  | .   |
| Honduras | 0.0349 | 0.0399 | 0.3820 | .     | .  | .  | .   |
| India    | -0.0047| 0.0501 | 0.9256 | .     | .  | .  | .   |
| Pakistan | -0.0023| 0.0471 | 0.9608 | .     | .  | .  | .   |
| Peru     | 0.1007 | 0.0471 | 0.0325 | *     | .  | .  | *   |

Peru has a one-sided p-value of 0.0162. The VWN-Lin threshold for J=6 is 0.0201, so it rejects. But BH's step-up procedure fails: with only 1 out of 6 p-values below the naive level, the largest k satisfying p_(k) <= k * alpha / J is k=0, so BH rejects nothing.

This illustrates the paper's point: BH controls FDR via a step-up rule that becomes conservative when few hypotheses are significant. VWN applies a single cost-calibrated threshold to each test independently. When the cost structure justifies a relatively generous threshold (as Linear/FDA does for J=6), VWN can reject hypotheses that BH cannot.

Other cases where VWN-Lin matches but does not exceed BH:
- **FoodSecurity EL1:** BH=4, VWN-Lin=4 (tied), VWN-CD=2
- **Consumption EL1:** BH=4, VWN-Lin=4 (tied), VWN-CD=3

---

## Comparison: Exercise 1 vs Exercise 2

| Feature | Exercise 1 | Exercise 2 |
|---------|-----------|-----------|
| What varies | Outcomes (J=10) | Treatment arms / countries (J=6) |
| Treatment | Single `treatment` dummy | 6 country-specific `treat_c` dummies |
| Sample | By country or pooled | Always pooled |
| J | 10 (or 9) | 6 (or 5) |
| CD threshold | 0.0067 | 0.0105 |
| Lin threshold | 0.0177 | 0.0201 |
| VWN > BH? | No | Yes (PhysHealth EL2) |

---

## Exercise 3: Cost Calibration from Banerjee et al. Table 4, Panel A

**Setup:** Use the actual program cost data from Banerjee et al. (2015) Table 4 Panel A (and Table S7 in the supplement) to calibrate the linear cost model for Exercise 2, and compare with BH.

**Code:** `v2/code/analysis_part3_calibration.do`
**Log:** `v2/output/part3_calibration.log`

### Cost data (Table 4 Panel A / Table S7)

All costs are **per participant who received treatment** (compliers, not ITT-assigned), in 2014 USD PPP (Table 4) and USD exchange rates (Table S7). See Table S7 notes: for India, compliance was 51.5%; other countries likely ~90–95%.

| Country  | Cost/pp (PPP) | Transfer/pp | Supervision/pp | Indirect+Startup/pp |
|----------|---------------|-------------|----------------|---------------------|
| Ethiopia | $3,591        | $1,228      | $1,900         | $464                |
| Ghana    | $4,672        | $680        | $2,832         | $1,159              |
| Honduras | $2,670        | $724        | $1,633         | $313                |
| India    | $1,257        | $700        | $407           | $150                |
| Pakistan | $5,150        | $2,048      | — (not broken down) | $470           |
| Peru     | $4,960        | $1,095      | $3,357         | $508                |

Average across 6 countries: ~$3,717/pp (PPP). Total estimated program cost: ~$13–15M across all arms (approximate; exact total depends on compliance rates by country, which are not fully reported).

### Cost classification: fixed vs. variable with J

The VWN correction depends on how total cost C scales with the number of arms J. We classify each Table 4 line item by asking: *if the study had run in 3 countries instead of 6, would this cost item be cut roughly in half?*

**Variable with J** (scales with number of country arms; ~66% of average total cost):

| Cost category      | Avg/pp (PPP) | % of total | Reasoning                                      |
|--------------------|-------------|------------|------------------------------------------------|
| Staff salaries     | ~$1,185     | 32%        | Each country hires its own implementation staff |
| Asset cost         | ~$760       | 20%        | Purchased and given to each participant         |
| Food stipend       | ~$305       | 8%         | Consumption support paid per participant         |
| Travel costs       | ~$150       | 4%         | Field visits to participants within each arm    |
| Materials          | ~$65        | 2%         | Country-specific program materials              |

**Per-arm fixed** (one-time cost per country, divided by n in Table 4; ~8% of total):

| Cost category      | Avg/pp (PPP) | % of total | Reasoning                                      |
|--------------------|-------------|------------|------------------------------------------------|
| Training           | ~$230       | 6%         | Training local staff is done once per country   |
| Start-up expenses  | ~$75        | 2%         | One-time setup per country arm                  |

These are variable with J (adding a country means another round of training/setup) but fixed with respect to n within an arm.

**Ambiguous** (~23% of total):

| Cost category      | Avg/pp (PPP) | % of total | Reasoning                                      |
|--------------------|-------------|------------|------------------------------------------------|
| Indirect costs     | ~$450       | 12%        | Organizational overhead; partly shared, partly per-arm |
| Other supervision  | ~$400       | 11%        | Mix of per-arm overhead and per-participant     |

Likely mostly per-arm, since each country has its own implementing organization.

**Fixed with J** (invariant to number of arms):

| Cost category           | In Table 4? | Reasoning                                      |
|-------------------------|-------------|------------------------------------------------|
| Study-wide coordination | **No**      | J-PAL multi-site coordination, protocol design, centralized data management, publication |

Averages are in PPP, excluding Pakistan for supervision sub-items (breakdown not reported). Percentages are approximate shares of the 6-country average total cost ($3,717/pp PPP).

**Bottom line:** Every line item in Table 4 is either clearly variable with J (staff, assets, food, travel, materials — ~66% of cost) or per-arm fixed (training, start-up — ~8%, still scales with J). The ambiguous items (indirect, other supervision — ~23%) are likely mostly per-arm. The only genuinely J-fixed cost — study-wide coordination — is unobserved and almost certainly a small share of total program spending.

### What was calibrated and how

The VWN linear cost model is C = c_f + c_v · |J| · n̄, where cf_share = c_f / C̄ determines the correction. The calibration exercise asks: **what is cf_share for Banerjee et al.?**

**What the data tells us:** Table 4 reports exclusively per-participant implementation costs, separately by country. Every dollar in these tables is paid per treated person and scales with the number of arms — if you drop India, you save India's full cost. The **observable** fixed cost share from the data is therefore approximately **zero**.

**What the data doesn't tell us:** There are real study-wide costs not in Table 4 — J-PAL coordination across 6 countries, common protocol development, centralized data management, and publication. These are genuine fixed costs (invariant to J) but are not reported.

**The 10% is a judgment call, not a data-derived estimate.** We cannot identify cf_share from a single experiment's cost tables. Instead, we bound it:
- **Lower bound ≈ 0:** Observable costs are entirely per-arm/per-participant.
- **Upper bound ≈ 0.15–0.20:** Even if coordination costs were $2–3M on top of the $14.8M in implementation, cf_share stays below 0.20.
- **We use 0.10 as a round number in the middle of the plausible range**, but the results section shows sensitivity across the full range.

**J_bar = 6:** We set this to the number of arms in this study, since we are calibrating to this specific experiment rather than to an external reference population.

**Note on compliance:** Table 4/S7 costs are per complier, not per ITT-assigned household (Table S7 notes; India compliance = 51.5%, others likely ~90–95%). Our code uses N_assigned, overstating total costs by ~7%. This does not affect the cf_share classification, which depends on cost *structure*, not exact totals.

### Why the default cost parameters don't fit this setting

The FDA linear default (cf_share = 0.46) is calibrated to pharma trials where a single drug is developed at huge fixed cost and then tested across subgroups at low marginal cost. The J-PAL CD default (β = 0.13) reflects the average economics experiment where adding an arm within a single site is cheap. In Banerjee et al., each country arm has independent implementation with per-participant costs of $1,000–5,000 PPP. Adding a country arm costs millions — the opposite of the default assumptions.

### Calibrated thresholds vs. BH (one-sided, α_bar = 0.05, J = 6)

| Method | α_opt (1-sided) | α_opt (2-sided equiv) |
|--------|----------------|-----------------------|
| No correction | 0.050 | 0.100 |
| **VWN-Lin calibrated (cf_share=0.10)** | **0.033** | **0.067** |
| BH (step-up) | varies | varies |
| VWN-Lin default (cf_share=0.46) | 0.020 | 0.040 |
| VWN-CD default (β=0.13) | 0.011 | 0.021 |
| Bonferroni | 0.008 | 0.017 |

The calibrated threshold (0.033 one-sided) is **more generous than BH** in most cases, because BH's step-up rule becomes conservative when few hypotheses are significant (it requires p_(k) ≤ k·α/J for the k-th smallest p-value). The calibrated VWN applies a single threshold to each test independently.

### Summary: Calibrated VWN vs BH and default VWN (10% significance)

| Outcome       | EL1 J | Naive | BH | CD | L_def | **L_cal** | EL2 J | Naive | BH | CD | L_def | **L_cal** |
|---------------|-------|-------|----|-----|-------|-----------|-------|-------|----|-----|-------|-----------|
| Consumption   | 6     | 4     | 4  | 3   | 4     | **4**     | 6     | 5     | 3  | 3   | 3     | **3**     |
| Income        | 6     | 5     | 5  | 5   | 5     | **5**     | 6     | 6     | 6  | 4   | 4     | **5**     |
| Assets        | 6     | 5     | 5  | 5   | 5     | **5**     | 6     | 5     | 4  | 4   | 4     | **4**     |
| FoodSecurity  | 6     | 4     | 4  | 2   | 4     | **4**     | 6     | 4     | 2  | 2   | 2     | **2**     |
| FinInclusion  | 6     | 4     | 3  | 3   | 3     | **3**     | 6     | 3     | 3  | 3   | 3     | **3**     |
| TimeUse       | 6     | 3     | 3  | 3   | 3     | **3**     | 6     | 2     | 2  | 2   | 2     | **2**     |
| PhysHealth    | 6     | 5     | 3  | 1   | 2     | **3**     | 6     | 1     | 0  | 0   | 1     | **1**     |
| MentalHealth  | 5     | 2     | 2  | 2   | 2     | **2**     | 6     | 2     | 2  | 2   | 2     | **2**     |
| PolInvolve    | 6     | 2     | 2  | 2   | 2     | **2**     | 6     | 4     | 3  | 2   | 3     | **3**     |
| WomensEmp     | 6     | 1     | 1  | 1   | 1     | **1**     | 5     | 0     | 0  | 0   | 0     | **0**     |

CD = VWN Cobb-Douglas default (β=0.13). L_def = VWN Linear default (cf_share=0.46, J_bar=3). **L_cal** = VWN Linear calibrated (cf_share=0.10, J_bar=6).

### VWN-calibrated vs BH: where they differ

In most cells, L_cal and BH agree. The interesting cases:

**L_cal rejects more than BH:**
- **PhysHealth EL2:** BH = 0, L_cal = 1. Peru has p_1s = 0.016, which passes the calibrated threshold (0.033) but fails BH because it's the only marginally significant country — BH's step-up rule requires p_(1) ≤ 1×0.05/6 = 0.0083, which fails. This is the same mechanism discussed in Exercise 2.
- **PhysHealth EL1:** BH = 3, L_cal = 3 (tied here, but BH = 3 vs CD = 1, showing the calibrated model agrees with BH rather than default VWN).

**BH rejects more than L_cal:**
- **Income EL2:** BH = 6, L_cal = 5. All 6 countries are significant under BH because the step-up procedure benefits from having many small p-values — once the largest k satisfying p_(k) ≤ k·α/6 is found, all ranks below are rejected. L_cal misses one country whose p_1s is between 0.033 and 0.05.

**Key takeaway:** The calibrated VWN and BH produce similar results in this application but for fundamentally different reasons. BH controls FDR through a statistical step-up rule. VWN uses the economic cost structure to determine how much correction is justified. When costs are mostly variable (as here), VWN says: this experiment was expensive precisely because it ran 6 arms, so don't penalize the researcher much for having 6 hypotheses.

### Sensitivity to cf_share

| cf_share | α_opt (1s) | Total rejections (EL1+EL2, across all outcomes) |
|----------|------------|------------------------------------------------|
| 0.05     | 0.040      | ~same as naive for most outcomes                |
| **0.10** | **0.033**  | **close to BH in most cases**                   |
| 0.15     | 0.029      | slightly more conservative than BH              |
| 0.20     | 0.025      | equivalent to naive 5% two-sided                |

The results are not highly sensitive within the plausible range (0.05–0.20). The threshold stays well above the default VWN levels throughout, because the economic argument is robust: costs in this setting are overwhelmingly per-arm, not fixed.

### Alternative calibration: cf_share = 0.23 (ambiguous items as fixed)

If we classify the "ambiguous" Table 4 line items (indirect costs ~12%, other supervision ~11%) as fixed rather than variable, the fixed cost share rises from 10% to 23%. This yields a tighter threshold:

| Method | α_opt (1-sided) | α_opt (2-sided equiv) |
|--------|----------------|-----------------------|
| **VWN-Lin (cf_share=0.23)** | **0.023** | **0.047** |
| VWN-Lin (cf_share=0.10) | 0.033 | 0.067 |
| BH (step-up) | varies | varies |

### Summary: cf_share = 0.23 vs BH and defaults (10% significance)

| Outcome       | EL1 J | Naive | BH | CD | L_def | **L_cal** | EL2 J | Naive | BH | CD | L_def | **L_cal** |
|---------------|-------|-------|----|-----|-------|-----------|-------|-------|----|-----|-------|-----------|
| Consumption   | 6     | 4     | 4  | 3   | 4     | **4**     | 6     | 5     | 3  | 3   | 3     | **3**     |
| Income        | 6     | 5     | 5  | 5   | 5     | **5**     | 6     | 6     | 6  | 4   | 4     | **4**     |
| Assets        | 6     | 5     | 5  | 5   | 5     | **5**     | 6     | 5     | 4  | 4   | 4     | **4**     |
| FoodSecurity  | 6     | 4     | 4  | 2   | 4     | **4**     | 6     | 4     | 2  | 2   | 2     | **2**     |
| FinInclusion  | 6     | 4     | 3  | 3   | 3     | **3**     | 6     | 3     | 3  | 3   | 3     | **3**     |
| TimeUse       | 6     | 3     | 3  | 3   | 3     | **3**     | 6     | 2     | 2  | 2   | 2     | **2**     |
| PhysHealth    | 6     | 5     | 3  | 1   | 2     | **3**     | 6     | 1     | 0  | 0   | 1     | **1**     |
| MentalHealth  | 5     | 2     | 2  | 2   | 2     | **2**     | 6     | 2     | 2  | 2   | 2     | **2**     |
| PolInvolve    | 6     | 2     | 2  | 2   | 2     | **2**     | 6     | 4     | 3  | 2   | 3     | **3**     |
| WomensEmp     | 6     | 1     | 1  | 1   | 1     | **1**     | 5     | 0     | 0  | 0   | 0     | **0**     |

**L_cal** = VWN Linear calibrated (cf_share=0.23, J_bar=6). Other columns unchanged from above.

### L_cal (0.23) vs BH: where they differ

At cf_share=0.23, L_cal and BH agree in 18 of 20 outcome-period cells. Two cells differ:

**L_cal rejects more than BH (1 cell):**
- **PhysHealth EL2:** L_cal = 1, BH = 0. Peru (p_1s = 0.016) passes the L_cal threshold (0.023) but fails BH's step-up rule, which requires p_(1) ≤ 0.05/6 = 0.0083 when only one country is marginally significant. This is the same finding as at cf_share = 0.10 — it persists because Peru's p-value (0.016) is well below the threshold (0.023).

**BH rejects more than L_cal (1 cell):**
- **Income EL2:** BH = 6, L_cal = 4. BH rejects all 6 countries via its step-up cascade (many small p-values lift the effective threshold for higher ranks). L_cal misses Peru (p_1s = 0.033) and Pakistan (p_1s = 0.049), both above the 0.023 threshold. At cf_share = 0.10, L_cal missed only Pakistan; the tighter threshold at 0.23 now also excludes Peru.

### Change from cf_share = 0.10 to 0.23

Only **1 cell** changes: **Income EL2** drops from L_cal = 5 to L_cal = 4 (Peru, p_1s = 0.033, falls between the two thresholds). All other 19 cells are identical. The classification of ambiguous cost items has minimal impact on conclusions.
