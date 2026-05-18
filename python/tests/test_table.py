"""Tests for mht_table."""

import math
from mhtopt.table import mht_table


def test_returns_dict_with_J():
    t = mht_table(alpha_bar=[0.05], J_range=[1, 2, 3, 4, 5], nm_ratios=[1.0])
    assert "J" in t
    assert len(t["J"]) == 5


def test_correct_number_of_columns():
    t = mht_table(alpha_bar=[0.025, 0.05], J_range=[1, 2, 3],
                  nm_ratios=[1.0], sidak_bars=[0.025])
    # 2 alpha_bar * 1 nm_ratio + 1 sidak = 3 columns
    assert len(t["columns"]) == 3


def test_cobbdouglas_model():
    t = mht_table(model="cobbdouglas", alpha_bar=[0.05], J_range=[1, 2, 3],
                  nm_ratios=[1.0], beta=0.13, iota=0.075)
    assert t["model"] == "cobbdouglas"
    assert len(t["J"]) == 3


def test_sidak_suppressed_when_empty():
    t = mht_table(alpha_bar=[0.05], J_range=[1, 2, 3], nm_ratios=[1.0],
                  sidak_bars=[])
    assert not any("sidak" in k for k in t["columns"])


def test_inf_row_included():
    t = mht_table(alpha_bar=[0.05], J_range=[1, 2, float('inf')], nm_ratios=[1.0])
    assert float('inf') in t["J"]


def test_default_reproduces_table1_dimensions():
    t = mht_table()
    assert len(t["J"]) == 10  # 1..9 + inf
    # 4 alpha_bar * 4 nm_ratios + 2 sidak = 18 columns
    assert len(t["columns"]) == 18
