#' Estimate Cost Function Parameters for MHT Adjustment
#'
#' Estimates the parameters of the research cost function from data on project
#' costs, number of treatment arms, and sample sizes. Implements the estimation
#' approach from Section 6 and Appendix A of Viviano, Wuthrich, and Niehaus (2026).
#'
#' @param cost Numeric vector. Total project/trial costs.
#' @param arms Numeric vector. Number of treatment arms in each study.
#' @param sample_size Numeric vector. Sample size (total or per arm) in each study.
#' @param alpha_bar Numeric. Benchmark single-hypothesis test size.
#' @param model Character. \code{"cobbdouglas"} (default) estimates
#'   \eqn{\log(C) = \text{const} + \beta \log|J| + \iota \log(n)} via OLS,
#'   as in Table 2 of the paper. \code{"linear_share"} estimates
#'   \eqn{C = c_f + c_v \cdot |J| \cdot n} via OLS to decompose fixed and
#'   variable costs, then computes the fixed-cost share \eqn{c_f / \bar{C}}.
#' @param controls Optional data frame of control variables to include in the
#'   regression. Columns will be added as covariates.
#' @param robust Logical. Use heteroskedasticity-robust (HC1) standard errors.
#'   Default \code{TRUE}.
#'
#' @return A list of class \code{"mht_cost_estimate"} containing:
#'   \describe{
#'     \item{model}{Model type used}
#'     \item{fit}{The fitted \code{lm} object}
#'     \item{alpha_bar}{Benchmark alpha}
#'     \item{beta, iota}{Estimated parameters (Cobb-Douglas)}
#'     \item{beta_se, iota_se}{Standard errors}
#'     \item{p_beta0, p_beta1}{P-values for H0: beta=0 and beta=1}
#'     \item{p_iota0, p_iota1}{P-values for H0: iota=0 and iota=1}
#'     \item{c_f, c_v}{Estimated fixed and variable costs (Linear)}
#'     \item{cf_share}{Estimated fixed cost share (Linear)}
#'   }
#'
#' @examples
#' # Simulate data mimicking J-PAL cost structure
#' set.seed(42)
#' n <- 300
#' arms <- sample(1:5, n, replace = TRUE)
#' sample_size <- sample(500:5000, n, replace = TRUE)
#' cost <- exp(10 + 0.2 * log(arms) + 0.15 * log(sample_size) + rnorm(n, 0, 0.4))
#'
#' # Estimate Cobb-Douglas cost function
#' est <- mht_cost_estimate(cost, arms, sample_size, alpha_bar = 0.05)
#' print(est)
#'
#' # Use estimated parameters to compute critical values
#' mht_critical(J = 5, alpha_bar = 0.05, model = "cobbdouglas",
#'              beta = est$beta, iota = est$iota)
#'
#' @references
#' Viviano, D., Wuthrich, K., and Niehaus, P. (2026). "A Model of Multiple
#' Hypothesis Testing." arXiv:2104.13367v10. \url{https://arxiv.org/abs/2104.13367}
#'
#' @importFrom stats lm as.formula coef nobs residuals model.matrix pt
#' @export
mht_cost_estimate <- function(cost, arms, sample_size,
                              alpha_bar,
                              model = c("cobbdouglas", "linear_share"),
                              controls = NULL,
                              robust = TRUE) {

  model <- match.arg(model)

  # Input validation
  n <- length(cost)
  stopifnot(length(arms) == n, length(sample_size) == n)
  stopifnot(all(cost > 0), all(arms >= 1), all(sample_size > 0))
  stopifnot(alpha_bar > 0, alpha_bar < 1)

  if (model == "cobbdouglas") {
    # Log-linear estimation: log(C) = const + beta*log(J) + iota*log(n) + controls
    df <- data.frame(
      log_cost = log(cost),
      log_arms = log(arms),
      log_size = log(sample_size)
    )

    formula_str <- "log_cost ~ log_arms + log_size"

    if (!is.null(controls)) {
      controls_df <- as.data.frame(controls)
      for (nm in names(controls_df)) {
        df[[nm]] <- controls_df[[nm]]
        formula_str <- paste0(formula_str, " + ", nm)
      }
    }

    fit <- lm(as.formula(formula_str), data = df)
    beta_hat <- coef(fit)["log_arms"]
    iota_hat <- coef(fit)["log_size"]

    # Standard errors (robust or classical)
    if (robust) {
      # HC1 robust standard errors
      e <- residuals(fit)
      X <- model.matrix(fit)
      n_obs <- nrow(X)
      k <- ncol(X)
      bread <- solve(crossprod(X))
      meat <- crossprod(X * e) * n_obs / (n_obs - k)
      V <- bread %*% meat %*% bread
      se <- sqrt(diag(V))
      beta_se <- se["log_arms"]
      iota_se <- se["log_size"]
    } else {
      beta_se <- summary(fit)$coefficients["log_arms", "Std. Error"]
      iota_se <- summary(fit)$coefficients["log_size", "Std. Error"]
    }

    # Hypothesis tests
    n_obs <- nobs(fit)
    df_resid <- fit$df.residual
    p_beta0 <- 2 * pt(abs(beta_hat / beta_se), df = df_resid, lower.tail = FALSE)
    p_beta1 <- 2 * pt(abs((beta_hat - 1) / beta_se), df = df_resid, lower.tail = FALSE)
    p_iota0 <- 2 * pt(abs(iota_hat / iota_se), df = df_resid, lower.tail = FALSE)
    p_iota1 <- 2 * pt(abs((iota_hat - 1) / iota_se), df = df_resid, lower.tail = FALSE)

    result <- list(
      model = model,
      fit = fit,
      alpha_bar = alpha_bar,
      n_obs = n_obs,
      beta = unname(beta_hat),
      iota = unname(iota_hat),
      beta_se = unname(beta_se),
      iota_se = unname(iota_se),
      p_beta0 = unname(p_beta0),
      p_beta1 = unname(p_beta1),
      p_iota0 = unname(p_iota0),
      p_iota1 = unname(p_iota1),
      robust = robust
    )

  } else {
    # Linear model: C = c_f + c_v * J * n
    df <- data.frame(
      cost = cost,
      jn = arms * sample_size
    )

    formula_str <- "cost ~ jn"
    if (!is.null(controls)) {
      controls_df <- as.data.frame(controls)
      for (nm in names(controls_df)) {
        df[[nm]] <- controls_df[[nm]]
        formula_str <- paste0(formula_str, " + ", nm)
      }
    }

    fit <- lm(as.formula(formula_str), data = df)
    c_f <- coef(fit)["(Intercept)"]
    c_v <- coef(fit)["jn"]
    cf_share <- max(0, min(1, c_f / mean(cost)))
    mean_J <- mean(arms)

    result <- list(
      model = model,
      fit = fit,
      alpha_bar = alpha_bar,
      n_obs = nobs(fit),
      c_f = unname(c_f),
      c_v = unname(c_v),
      cf_share = unname(cf_share),
      mean_J = mean_J,
      robust = robust
    )
  }

  class(result) <- "mht_cost_estimate"
  result
}


