"""Postestimation: apply MHT testing to fitted model coefficients."""

import numpy as np
from scipy.stats import norm

from mhtopt.test import mht_test


def mht_est(fit, vars=None, alpha_bar=None, onesided=True, model="linear",
            cf_share=0.46, J_bar=3, nm_ratio=1.0, mbar=None,
            beta=0.13, iota=0.075):
    """
    Apply MHT adjustment to coefficients from a fitted regression model.

    Parameters
    ----------
    fit : object
        A fitted model object. Supported:
        - statsmodels RegressionResults (OLS, WLS, GLS, GLM, etc.)
        - linearmodels results (IV2SLS, OLS, PanelOLS, etc.)
        - Any object with .params, .bse, .tvalues, .pvalues attributes
        - A dict with keys 'params', 'std_errors', 't_stats', 'p_values', 'index'
    vars : list of str or None
        Coefficient names to test. If None, all non-intercept coefficients.
    alpha_bar : float
        Benchmark single-hypothesis test size.
    onesided : bool
        If True (default), convert two-sided p-values to one-sided
        (positive direction, per Remark 6 of the paper).
    model : str
        Cost model: "linear" (default) or "cobbdouglas".
    mbar : float or None
        Benchmark per-arm sample size. If supplied, nm_ratio = (nobs/J) / mbar.
    cf_share, J_bar, nm_ratio, beta, iota : float
        Cost model parameters (see mht_critical).

    Returns
    -------
    dict
        Keys: terms, estimates, std_errors, t_stats, p_values,
        reject_optimal, reject_bonferroni, reject_holm, reject_bh,
        reject_unadjusted, alpha_opt, alpha_bonf, alpha_bar, J, model, onesided.
    """
    if alpha_bar is None:
        raise ValueError("alpha_bar is required")

    # Extract coefficient table
    coef_table = _extract_coef_table(fit)
    terms = coef_table["terms"]
    estimates = coef_table["estimates"]
    std_errors = coef_table["std_errors"]
    t_stats = coef_table["t_stats"]
    p_two = coef_table["p_values"]

    # Select variables
    if vars is not None:
        indices = []
        for v in vars:
            if v not in terms:
                raise ValueError(
                    f"Variable '{v}' not found in model coefficients. "
                    f"Available: {list(terms)}"
                )
            indices.append(list(terms).index(v))
        indices = np.array(indices)
    else:
        # Exclude intercept-like terms
        indices = np.array([i for i, t in enumerate(terms)
                           if t not in ("Intercept", "const", "(Intercept)")])

    if len(indices) == 0:
        raise ValueError("No coefficients selected for testing.")

    terms = np.array(terms)[indices]
    estimates = estimates[indices]
    std_errors = std_errors[indices]
    t_stats = t_stats[indices]
    p_two = p_two[indices]

    J = len(terms)

    # Compute nm_ratio from mbar if supplied
    if mbar is not None:
        nobs = _get_nobs(fit)
        if nobs is None:
            raise ValueError("Cannot determine sample size from model; specify nm_ratio directly.")
        nm_ratio = (nobs / J) / mbar

    # Compute p-values for testing
    if onesided:
        # One-sided (positive direction):
        #   t >= 0: p = p_two / 2
        #   t <  0: p = 1 - p_two / 2
        p_test = np.where(t_stats >= 0, p_two / 2, 1 - p_two / 2)
    else:
        p_test = p_two

    # Apply MHT testing
    result = mht_test(p=p_test, alpha_bar=alpha_bar, model=model,
                      cf_share=cf_share, J_bar=J_bar, nm_ratio=nm_ratio,
                      beta=beta, iota=iota)

    return {
        "terms": list(terms),
        "estimates": estimates,
        "std_errors": std_errors,
        "t_stats": t_stats,
        "p_values": p_test,
        "reject_optimal": result["reject_optimal"],
        "reject_bonferroni": result["reject_bonferroni"],
        "reject_holm": result["reject_holm"],
        "reject_bh": result["reject_bh"],
        "reject_unadjusted": result["reject_unadjusted"],
        "alpha_opt": result["alpha_opt"],
        "alpha_bonf": result["alpha_bonf"],
        "alpha_bar": alpha_bar,
        "J": J,
        "model": model,
        "onesided": onesided,
    }


def _extract_coef_table(fit):
    """Extract standardized coefficient table from various model objects."""

    # Dict input (manual specification)
    if isinstance(fit, dict):
        return {
            "terms": np.array(fit["index"]),
            "estimates": np.asarray(fit["params"], dtype=float),
            "std_errors": np.asarray(fit["std_errors"], dtype=float),
            "t_stats": np.asarray(fit["t_stats"], dtype=float),
            "p_values": np.asarray(fit["p_values"], dtype=float),
        }

    # statsmodels-style: has .params, .bse, .tvalues, .pvalues as Series/arrays
    if hasattr(fit, "params") and hasattr(fit, "bse"):
        params = fit.params
        bse = fit.bse
        tvalues = getattr(fit, "tvalues", params / bse)
        pvalues = getattr(fit, "pvalues", None)

        # If pandas Series, extract index and values
        if hasattr(params, "index"):
            terms = np.array(params.index.tolist())
            estimates = np.asarray(params.values, dtype=float)
            std_errors = np.asarray(bse.values, dtype=float)
            t_stats = np.asarray(tvalues.values if hasattr(tvalues, "values") else tvalues, dtype=float)
            if pvalues is not None:
                p_values = np.asarray(pvalues.values if hasattr(pvalues, "values") else pvalues, dtype=float)
            else:
                p_values = 2 * (1 - norm.cdf(np.abs(t_stats)))
        else:
            raise ValueError(
                "Model has .params but no .index — pass a dict with "
                "'index', 'params', 'std_errors', 't_stats', 'p_values' keys."
            )

        return {
            "terms": terms,
            "estimates": estimates,
            "std_errors": std_errors,
            "t_stats": t_stats,
            "p_values": p_values,
        }

    raise ValueError(
        f"Cannot extract coefficients from object of type '{type(fit).__name__}'. "
        "Supported: statsmodels results, linearmodels results, or a dict with keys "
        "'index', 'params', 'std_errors', 't_stats', 'p_values'."
    )


def _get_nobs(fit):
    """Extract number of observations from a model object."""
    if isinstance(fit, dict):
        return fit.get("nobs")
    if hasattr(fit, "nobs"):
        n = fit.nobs
        return int(n) if n is not None else None
    if hasattr(fit, "model") and hasattr(fit.model, "nobs"):
        return int(fit.model.nobs)
    return None
