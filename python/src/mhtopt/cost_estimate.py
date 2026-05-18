"""Estimate cost function parameters for MHT adjustment."""

import numpy as np
from scipy.stats import t as t_dist


def mht_cost_estimate(cost, arms, sample_size, alpha_bar, model="cobbdouglas",
                      controls=None, robust=True):
    """
    Estimate cost function parameters from project-level data.

    Parameters
    ----------
    cost : array-like
        Total project/trial costs.
    arms : array-like
        Number of treatment arms in each study.
    sample_size : array-like
        Sample size (total or per arm) in each study.
    alpha_bar : float
        Benchmark single-hypothesis test size.
    model : str
        "cobbdouglas" (default) or "linear_share".
    controls : array-like or None
        Optional matrix of control variables (n x k).
    robust : bool
        Use HC1 robust standard errors. Default True.

    Returns
    -------
    dict
        For cobbdouglas: beta, iota, beta_se, iota_se, p_beta0, p_beta1,
        p_iota0, p_iota1, n_obs, model, alpha_bar.
        For linear_share: c_f, c_v, cf_share, mean_J, n_obs, model, alpha_bar.
    """
    if model not in ("cobbdouglas", "linear_share"):
        raise ValueError(f"model must be 'cobbdouglas' or 'linear_share', got '{model}'")

    cost = np.asarray(cost, dtype=float)
    arms = np.asarray(arms, dtype=float)
    sample_size = np.asarray(sample_size, dtype=float)

    n = len(cost)
    if len(arms) != n or len(sample_size) != n:
        raise ValueError("cost, arms, and sample_size must have the same length")
    if not (np.all(cost > 0) and np.all(arms >= 1) and np.all(sample_size > 0)):
        raise ValueError("cost must be > 0, arms >= 1, sample_size > 0")
    if not (0 < alpha_bar < 1):
        raise ValueError("alpha_bar must be in (0, 1)")

    if model == "cobbdouglas":
        # log(C) = const + beta*log(J) + iota*log(n) + controls
        y = np.log(cost)
        X = np.column_stack([np.ones(n), np.log(arms), np.log(sample_size)])

        if controls is not None:
            controls = np.asarray(controls, dtype=float)
            if controls.ndim == 1:
                controls = controls.reshape(-1, 1)
            X = np.column_stack([X, controls])

        # OLS
        beta_hat, residuals, rank, sv = np.linalg.lstsq(X, y, rcond=None)
        e = y - X @ beta_hat
        k = X.shape[1]
        df_resid = n - k

        # Standard errors
        if robust:
            # HC1
            bread = np.linalg.inv(X.T @ X)
            meat = (X.T * (e ** 2)) @ X * (n / (n - k))
            V = bread @ meat @ bread
        else:
            s2 = np.sum(e ** 2) / df_resid
            V = s2 * np.linalg.inv(X.T @ X)

        se = np.sqrt(np.diag(V))

        beta_est = beta_hat[1]
        iota_est = beta_hat[2]
        beta_se = se[1]
        iota_se = se[2]

        # Hypothesis tests
        p_beta0 = 2 * t_dist.sf(abs(beta_est / beta_se), df=df_resid)
        p_beta1 = 2 * t_dist.sf(abs((beta_est - 1) / beta_se), df=df_resid)
        p_iota0 = 2 * t_dist.sf(abs(iota_est / iota_se), df=df_resid)
        p_iota1 = 2 * t_dist.sf(abs((iota_est - 1) / iota_se), df=df_resid)

        return {
            "model": model,
            "alpha_bar": alpha_bar,
            "n_obs": n,
            "beta": float(beta_est),
            "iota": float(iota_est),
            "beta_se": float(beta_se),
            "iota_se": float(iota_se),
            "p_beta0": float(p_beta0),
            "p_beta1": float(p_beta1),
            "p_iota0": float(p_iota0),
            "p_iota1": float(p_iota1),
            "robust": robust,
        }

    else:
        # Linear: C = c_f + c_v * J * n
        y = cost
        jn = arms * sample_size
        X = np.column_stack([np.ones(n), jn])

        if controls is not None:
            controls = np.asarray(controls, dtype=float)
            if controls.ndim == 1:
                controls = controls.reshape(-1, 1)
            X = np.column_stack([X, controls])

        beta_hat, _, _, _ = np.linalg.lstsq(X, y, rcond=None)

        c_f = float(beta_hat[0])
        c_v = float(beta_hat[1])
        cf_share = max(0.0, min(1.0, c_f / float(np.mean(cost))))
        mean_J = float(np.mean(arms))

        return {
            "model": model,
            "alpha_bar": alpha_bar,
            "n_obs": n,
            "c_f": c_f,
            "c_v": c_v,
            "cf_share": cf_share,
            "mean_J": mean_J,
            "robust": robust,
        }
