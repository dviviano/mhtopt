"""Perform hypothesis tests with optimal MHT adjustment."""

import numpy as np
from scipy.stats import norm

from mhtopt.critical import mht_critical


def mht_test(p=None, z=None, alpha_bar=None, model="linear", cf_share=0.46,
             J_bar=3, nm_ratio=1.0, beta=0.13, iota=0.075):
    """
    Apply the model-optimal MHT adjustment to p-values or z-statistics.

    Parameters
    ----------
    p : array-like or None
        One-sided p-values. Provide either p or z.
    z : array-like or None
        Z-statistics. If provided, p-values are computed as 1 - Phi(z).
    alpha_bar : float
        Benchmark single-hypothesis test size.
    model : str
        Cost model: "linear" (default) or "cobbdouglas".
    cf_share, J_bar, nm_ratio, beta, iota : float
        Cost model parameters (see mht_critical).

    Returns
    -------
    dict
        Keys: p_values, reject_optimal, reject_bonferroni, reject_holm,
        reject_bh, reject_unadjusted, alpha_opt, alpha_bonf, alpha_bar, J, model.
    """
    if p is None and z is None:
        raise ValueError("Must provide either p or z")
    if p is not None and z is not None:
        raise ValueError("Provide either p or z, not both")
    if alpha_bar is None:
        raise ValueError("alpha_bar is required")

    if z is not None:
        p = 1 - norm.cdf(np.asarray(z, dtype=float))
    else:
        p = np.asarray(p, dtype=float)

    J = len(p)
    if J < 1:
        raise ValueError("Need at least one p-value")

    # Compute optimal critical value
    cv = mht_critical(J=J, alpha_bar=alpha_bar, model=model, cf_share=cf_share,
                      J_bar=J_bar, nm_ratio=nm_ratio, beta=beta, iota=iota)
    alpha_opt = cv["alpha_opt"]
    alpha_bonf = cv["alpha_bonf"]

    # 1. Optimal (model-based)
    reject_opt = p <= alpha_opt

    # 2. Bonferroni
    reject_bonf = p <= alpha_bonf

    # 3. Holm step-down
    reject_holm = _holm_reject(p, alpha_bar)

    # 4. Benjamini-Hochberg
    reject_bh = _bh_reject(p, alpha_bar)

    # 5. Unadjusted
    reject_unadj = p <= alpha_bar

    return {
        "p_values": p,
        "reject_optimal": reject_opt,
        "reject_bonferroni": reject_bonf,
        "reject_holm": reject_holm,
        "reject_bh": reject_bh,
        "reject_unadjusted": reject_unadj,
        "alpha_opt": alpha_opt,
        "alpha_bonf": alpha_bonf,
        "alpha_bar": alpha_bar,
        "J": J,
        "model": model,
    }


def _holm_reject(p, alpha):
    """Holm step-down procedure."""
    n = len(p)
    order = np.argsort(p)
    reject = np.zeros(n, dtype=bool)
    for i, idx in enumerate(order):
        if p[idx] <= alpha / (n - i):
            reject[idx] = True
        else:
            break
    return reject


def _bh_reject(p, alpha):
    """Benjamini-Hochberg step-up procedure."""
    n = len(p)
    order = np.argsort(p)
    reject = np.zeros(n, dtype=bool)
    # Find largest k such that p_(k) <= k/n * alpha
    max_k = -1
    for k in range(n):
        if p[order[k]] <= (k + 1) / n * alpha:
            max_k = k
    if max_k >= 0:
        reject[order[:max_k + 1]] = True
    return reject
