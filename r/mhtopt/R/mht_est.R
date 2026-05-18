#' Apply MHT Testing Directly to a Fitted Model (Postestimation)
#'
#' Extracts coefficient estimates, standard errors, and p-values from a fitted
#' regression object and applies the optimal MHT adjustment from Proposition 4.1
#' of Viviano, Wuthrich, and Niehaus (2026). This is the standard research
#' workflow interface: run a regression, then call \code{mht_est()} on
#' the result.
#'
#' @details
#' Supported model classes:
#' \itemize{
#'   \item \code{lm}, \code{glm} (base R)
#'   \item \code{lm_robust}, \code{iv_robust} (estimatr package)
#'   \item \code{fixest} class objects, e.g. \code{feols()}, \code{fepois()} (fixest package)
#' }
#' Any other class with a \code{coef(summary(fit))} method returning a
#' standard 4-column matrix (Estimate, Std. Error, t/z value, Pr(>|t|)) will
#' also work.
#'
#' @section One-sided vs. two-sided p-values:
#' Most estimation functions return two-sided p-values. By default
#' (\code{onesided = TRUE}), this function converts to one-sided p-values in
#' the positive direction. This is theoretically grounded in \strong{Remark 6}
#' of the paper: under Assumptions 2–4 (linearity, welfare additivity, and
#' normality), one-sided t-tests are \emph{globally optimal}. The key
#' assumption is that the \emph{status quo} (the baseline policy) remains in
#' place whenever the researcher does not report a positive finding. Negative
#' treatment effects therefore never lead to rejection (welfare gains require
#' positive effects).
#'
#' \strong{Two-sided tests} (\code{onesided = FALSE}) are appropriate when
#' there is uncertainty about the policymaker's default action — i.e., the
#' policymaker may implement a treatment even in the absence of a positive
#' recommendation. \strong{Appendix B.2} (Proposition 9) of the paper shows
#' that in this extended model, two-sided t-tests with the \emph{same}
#' critical threshold \eqn{t^* = \Phi^{-1}(1 - \alpha^*)}{t* = Phi^{-1}(1 - alpha*)}
#' are maximin optimal.
#'
#' Conversion when \code{onesided = TRUE}:
#' \itemize{
#'   \item If t-statistic >= 0: \code{p_one = p_two / 2}
#'   \item If t-statistic < 0:  \code{p_one = 1 - p_two / 2}
#' }
#' A negative effect is never rejected (p_one > 0.5 for t < 0).
#'
#' @param fit A fitted model object. See Details for supported classes.
#' @param vars Character vector of coefficient names to test. If \code{NULL},
#'   all coefficients except \code{"(Intercept)"} are tested. Names must
#'   match the rownames of \code{coef(summary(fit))} exactly.
#' @param alpha_bar Numeric. Benchmark single-hypothesis significance level
#'   (e.g., 0.05).
#' @param onesided Logical. If \code{TRUE} (default), two-sided p-values from
#'   the model are converted to one-sided (positive direction). See Details.
#' @param model Character. Cost model: \code{"linear"} (default) or
#'   \code{"cobbdouglas"}. Passed to \code{\link{mht_critical}}.
#' @param cf_share Numeric. Fixed cost share (Linear model). Default 0.46.
#' @param J_bar Numeric. Average number of subgroups (Linear model). Default 3.
#' @param nm_ratio Numeric. Sample size ratio n_bar/m_bar. Default 1.0.
#'   Overridden by \code{mbar} if supplied.
#' @param mbar Numeric or \code{NULL}. Benchmark per-arm sample size. If
#'   supplied, \code{nm_ratio} is computed as \code{nobs(fit) / J / mbar},
#'   where J is the number of hypotheses tested.
#' @param beta Numeric. Arms elasticity (Cobb-Douglas). Default 0.13.
#' @param iota Numeric. Sample size elasticity (Cobb-Douglas). Default 0.075.
#'
#' @return A data frame of class \code{c("mht_est", "data.frame")} with
#'   columns:
#'   \describe{
#'     \item{term}{Coefficient name}
#'     \item{estimate}{Point estimate}
#'     \item{std_error}{Standard error}
#'     \item{t_stat}{t- or z-statistic}
#'     \item{p_value}{p-value used for testing (one-sided if \code{onesided=TRUE})}
#'     \item{reject_optimal}{Logical. Rejection under optimal model-based procedure}
#'     \item{reject_bonferroni}{Logical. Rejection under Bonferroni}
#'     \item{reject_holm}{Logical. Rejection under Holm step-down}
#'     \item{reject_bh}{Logical. Rejection under Benjamini-Hochberg (FDR)}
#'     \item{reject_unadjusted}{Logical. Rejection without adjustment}
#'   }
#'   Attributes \code{alpha_opt}, \code{alpha_bonf}, \code{alpha_bar},
#'   \code{J}, and \code{model} are attached.
#'
#' @examples
#' # Basic usage with lm()
#' data(mtcars)
#' fit <- lm(mpg ~ cyl + hp + wt + am, data = mtcars)
#' mht_est(fit, vars = c("cyl", "hp", "wt", "am"), alpha_bar = 0.05)
#'
#' # With Cobb-Douglas model
#' mht_est(fit, vars = c("cyl", "hp", "wt", "am"), alpha_bar = 0.05,
#'                model = "cobbdouglas", beta = 0.13, iota = 0.075)
#'
#' # Two-sided test (e.g., for a two-sided hypothesis)
#' mht_est(fit, vars = c("cyl", "hp", "wt"), alpha_bar = 0.05,
#'                onesided = FALSE)
#'
#' # With estimatr::lm_robust (if installed):
#' # fit_r <- estimatr::lm_robust(mpg ~ cyl + hp + wt,
#' #            clusters = ~am, data = mtcars)
#' # mht_est(fit_r, vars = c("cyl", "hp", "wt"), alpha_bar = 0.05)
#'
#' # With fixest::feols (if installed):
#' # fit_fe <- fixest::feols(mpg ~ cyl + hp + wt | gear, data = mtcars)
#' # mht_est(fit_fe, vars = c("cyl", "hp", "wt"), alpha_bar = 0.05)
#'
#' @seealso \code{\link{mht_test}} for direct p-value input,
#'   \code{\link{mht_critical}} for computing critical values only.
#'
#' @references
#' Viviano, D., Wuthrich, K., and Niehaus, P. (2026). "A Model of Multiple
#' Hypothesis Testing." arXiv:2104.13367v10. \url{https://arxiv.org/abs/2104.13367}
#'
#' @importFrom stats nobs coef
#' @export
mht_est <- function(fit,
                            vars      = NULL,
                            alpha_bar,
                            onesided  = TRUE,
                            model     = c("linear", "cobbdouglas"),
                            cf_share  = 0.46,
                            J_bar     = 3,
                            nm_ratio  = 1.0,
                            mbar      = NULL,
                            beta      = 0.13,
                            iota      = 0.075) {

  model <- match.arg(model)
  stopifnot(alpha_bar > 0, alpha_bar < 1)
  if (is.null(mbar)) {
    stopifnot(nm_ratio > 0)
  } else {
    stopifnot(is.numeric(mbar), length(mbar) == 1, mbar > 0)
  }

  # Extract coefficient table from the model object
  cf <- .extract_coef_table(fit)

  # Select requested variables
  if (!is.null(vars)) {
    missing_vars <- setdiff(vars, cf$term)
    if (length(missing_vars) > 0) {
      stop(sprintf(
        "Variable(s) not found in model coefficients: %s\nAvailable: %s",
        paste(missing_vars, collapse = ", "),
        paste(cf$term, collapse = ", ")
      ))
    }
    cf <- cf[match(vars, cf$term), , drop = FALSE]
  } else {
    cf <- cf[cf$term != "(Intercept)", , drop = FALSE]
    cf <- cf[!grepl("^\\(|^_cons", cf$term), , drop = FALSE]
  }

  if (nrow(cf) == 0) {
    stop("No coefficients selected for testing. ",
         "Check that 'vars' matches coefficient names in the model.")
  }

  # Override nm_ratio from mbar if supplied: nm_ratio = (N/J) / mbar
  if (!is.null(mbar)) {
    n_fit <- tryCatch(nobs(fit), error = function(e) NA_real_)
    if (is.na(n_fit) || !is.finite(n_fit))
      stop("Cannot determine sample size from model; specify nm_ratio directly.")
    nm_ratio <- (n_fit / nrow(cf)) / mbar
  }

  # Compute p-values for testing
  if (onesided) {
    # One-sided p-value in the positive direction:
    #   t >= 0 -> p = p_two / 2
    #   t <  0 -> p = 1 - p_two / 2  (effectively no rejection for negative effects)
    p_test <- ifelse(cf$t_stat >= 0, cf$p_two / 2, 1 - cf$p_two / 2)
  } else {
    p_test <- cf$p_two
  }

  # Apply MHT testing
  mht_res <- mht_test(
    p        = p_test,
    alpha_bar = alpha_bar,
    model    = model,
    cf_share = cf_share,
    J_bar    = J_bar,
    nm_ratio = nm_ratio,
    beta     = beta,
    iota     = iota
  )

  # Construct output data frame preserving variable names
  out <- data.frame(
    term              = cf$term,
    estimate          = cf$estimate,
    std_error         = cf$std_error,
    t_stat            = cf$t_stat,
    p_value           = mht_res$p_value,
    reject_optimal    = mht_res$reject_optimal,
    reject_bonferroni = mht_res$reject_bonferroni,
    reject_holm       = mht_res$reject_holm,
    reject_bh         = mht_res$reject_bh,
    reject_unadjusted = mht_res$reject_unadjusted,
    stringsAsFactors  = FALSE,
    row.names         = NULL
  )

  # Copy attributes from mht_res
  for (nm in c("alpha_opt", "alpha_bonf", "alpha_bar", "J", "model")) {
    attr(out, nm) <- attr(mht_res, nm)
  }
  attr(out, "onesided") <- onesided

  class(out) <- c("mht_est", "data.frame")
  out
}


