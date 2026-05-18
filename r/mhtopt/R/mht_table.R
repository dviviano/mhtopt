#' Generate Table of Optimal Critical Values
#'
#' Generates a table of optimal critical values for a range of hypothesis counts
#' and sample size ratios, reproducing Table 1 in Viviano, Wuthrich, and Niehaus
#' (2026) (linear calibration) or the J-PAL Cobb-Douglas calibration.
#'
#' The default arguments reproduce Table 1 of the paper exactly: rows for
#' \eqn{|J| = 1, \ldots, 9, \infty}, four \eqn{\bar\alpha} columns at
#' \eqn{\bar n/\bar m = 100\%}, single-column groups at 50\%, 150\%, and 200\%
#' (all with \eqn{\bar\alpha = 0.025}), and Sidak benchmark columns for
#' \eqn{\bar\alpha \in \{0.025, 0.05\}}.
#'
#' @param alpha_bar Numeric vector. Benchmark single-hypothesis sizes for the
#'   optimal columns. Default \code{c(0.025, 0.05, 0.1, 0.15)}.
#' @param J_range Numeric vector. Hypothesis counts (rows). May include
#'   \code{Inf} for the limiting \eqn{|J| \to \infty} row.
#'   Default \code{c(1:9, Inf)}.
#' @param nm_ratios Numeric vector. Sample size ratios \eqn{\bar n / \bar m}.
#'   Default \code{c(0.5, 1.0, 1.5, 2.0)}.
#' @param sidak_bars Numeric vector. \eqn{\bar\alpha} values for Sidak benchmark
#'   columns, appended after the optimal columns. Set to \code{NULL} to suppress.
#'   Default \code{c(0.025, 0.05)}, matching Table 1 of the paper.
#' @param model Character. Cost model: \code{"linear"} or \code{"cobbdouglas"}.
#' @param ... Additional arguments passed to \code{\link{mht_critical}}.
#'
#' @return A data frame (class \code{"mht_table"}) with columns:
#'   \itemize{
#'     \item \code{J}: hypothesis count (may include \code{Inf})
#'     \item \code{a<ab>_nm<nm>}: optimal alpha for each (alpha_bar, nm_ratio) pair
#'     \item \code{sidak_<ab>}: Sidak level for each sidak_bars value
#'   }
#'
#' @examples
#' # Reproduce Table 1 exactly (v10)
#' mht_table()
#'
#' # Cobb-Douglas with J-PAL parameters, no Sidak columns
#' mht_table(model = "cobbdouglas", beta = 0.13, iota = 0.075, sidak_bars = NULL)
#'
#' # Custom range, single alpha
#' mht_table(alpha_bar = 0.05, J_range = 1:20, nm_ratios = 1.0, sidak_bars = NULL)
#'
#' @references
#' Viviano, D., Wuthrich, K., and Niehaus, P. (2026). "A Model of Multiple
#' Hypothesis Testing." arXiv:2104.13367v10. \url{https://arxiv.org/abs/2104.13367}
#'
#' @export
mht_table <- function(alpha_bar  = c(0.025, 0.05, 0.1, 0.15),
                      J_range    = c(1:9, Inf),
                      nm_ratios  = c(0.5, 1.0, 1.5, 2.0),
                      sidak_bars = c(0.025, 0.05),
                      model      = c("linear", "cobbdouglas"),
                      ...) {

  model <- match.arg(model)

  # Build results data frame
  results <- data.frame(J = J_range)

  # Optimal critical value columns
  for (nm in nm_ratios) {
    for (ab in alpha_bar) {
      col_name <- sprintf("a%.3f_nm%.1f", ab, nm)
      results[[col_name]] <- sapply(J_range, function(j) {
        mht_critical(J = j, alpha_bar = ab, model = model,
                     nm_ratio = nm, ...)$alpha_opt
      })
    }
  }

  # Sidak benchmark columns (independent of cost model / nm_ratio)
  if (!is.null(sidak_bars) && length(sidak_bars) > 0) {
    for (ab in sidak_bars) {
      col_name <- sprintf("sidak_%.3f", ab)
      results[[col_name]] <- sapply(J_range, function(j) {
        1 - (1 - ab)^(1 / j)   # = 0 when j = Inf
      })
    }
  }

  class(results) <- c("mht_table", "data.frame")
  attr(results, "alpha_bar")  <- alpha_bar
  attr(results, "nm_ratios")  <- nm_ratios
  attr(results, "sidak_bars") <- sidak_bars
  attr(results, "model")      <- model
  results
}


