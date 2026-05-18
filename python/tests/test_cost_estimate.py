"""Tests for mht_cost_estimate."""

import numpy as np
import pytest
from mhtopt.cost_estimate import mht_cost_estimate


np.random.seed(42)
n = 300
arms_sim = np.random.choice(range(1, 6), n)
ss_sim = np.random.choice(range(500, 5001), n)
cost_sim = np.exp(10 + 0.2 * np.log(arms_sim) + 0.15 * np.log(ss_sim) +
                  np.random.randn(n) * 0.4)


def test_cobbdouglas_recovers_beta():
    est = mht_cost_estimate(cost_sim, arms_sim, ss_sim, alpha_bar=0.05)
    assert abs(est["beta"] - 0.2) < 0.1


def test_cobbdouglas_recovers_iota():
    est = mht_cost_estimate(cost_sim, arms_sim, ss_sim, alpha_bar=0.05)
    assert abs(est["iota"] - 0.15) < 0.1


def test_linear_share_valid():
    cost_lin = 50000 + 10 * arms_sim * ss_sim + np.random.randn(n) * 5000
    est = mht_cost_estimate(cost_lin, arms_sim, ss_sim, alpha_bar=0.05,
                            model="linear_share")
    assert 0 < est["cf_share"] < 1


def test_beta_significantly_different_from_zero():
    est = mht_cost_estimate(cost_sim, arms_sim, ss_sim, alpha_bar=0.05)
    assert est["p_beta0"] < 0.05