#' @export
print.mht_cost_estimate <- function(x, ...) {
  cat("\n")
  cat(strrep("-", 65), "\n")

  if (x$model == "cobbdouglas") {
    cat("  Cost Function Estimation (Cobb-Douglas)\n")
    cat("  log(C) = const + beta*log(|J|) + iota*log(n)\n")
    cat(strrep("-", 65), "\n\n")

    cat(sprintf("  Observations:     %d\n", x$n_obs))
    cat(sprintf("  Robust SE:        %s\n\n", if (x$robust) "Yes (HC1)" else "No"))

    se_label <- if (x$robust) "Robust SE" else "SE"
    cat(sprintf("  %-18s %10s %10s\n", "Parameter", "Estimate", se_label))
    cat(strrep("-", 45), "\n")
    cat(sprintf("  %-18s %10.4f %10.4f\n", "beta (log arms)", x$beta, x$beta_se))
    cat(sprintf("  %-18s %10.4f %10.4f\n", "iota (log size)", x$iota, x$iota_se))
    cat(strrep("-", 45), "\n\n")

    cat("  Hypothesis Tests:\n")
    cat(sprintf("    H0: beta = 0 (Bonferroni):       p = %.4f\n", x$p_beta0))
    cat(sprintf("    H0: beta = 1 (no adjustment):    p = %.4f\n", x$p_beta1))
    cat(sprintf("    H0: iota = 0 (cost ~ n):         p = %.4f\n", x$p_iota0))
    cat(sprintf("    H0: iota = 1 (cost prop. to n):  p = %.4f\n", x$p_iota1))

  } else {
    cat("  Cost Function Estimation (Linear)\n")
    cat("  C = c_f + c_v * |J| * n\n")
    cat(strrep("-", 65), "\n\n")

    cat(sprintf("  Observations:     %d\n", x$n_obs))
    cat(sprintf("  Fixed cost (c_f):     %12.2f\n", x$c_f))
    cat(sprintf("  Variable cost (c_v):  %12.4f\n", x$c_v))
    cat(sprintf("  Fixed cost share:     %12.3f\n", x$cf_share))
    cat(sprintf("  Mean arms (J_bar):    %12.1f\n", x$mean_J))
  }

  cat(strrep("-", 65), "\n\n")
  invisible(x)
}
