"""
MHT: Optimal Multiple Hypothesis Testing Corrections

Implements the optimal MHT correction from Proposition 4.1 of
Viviano, Wuthrich, and Niehaus (2026, arXiv:2104.13367v10).

Functions:
    mht_critical     -- Compute optimal per-test significance level
    mht_test         -- Apply MHT adjustment to p-values
    mht_est          -- Postestimation: test coefficients from a fitted model
    mht_cost_estimate -- Estimate cost function parameters from data
    mht_table        -- Generate reference tables of critical values
"""

from mhtopt.critical import mht_critical
from mhtopt.test import mht_test
from mhtopt.est import mht_est
from mhtopt.cost_estimate import mht_cost_estimate
from mhtopt.table import mht_table

__version__ = "0.1.0"
__all__ = ["mht_critical", "mht_test", "mht_est", "mht_cost_estimate", "mht_table"]
