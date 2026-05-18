"""Tests for mht_critical."""

import math
import pytest
from mhtopt.critical import mht_critical


def test_J1_returns_alpha_bar():
    r = mht_critical(J=1, alpha_bar=0.05)
    assert abs(r["alpha_opt"] - 0.05) < 1e-10


def test_linear_alpha_opt_less_than_alpha_bar():
    r = mht_critical(J=5, alpha_bar=0.05, model="linear")
    assert r["alpha_opt"] < 0.05


def test_linear_alpha_opt_greater_than_bonferroni():
    r = mht_critical(J=5, alpha_bar=0.05, model="linear")
    assert r["alpha_opt"] > r["alpha_bonf"]


def test_linear_alpha_decreases_with_J():
    alphas = [mht_critical(j, 0.05, "linear")["alpha_opt"] for j in range(1, 11)]
    for i in range(len(alphas) - 1):
        assert alphas[i] >= alphas[i + 1]


def test_cobbdouglas_beta0_is_bonferroni():
    r = mht_critical(J=5, alpha_bar=0.05, model="cobbdouglas", beta=0, iota=0)
    assert abs(r["alpha_opt"] - 0.05 / 5) < 1e-10


def test_cobbdouglas_beta1_is_unadjusted():
    r = mht_critical(J=5, alpha_bar=0.05, model="cobbdouglas", beta=1, iota=0)
    assert abs(r["alpha_opt"] - 0.05) < 1e-10


def test_table1_spot_check():
    r = mht_critical(J=5, alpha_bar=0.05, model="linear")
    assert abs(r["alpha_opt"] - 0.021) < 0.002


def test_larger_nm_ratio_gives_larger_alpha():
    a1 = mht_critical(J=5, alpha_bar=0.05, nm_ratio=0.5)["alpha_opt"]
    a2 = mht_critical(J=5, alpha_bar=0.05, nm_ratio=1.0)["alpha_opt"]
    a3 = mht_critical(J=5, alpha_bar=0.05, nm_ratio=2.0)["alpha_opt"]
    assert a1 < a2 < a3


def test_J_inf_linear():
    r = mht_critical(J=float('inf'), alpha_bar=0.025, model="linear")
    assert r["alpha_opt"] > 0
    assert r["alpha_opt"] < 0.025


def test_J_inf_cobbdouglas():
    r = mht_critical(J=float('inf'), alpha_bar=0.025, model="cobbdouglas")
    assert abs(r["alpha_opt"]) < 1e-10


def test_invalid_J():
    with pytest.raises(ValueError):
        mht_critical(J=0, alpha_bar=0.05)


def test_invalid_alpha_bar():
    with pytest.raises(ValueError):
        mht_critical(J=5, alpha_bar=0)


def test_numeric_verification_linear_formula():
    ratio = 0.46 * 3 / (1 - 0.46)
    for j in [1, 3, 5, 9]:
        expected = 0.05 * (1 + ratio / j) / (1 + ratio)
        got = mht_critical(J=j, alpha_bar=0.05)["alpha_opt"]
        assert abs(got - expected) < 1e-8, f"J={j}: expected {expected}, got {got}"