#' @export
print.mht_est <- function(x, digits = 4, ...) {
  J          <- attr(x, "J")
  alpha_opt  <- attr(x, "alpha_opt")
  alpha_bonf <- attr(x, "alpha_bonf")
  alpha_bar  <- attr(x, "alpha_bar")
  model      <- attr(x, "model")
  onesided   <- attr(x, "onesided")

  cat("\n")
  cat(strrep("-", 72), "\n")
  cat("  MHT Postestimation Results\n")
  cat("  Viviano, Wuthrich, and Niehaus (2026)\n")
  cat(strrep("-", 72), "\n\n")

  model_name <- if (is.null(model) || length(model) == 0) "unknown"
                else if (model == "linear") "Linear" else "Cobb-Douglas"
  side_str   <- if (isTRUE(onesided)) "one-sided (positive direction)" else "two-sided"
  cat(sprintf("  Hypotheses tested:    %d\n", J))
  cat(sprintf("  Benchmark alpha:      %.4f\n", alpha_bar))
  cat(sprintf("  Cost model:           %s\n", model_name))
  cat(sprintf("  P-values:             %s\n\n", side_str))

  cat(strrep("-", 58), "\n")
  cat(sprintf("  %-24s %10s %12s\n", "Procedure", "Test size", "Rejections"))
  cat(strrep("-", 58), "\n")
  cat(sprintf("  %-24s %10.6f %12d\n", "Optimal (model-based)", alpha_opt, sum(x$reject_optimal)))
  cat(sprintf("  %-24s %10.6f %12d\n", "Bonferroni",            alpha_bonf, sum(x$reject_bonferroni)))
  cat(sprintf("  %-24s %10s %12d\n", "Holm (step-down)",  "step-wise", sum(x$reject_holm)))
  cat(sprintf("  %-24s %10s %12d\n", "BH (FDR control)",  "step-wise", sum(x$reject_bh)))
  cat(sprintf("  %-24s %10.6f %12d\n", "Unadjusted",           alpha_bar,  sum(x$reject_unadjusted)))
  cat(strrep("-", 58), "\n\n")

  cat("  Detailed results (* = reject at threshold):\n\n")

  # Format the detailed table
  fmt_bool <- function(v) ifelse(v, "  *  ", "  .  ")

  display_df <- data.frame(
    term      = x$term,
    estimate  = formatC(x$estimate,  format = "f", digits = digits),
    se        = formatC(x$std_error, format = "f", digits = digits),
    t_stat    = formatC(x$t_stat,    format = "f", digits = 3),
    p_val     = formatC(x$p_value,   format = "f", digits = digits),
    optimal   = fmt_bool(x$reject_optimal),
    bonf      = fmt_bool(x$reject_bonferroni),
    holm      = fmt_bool(x$reject_holm),
    bh        = fmt_bool(x$reject_bh),
    unadj     = fmt_bool(x$reject_unadjusted),
    stringsAsFactors = FALSE
  )
  names(display_df) <- c("term", "estimate", "se", "t_stat", "p_value",
                          "optimal", "bonf", "holm", "bh", "unadj")
  print(display_df, row.names = FALSE)
  cat("\n")

  invisible(x)
}


