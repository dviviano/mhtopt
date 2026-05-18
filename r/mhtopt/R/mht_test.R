#' Perform Hypothesis Tests with Optimal MHT Adjustment
#'
#' Given p-values or test statistics, applies the model-optimal MHT adjustment
#' from Proposition 4.1 of Viviano, Wuthrich, and Niehaus (2026) and returns
#' rejection decisions compared across multiple procedures.
#'
#' @param p Numeric vector. One-sided p-values. Provide either \code{p} or \code{z}.
#' @param z Numeric vector. Z-statistics. If provided, p-values are computed as
#'   \code{1 - pnorm(z)}.
#' @param alpha_bar Numeric. Benchmark single-hypothesis test size.
#' @param model Character. Cost model: \code{"linear"} (default) or \code{"cobbdouglas"}.
#' @param cf_share Numeric. Fixed cost share (Linear model). Default 0.46.
#' @param J_bar Numeric. Average number of subgroups (Linear model). Default 3.
#' @param nm_ratio Numeric. Sample size ratio. Default 1.0.
#' @param beta Numeric. Arms elasticity (Cobb-Douglas). Default 0.13.
#' @param iota Numeric. Sample size elasticity (Cobb-Douglas). Default 0.075.
#'
#' @return A data frame of class \code{"mht_test"} with columns:
#'   \describe{
#'     \item{p_value}{Input p-values}
#'     \item{reject_optimal}{Rejection under the optimal model-based procedure}
#'     \item{reject_bonferroni}{Rejection under Bonferroni correction}
#'     \item{reject_holm}{Rejection under Holm's step-down procedure}
#'     \item{reject_bh}{Rejection under Benjamini-Hochberg (FDR) control}
#'     \item{reject_unadjusted}{Rejection without adjustment}
#'   }
#'   The object also carries attributes \code{alpha_opt}, \code{alpha_bonf},
#'   \code{alpha_bar}, \code{J}, and \code{model}.
#'
#' @examples
#' # Test with p-values
#' pvals <- c(0.003, 0.015, 0.030, 0.048, 0.120, 0.500)
#' result <- mht_test(p = pvals, alpha_bar = 0.05)
#' print(result)
#'
#' # Test with z-statistics
#' zstats <- qnorm(1 - pvals)
#' result2 <- mht_test(z = zstats, alpha_bar = 0.05)
#'
#' # Cobb-Douglas model
#' result3 <- mht_test(p = pvals, alpha_bar = 0.05, model = "cobbdouglas")
#'
#' @references
#' Viviano, D., K. Wuthrich, and P. Niehaus (2026). A model of multiple
#' hypothesis testing. \emph{arXiv:2104.13367v10}.
#'
#' @export
mht_test <- function(p = NULL, z = NULL,
                     alpha_bar,
                     model = c("linear", "cobbdouglas"),
                     cf_share = 0.46,
                     J_bar = 3,
                     nm_ratio = 1.0,
                     beta = 0.13,
                     iota = 0.075) {

  model <- match.arg(model)

  # Input validation
  if (is.null(p) && is.null(z)) {
    stop("Must provide either p-values (p) or z-statistics (z)")
  }
  if (!is.null(p) && !is.null(z)) {
    stop("Provide either p or z, not both")
  }

  # Convert z to p if needed
  if (!is.null(z)) {
    p <- 1 - pnorm(z)
  }

  J <- length(p)
  stopifnot(J >= 1, alpha_bar > 0, alpha_bar < 1)

  # Compute optimal critical value
  cv <- mht_critical(J = J, alpha_bar = alpha_bar, model = model,
                     cf_share = cf_share, J_bar = J_bar,
                     nm_ratio = nm_ratio, beta = beta, iota = iota)

  alpha_opt <- cv$alpha_opt
  alpha_bonf <- cv$alpha_bonf

  # 1. Optimal (model-based)
  reject_opt <- p <= alpha_opt

  # 2. Bonferroni
  reject_bonf <- p <= alpha_bonf

  # 3. Holm step-down
  reject_holm <- p.adjust(p, method = "holm") <= alpha_bar

  # 4. Benjamini-Hochberg
  reject_bh <- p.adjust(p, method = "BH") <= alpha_bar

  # 5. Unadjusted
  reject_unadj <- p <= alpha_bar

  result <- data.frame(
    p_value = p,
    reject_optimal = reject_opt,
    reject_bonferroni = reject_bonf,
    reject_holm = reject_holm,
    reject_bh = reject_bh,
    reject_unadjusted = reject_unadj
  )

  attr(result, "alpha_opt") <- alpha_opt
  attr(result, "alpha_bonf") <- alpha_bonf
  attr(result, "alpha_bar") <- alpha_bar
  attr(result, "J") <- J
  attr(result, "model") <- model
  class(result) <- c("mht_test", "data.frame")

  result
}


#' @export
print.mht_test <- function(x, ...) {
  J <- attr(x, "J")
  alpha_opt <- attr(x, "alpha_opt")
  alpha_bonf <- attr(x, "alpha_bonf")
  alpha_bar <- attr(x, "alpha_bar")
  model <- attr(x, "model")

  cat("\n")
  cat(strrep("-", 65), "\n")
  cat("  Multiple Hypothesis Testing Results\n")
  cat("  Viviano, Wuthrich, and Niehaus (2026)\n")
  cat(strrep("-", 65), "\n\n")

  model_name <- if (model == "linear") "Linear" else "Cobb-Douglas"
  cat(sprintf("  Hypotheses tested:    %d\n", J))
  cat(sprintf("  Benchmark alpha:      %.4f\n", alpha_bar))
  cat(sprintf("  Cost model:           %s\n\n", model_name))

  cat(strrep("-", 55), "\n")
  cat(sprintf("  %-24s %10s %12s\n", "Procedure", "Test size", "Rejections"))
  cat(strrep("-", 55), "\n")
  cat(sprintf("  %-24s %10.6f %12d\n", "Optimal (model-based)", alpha_opt, sum(x$reject_optimal)))
  cat(sprintf("  %-24s %10.6f %12d\n", "Bonferroni", alpha_bonf, sum(x$reject_bonferroni)))
  cat(sprintf("  %-24s %10s %12d\n", "Holm (step-down)", paste0(format(alpha_bar, nsmall=4), " *"), sum(x$reject_holm)))
  cat(sprintf("  %-24s %10s %12d\n", "BH (FDR control)", paste0(format(alpha_bar, nsmall=4), " *"), sum(x$reject_bh)))
  cat(sprintf("  %-24s %10.6f %12d\n", "Unadjusted", alpha_bar, sum(x$reject_unadjusted)))
  cat(strrep("-", 55), "\n")
  cat("  * Step-wise; effective threshold varies by rank\n\n")

  cat("  Detailed results:\n")
  print.data.frame(x, row.names = FALSE)
  cat("\n")

  invisible(x)
}
