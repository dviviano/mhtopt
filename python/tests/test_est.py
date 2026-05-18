"""Tests for mht_est."""

import numpy as np
import pytest
from mhtopt.est import mht_est


# Create a mock fit object (dict-based)
np.random.seed(123)
n = 32
x1, x2, x3, x4 = np.random.randn(4, n)
y = 0.5 * x1 - 0.3 * x2 + 0.1 * x3 + np.random.randn(n)

# Simple OLS by hand for testing
X = np.column_stack([np.ones(n), x1, x2, x3, x4])
beta_hat = np.linalg.lstsq(X, y, rcond=None)[0]
e = y - X @ beta_hat
s2 = np.sum(e**2) / (n - 5)
se = np.sqrt(s2 * np.diag(np.linalg.inv(X.T @ X)))
t_stats = beta_hat / se
from scipy.stats import t as t_dist
p_values = 2 * t_dist.sf(np.abs(t_stats), df=n-5)

mock_fit = {
    "index": ["Intercept", "x1", "x2", "x3", "x4"],
    "params": beta_hat,
    "std_errors": se,
    "t_stats": t_stats,
    "p_values": p_values,
    "nobs": n,
}


def test_mht_est_returns_dict():
    r = mht_est(mock_fit, vars=["x1", "x2", "x3", "x4"], alpha_bar=0.05)
    assert isinstance(r, dict)


def test_mht_est_correct_keys():
    r = mht_est(mock_fit, vars=["x1", "x2", "x3", "x4"], alpha_bar=0.05)
    for key in ("terms", "estimates", "std_errors", "t_stats", "p_values",
                "reject_optimal", "reject_bonferroni", "reject_holm",
                "reject_bh", "reject_unadjusted"):
        assert key in r


def test_mht_est_preserves_variable_names():
    r = mht_est(mock_fit, vars=["x1", "x2", "x3", "x4"], alpha_bar=0.05)
    assert r["terms"] == ["x1", "x2", "x3", "x4"]


def test_mht_est_J_equals_4():
    r = mht_est(mock_fit, vars=["x1", "x2", "x3", "x4"], alpha_bar=0.05)
    assert r["J"] == 4


def test_mht_est_onesided_default():
    r = mht_est(mock_fit, vars=["x1", "x2", "x3", "x4"], alpha_bar=0.05)
    neg_t = r["t_stats"] < 0
    if neg_t.any():
        assert np.all(r["p_values"][neg_t] > 0.5)


def test_mht_est_twosided():
    r = mht_est(mock_fit, vars=["x1", "x2", "x3"], alpha_bar=0.05, onesided=False)
    assert np.all((r["p_values"] > 0) & (r["p_values"] <= 1))


def test_mht_est_missing_var():
    with pytest.raises(ValueError, match="NOTAVAR"):
        mht_est(mock_fit, vars=["x1", "NOTAVAR"], alpha_bar=0.05)


def test_mht_est_null_vars_excludes_intercept():
    r = mht_est(mock_fit, vars=None, alpha_bar=0.05)
    assert "Intercept" not in r["terms"]
    assert r["J"] == 4


def test_mht_est_cobbdouglas():
    r = mht_est(mock_fit, vars=["x1", "x2", "x3", "x4"],
                alpha_bar=0.05, model="cobbdouglas")
    assert r["model"] == "cobbdouglas"


def test_mht_est_mbar():
    r_default = mht_est(mock_fit, vars=["x1", "x2", "x3", "x4"], alpha_bar=0.05)
    r_mbar = mht_est(mock_fit, vars=["x1", "x2", "x3", "x4"], alpha_bar=0.05,
                     mbar=50)
    # mbar=50, nobs=32, J=4 => nm_ratio = (32/4)/50 = 0.16 < 1 => more conservative
    assert r_mbar["alpha_opt"] < r_default["alpha_opt"]


def test_mht_est_larger_study_larger_alpha():
    r_small = mht_est(mock_fit, vars=["x1", "x2"], alpha_bar=0.05, mbar=1000)
    r_large = mht_est(mock_fit, vars=["x1", "x2"], alpha_bar=0.05, mbar=10)
    assert r_large["alpha_opt"] > r_small["alpha_opt"]
