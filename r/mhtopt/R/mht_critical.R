#' Compute Optimal MHT Critical Values
#'
#' Compute optimal critical values for multiple hypothesis testing based on
#' Proposition 4.1 of Viviano, Wuthrich, and Niehaus (2026). The optimal
#' per-test significance level is \eqn{\alpha(J, \Sigma) = C(J, \Sigma) / (b \cdot \bar{\omega}(J))}.
#'
#' @param J Integer or \code{Inf}. Number of hypotheses being tested.
#'   Use \code{Inf} to obtain the limiting value as \eqn{|J| \to \infty}.
#' @param alpha_bar Numeric. Benchmark single-hypothesis test size (e.g., 0.05).
#' @param model Character. Cost model: \code{"linear"} (default) for the Linear
#'   model (Equation 27) or \code{"cobbdouglas"} for the Cobb-Douglas model
#'   (Appendix A).
#' @param cf_share Numeric. Fixed cost share for the Linear model. Default 0.46,
#'   based on Sertkaya et al. (2016).
#' @param J_bar Numeric. Average number of subgroups across trials (Linear model).
#'   Default 3, based on Pocock et al. (2002).
#' @param nm_ratio Numeric. Ratio of per-arm sample size to benchmark
#'   (\eqn{\bar{n}/\bar{m}}). Default 1.0.
#' @param beta Numeric. Elasticity of cost with respect to number of arms
#'   (Cobb-Douglas model). Default 0.13 (J-PAL estimate).
#' @param iota Numeric. Elasticity of cost with respect to sample size
#'   (Cobb-Douglas model). Default 0.075 (J-PAL estimate).
#'
#' @return A list of class \code{"mht_critical"} containing:
#'   \describe{
#'     \item{alpha_opt}{Optimal per-test significance level}
#'     \item{t_star}{Optimal z-threshold (critical value for one-sided test)}
#'     \item{alpha_bonf}{Bonferroni significance level (\eqn{\bar{\alpha}/|J|}); 0 when J = Inf}
#'     \item{t_bonf}{Bonferroni z-threshold}
#'     \item{alpha_sidak}{Sidak significance level \eqn{1-(1-\bar{\alpha})^{1/|J|}}; 0 when J = Inf}
#'     \item{t_sidak}{Sidak z-threshold}
#'     \item{alpha_bar}{Benchmark alpha}
#'     \item{J}{Number of hypotheses (may be Inf)}
#'     \item{nm_ratio}{Sample size ratio used}
#'     \item{model}{Cost model used}
#'   }
#'
#' @examples
#' # Linear calibration: 5 hypotheses, benchmark alpha = 0.05
#' mht_critical(J = 5, alpha_bar = 0.05)
#'
#' # Limiting case J -> Inf
#' mht_critical(J = Inf, alpha_bar = 0.025)
#'
#' # Cobb-Douglas (J-PAL calibration)
#' mht_critical(J = 5, alpha_bar = 0.05, model = "cobbdouglas",
#'              beta = 0.13, iota = 0.075)
#'
#' # Linear model with larger sample
#' mht_critical(J = 3, alpha_bar = 0.025, nm_ratio = 1.5)
#'
#' @references
#' Viviano, D., K. Wuthrich, and P. Niehaus (2026). A model of multiple
#' hypothesis testing. \emph{arXiv:2104.13367v10}.
#'
#' @export
mht_critical <- function(J, alpha_bar,
                         model = c("linear", "cobbdouglas"),
                         cf_share = 0.46,
                         J_bar = 3,
                         nm_ratio = 1.0,
                         beta = 0.13,
                         iota = 0.075) {

  model <- match.arg(model)

  # Input validation: allow J = Inf for the limiting case
  stopifnot(is.infinite(J) || J >= 1, alpha_bar > 0, alpha_bar < 1, nm_ratio > 0)

  if (model == "linear") {
    # Linear cost model (Equation 27 in v10)
    # alpha = abar * [(1 + ratio/J) / (1 + ratio) + (nm - 1) / (1 + ratio)]
    # As J -> Inf: multiplicity_adj -> 1 / (1 + ratio)
    # R's Inf arithmetic handles ratio/Inf = 0 automatically.
    ratio <- cf_share * J_bar / (1 - cf_share)
    multiplicity_adj <- (1 + ratio / J) / (1 + ratio)
    sample_adj <- (nm_ratio - 1) / (1 + ratio)
    alpha_opt <- alpha_bar * (multiplicity_adj + sample_adj)
  } else {
    # Cobb-Douglas model (Appendix A / J-PAL calibration)
    # As J -> Inf: J^(beta-1) -> 0 since beta < 1.
    # R's Inf arithmetic handles Inf^(negative) = 0 automatically.
    alpha_opt <- alpha_bar * J^(beta - 1) * nm_ratio^iota
  }

  # Clamp to valid range
  alpha_opt <- min(max(alpha_opt, 0), 1)

  # Compute z-thresholds
  t_star <- qnorm(1 - alpha_opt)

  # Bonferroni: abar / J  (-> 0 as J -> Inf; qnorm(1) = Inf)
  alpha_bonf <- alpha_bar / J
  t_bonf <- qnorm(1 - alpha_bonf)

  # Sidak: 1 - (1 - abar)^(1/J)  (-> 0 as J -> Inf)
  alpha_sidak <- 1 - (1 - alpha_bar)^(1 / J)
  t_sidak <- qnorm(1 - alpha_sidak)

  result <- list(
    alpha_opt   = alpha_opt,
    t_star      = t_star,
    alpha_bonf  = alpha_bonf,
    t_bonf      = t_bonf,
    alpha_sidak = alpha_sidak,
    t_sidak     = t_sidak,
    alpha_bar   = alpha_bar,
    J           = J,
    nm_ratio    = nm_ratio,
    model       = model
  )
  class(result) <- "mht_critical"
  result
}


#' @export
print.mht_critical <- function(x, ...) {
  J_label <- if (is.infinite(x$J)) "Inf" else sprintf("%d", as.integer(x$J))

  cat("\n")
  cat(strrep("-", 60), "\n")
  cat("  Optimal MHT Critical Values\n")
  cat("  Viviano, Wuthrich, and Niehaus (2026)\n")
  cat(strrep("-", 60), "\n\n")

  if (x$model == "linear") {
    cat("  Cost model:          Linear (Eq. 27)\n")
  } else {
    cat("  Cost model:          Cobb-Douglas (Appendix A)\n")
  }
  cat(sprintf("  Number of hypotheses: %s\n", J_label))
  cat(sprintf("  Benchmark alpha:      %.4f\n", x$alpha_bar))
  cat(sprintf("  Sample size ratio:    %.2f\n", x$nm_ratio))
  cat("\n")
  cat(strrep("-", 60), "\n")
  cat(sprintf("  Optimal test size:    %.6f\n", x$alpha_opt))
  cat(sprintf("  Optimal z-threshold:  %.4f\n", x$t_star))
  cat("\n")
  cat(sprintf("  Bonferroni size:      %.6f\n", x$alpha_bonf))
  cat(sprintf("  Bonferroni z-thresh:  %.4f\n", x$t_bonf))
  cat(sprintf("  Sidak size:           %.6f\n", x$alpha_sidak))
  cat(sprintf("  Sidak z-threshold:    %.4f\n", x$t_sidak))
  cat(sprintf("  Unadjusted size:      %.6f\n", x$alpha_bar))
  cat(strrep("-", 60), "\n\n")

  invisible(x)
}
