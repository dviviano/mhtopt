"""Generate tables of optimal critical values."""

import math

from mhtopt.critical import mht_critical


def mht_table(alpha_bar=None, J_range=None, nm_ratios=None, sidak_bars=None,
              model="linear", **kwargs):
    """
    Generate a table of optimal critical values.

    Default arguments reproduce Table 1 of Viviano, Wuthrich, and Niehaus (2026).

    Parameters
    ----------
    alpha_bar : list of float
        Benchmark sizes. Default [0.025, 0.05, 0.1, 0.15].
    J_range : list of int/float
        Hypothesis counts (rows). May include float('inf').
        Default [1, 2, ..., 9, inf].
    nm_ratios : list of float
        Sample size ratios. Default [0.5, 1.0, 1.5, 2.0].
    sidak_bars : list of float or None
        Alpha values for Sidak benchmark columns. Default [0.025, 0.05].
        Set to None to suppress.
    model : str
        Cost model: "linear" or "cobbdouglas".
    **kwargs
        Additional arguments passed to mht_critical (e.g., beta, iota, cf_share).

    Returns
    -------
    dict
        Keys: J (list), columns (dict of column_name -> list of values),
        alpha_bar, nm_ratios, sidak_bars, model.
    """
    if alpha_bar is None:
        alpha_bar = [0.025, 0.05, 0.1, 0.15]
    if J_range is None:
        J_range = list(range(1, 10)) + [float('inf')]
    if nm_ratios is None:
        nm_ratios = [0.5, 1.0, 1.5, 2.0]
    if sidak_bars is None:
        sidak_bars = [0.025, 0.05]

    if model not in ("linear", "cobbdouglas"):
        raise ValueError(f"model must be 'linear' or 'cobbdouglas', got '{model}'")

    columns = {}

    # Optimal critical value columns
    for nm in nm_ratios:
        for ab in alpha_bar:
            col_name = f"a{ab:.3f}_nm{nm:.1f}"
            columns[col_name] = [
                mht_critical(J=j, alpha_bar=ab, model=model, nm_ratio=nm, **kwargs)["alpha_opt"]
                for j in J_range
            ]

    # Sidak benchmark columns
    if sidak_bars:
        for ab in sidak_bars:
            col_name = f"sidak_{ab:.3f}"
            columns[col_name] = [
                0.0 if math.isinf(j) else 1 - (1 - ab) ** (1 / j)
                for j in J_range
            ]

    return {
        "J": J_range,
        "columns": columns,
        "alpha_bar": alpha_bar,
        "nm_ratios": nm_ratios,
        "sidak_bars": sidak_bars,
        "model": model,
    }


def print_table(tbl, digits=3):
    """Pretty-print an mht_table result."""
    J_range = tbl["J"]
    columns = tbl["columns"]
    model = tbl["model"]
    model_name = "Linear (Eq. 27)" if model == "linear" else "Cobb-Douglas"

    col_names = list(columns.keys())
    col_width = digits + 4

    rule_width = 6 + len(col_names) * (col_width + 1)

    print()
    print("=" * rule_width)
    print(f"  Optimal Critical Values ({model_name} model)")
    print("  Viviano, Wuthrich, and Niehaus (2026)")
    print("=" * rule_width)
    print()

    # Header
    header = f"  {'|J|':>3}"
    for name in col_names:
        header += f" {name:>{col_width}}"
    print("-" * rule_width)
    print(header)
    print("-" * rule_width)

    # Rows
    for i, j in enumerate(J_range):
        j_label = "Inf" if math.isinf(j) else str(int(j))
        row = f"  {j_label:>3}"
        for name in col_names:
            val = columns[name][i]
            row += f" {val:>{col_width}.{digits}f}"
        print(row)

    print("-" * rule_width)
    print()
