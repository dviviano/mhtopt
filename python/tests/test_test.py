"""Tests for mht_test."""

import numpy as np
import pytest
from scipy.stats import norm
from mhtopt.test import mht_test


pvals = np.array([0.003, 0.015, 0.030, 0.048, 0.120, 0.500])


def test_returns_all_keys():
    r = mht_test(p=pvals, alpha_bar=0.05)
    for key in ("p_values", "reject_optimal", "reject_bonferroni",
                "reject_holm", "reject_bh", "reject_unadjusted"):
        assert key in r


def test_z_stats_same_as_pvals():
    zs = norm.ppf(1 - pvals)
    r1 = mht_test(p=pvals, alpha_bar=0.05)
    r2 = mht_test(z=zs, alpha_bar=0.05)
    assert np.array_equal(r1["reject_optimal"], r2["reject_optimal"])


def test_optimal_gte_bonferroni_rejections():
    r = mht_test(p=pvals, alpha_bar=0.05)
    assert r["reject_optimal"].sum() >= r["reject_bonferroni"].sum()


def test_optimal_lte_unadjusted_rejections():
    r = mht_test(p=pvals, alpha_bar=0.05)
    assert r["reject_optimal"].sum() <= r["reject_unadjusted"].sum()


def test_tiny_pvals_all_rejected():
    r = mht_test(p=[0.001, 0.001, 0.001], alpha_bar=0.05)
    assert r["reject_optimal"].all()
    assert r["reject_bonferroni"].all()


def test_large_pvals_none_rejected():
    r = mht_test(p=[0.5, 0.6, 0.7], alpha_bar=0.05)
    assert not r["reject_optimal"].any()
    assert not r["reject_bonferroni"].any()
    assert not r["reject_unadjusted"].any()


def test_holm_gte_bonferroni_bh_gte_holm():
    r = mht_test(p=pvals, alpha_bar=0.05)
    assert r["reject_holm"].sum() >= r["reject_bonferroni"].sum()
    assert r["reject_bh"].sum() >= r["reject_holm"].sum()


def test_must_provide_p_or_z():
    with pytest.raises(ValueError):
        mht_test(alpha_bar=0.05)
    with pytest.raises(ValueError):
        mht_test(p=pvals, z=norm.ppf(1 - pvals), alpha_bar=0.05)


def test_cobbdouglas_model():
    r = mht_test(p=pvals, alpha_bar=0.05, model="cobbdouglas")
    assert r["model"] == "cobbdouglas"
