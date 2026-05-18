"""Compute optimal MHT critical values."""

import math
from scipy.stats import norm


def mht_critical(J, alpha_bar, model="linear", cf_share=0.46, J_bar=3,
                 nm_ratio=1.0, beta=0.13, iota=0.075):
    """
    Compute optimal critical values for multiple hypothesis testing.

    Based on Proposition 4.1 of Viviano, Wuthrich, and Niehaus (2026).

    Parameters
    ----------
    J : int or float('inf')
        Number of hypotheses being tested.
    alpha_bar : float
        Benchmark single-hypothesis test size (e.g., 0.05).
    model : str
        Cost model: "linear" (default) or "cobbdouglas".
    cf_share : float
        Fixed cost share (Linear model). Default 0.46.
    J_bar : float
        Average number of subgroups (Linear model). Default 3.
    nm_ratio : float
        Ratio of per-arm sample size to benchmark. Default 1.0.
    beta : float
        Elasticity of cost w.r.t. arms (Cobb-Douglas). Default 0.13.
    iota : float
        Elasticity of cost w.r.t. sample size (Cobb-Douglas). Default 0.075.

    Returns
    -------
    dict
        Keys: alpha_opt, t_star, alpha_bonf, t_bonf, alpha_sidak, t_sidak,
        alpha_bar, J, nm_ratio, model.
    """
    if model not in ("linear", "cobbdouglas"):
        raise ValueError(f"model must be 'linear' or 'cobbdouglas', got '{model}'")
    if not (math.isinf(J) or J >= 1):
        raise ValueError("J must be >= 1 or inf")
    if not (0 < alpha_bar < 1):
        raise ValueError("alpha_bar must be in (0, 1)")
    if nm_ratio <= 0:
        raise ValueError("nm_ratio must be > 0")

    if model == "linear":
        # Linear cost model (Equation 27 in v10)
        ratio = cf_share * J_bar / (1 - cf_share)
        if math.isinf(J):
            multiplicity_adj = 1 / (1 + ratio)
        else:
            multiplicity_adj = (1 + ratio / J) / (1 + ratio)
        sample_adj = (nm_ratio - 1) / (1 + ratio)
        alpha_opt = alpha_bar * (multiplicity_adj + sample_adj)
    else:
        # Cobb-Douglas model (Appendix A / J-PAL calibration)
        if math.isinf(J):
            alpha_opt = 0.0  # J^(beta-1) -> 0 since beta < 1
        else:
            alpha_opt = alpha_bar * (J ** (beta - 1)) * (nm_ratio ** iota)

    # Clamp to valid range
    alpha_opt = min(max(alpha_opt, 0.0), 1.0)

    # z-thresholds
    t_star = norm.ppf(1 - alpha_opt) if alpha_opt > 0 else float('inf')

    # Bonferroni
    if math.isinf(J):
        alpha_bonf = 0.0
        t_bonf = float('inf')
    else:
        alpha_bonf = alpha_bar / J
        t_bonf = norm.ppf(1 - alpha_bonf)

    # Sidak
    if math.isinf(J):
        alpha_sidak = 0.0
        t_sidak = float('inf')
    else:
        alpha_sidak = 1 - (1 - alpha_bar) ** (1 / J)
        t_sidak = norm.ppf(1 - alpha_sidak)

    return {
        "alpha_opt": alpha_opt,
        "t_star": t_star,
        "alpha_bonf": alpha_bonf,
        "t_bonf": t_bonf,
        "alpha_sidak": alpha_sidak,
        "t_sidak": t_sidak,
        "alpha_bar": alpha_bar,
        "J": J,
        "nm_ratio": nm_ratio,
        "model": model,
    }