# ============================================================================
# Internal helper: extract standardized coefficient table from model objects
# ============================================================================

#' @keywords internal
#' @noRd
.extract_coef_table <- function(fit) {

  # --- fixest (feols, fepois, feglm, etc.) ---
  if (inherits(fit, "fixest")) {
    if (!requireNamespace("fixest", quietly = TRUE)) {
      stop("Package 'fixest' must be installed to use fixest model objects.")
    }
    s <- fixest::coeftable(fit)
    return(.parse_coef_matrix(s))
  }

  # --- estimatr: lm_robust, iv_robust ---
  if (inherits(fit, c("lm_robust", "iv_robust"))) {
    s <- summary(fit)$coefficients
    return(.parse_coef_matrix(s))
  }

  # --- base R: lm, glm ---
  if (inherits(fit, c("lm", "glm"))) {
    s <- coef(summary(fit))
    return(.parse_coef_matrix(s))
  }

  # --- generic fallback: try coef(summary(fit)) ---
  s <- tryCatch(
    coef(summary(fit)),
    error = function(e) {
      tryCatch(
        summary(fit)$coefficients,
        error = function(e2) {
          stop(sprintf(
            paste0("Cannot extract coefficient table from object of class '%s'.\n",
                   "Supported classes: lm, glm, lm_robust/iv_robust (estimatr), ",
                   "fixest.\nFor other classes, ensure coef(summary(fit)) returns ",
                   "a matrix with columns: Estimate, Std. Error, t/z value, Pr(>|t|)."),
            paste(class(fit), collapse = "/")
          ))
        }
      )
    }
  )
  .parse_coef_matrix(s)
}