#' @export
print.mht_table <- function(x, digits = 3, ...) {
  alpha_bar  <- attr(x, "alpha_bar")
  nm_ratios  <- attr(x, "nm_ratios")
  sidak_bars <- attr(x, "sidak_bars")
  model      <- attr(x, "model")

  model_name <- if (model == "linear") "Linear (Eq. 27)" else "Cobb-Douglas"

  # J labels: integer or "Inf" (avoid as.integer(Inf) coercion warning)
  J_labels <- vapply(x$J,
                     function(j) if (is.infinite(j)) "Inf" else as.character(as.integer(j)),
                     character(1))

  # Column width helpers
  fmt_val <- function(v) formatC(v, format = "f", digits = digits, width = digits + 3)

  n_nm  <- length(nm_ratios)
  n_ab  <- length(alpha_bar)
  n_sid <- if (is.null(sidak_bars)) 0L else length(sidak_bars)

  col_width  <- digits + 4   # e.g. "0.025" at digits=3
  total_cols <- n_nm * n_ab + n_sid
  rule_width <- 6 + total_cols * col_width + (total_cols - 1)

  cat("\n")
  cat(strrep("=", rule_width), "\n")
  cat(sprintf("  Optimal Critical Values (%s model)\n", model_name))
  cat("  Viviano, Wuthrich, and Niehaus (2026)\n")
  cat(strrep("=", rule_width), "\n\n")

  # --- Build header ---
  # Group labels line
  grp_line <- sprintf("  %3s", "")
  for (nm in nm_ratios) {
    grp <- sprintf("n/m=%.0f%%", nm * 100)
    cell_block <- n_ab * col_width + (n_ab - 1)
    grp_line <- paste0(grp_line, " ",
                       formatC(grp, width = cell_block, flag = "-"))
  }
  if (n_sid > 0) {
    sid_grp   <- "Sidak"
    cell_block <- n_sid * col_width + (n_sid - 1)
    grp_line  <- paste0(grp_line, " ",
                        formatC(sid_grp, width = cell_block, flag = "-"))
  }
  cat(grp_line, "\n")

  # Sub-header: alpha_bar labels per group
  sub_line <- sprintf("  %3s", "|J|")
  for (nm in nm_ratios) {
    for (ab in alpha_bar) {
      sub_line <- paste0(sub_line, " ", formatC(sprintf("a=%.3f", ab),
                                                width = col_width, flag = "-"))
    }
  }
  if (n_sid > 0) {
    for (ab in sidak_bars) {
      sub_line <- paste0(sub_line, " ",
                         formatC(sprintf("a=%.3f", ab),
                                 width = col_width, flag = "-"))
    }
  }
  cat(strrep("-", rule_width), "\n")
  cat(sub_line, "\n")
  cat(strrep("-", rule_width), "\n")

  # --- Data rows ---
  for (i in seq_len(nrow(x))) {
    row_str <- sprintf("  %3s", J_labels[i])
    for (nm in nm_ratios) {
      for (ab in alpha_bar) {
        col_name <- sprintf("a%.3f_nm%.1f", ab, nm)
        row_str  <- paste0(row_str, " ", fmt_val(x[[col_name]][i]))
      }
    }
    if (n_sid > 0) {
      for (ab in sidak_bars) {
        col_name <- sprintf("sidak_%.3f", ab)
        row_str  <- paste0(row_str, " ", fmt_val(x[[col_name]][i]))
      }
    }
    cat(row_str, "\n")
  }

  cat(strrep("-", rule_width), "\n\n")
  invisible(x)
}