#' @keywords internal
#' @noRd
.parse_coef_matrix <- function(s) {
  # Robustly identify columns regardless of exact naming conventions
  cols <- colnames(s)

  est_col <- grep("^Estimate$",                         cols, value = TRUE)[1]
  se_col  <- grep("Std\\..*Error|Std Error|std_error",  cols, value = TRUE, ignore.case = TRUE)[1]
  t_col   <- grep("t value|z value|[Tt]\\s*value|Statistic", cols, value = TRUE)[1]
  p_col   <- grep("Pr\\(|p.value|p value|p_value",     cols, value = TRUE, ignore.case = TRUE)[1]

  if (is.na(est_col)) stop("Cannot find 'Estimate' column in coefficient table.")
  if (is.na(se_col))  stop("Cannot find standard error column in coefficient table.")
  if (is.na(t_col))   stop("Cannot find t/z statistic column in coefficient table.")
  if (is.na(p_col))   stop("Cannot find p-value column in coefficient table.")

  data.frame(
    term      = rownames(s),
    estimate  = as.numeric(s[, est_col]),
    std_error = as.numeric(s[, se_col]),
    t_stat    = as.numeric(s[, t_col]),
    p_two     = as.numeric(s[, p_col]),
    stringsAsFactors = FALSE,
    row.names = NULL
  )
}
