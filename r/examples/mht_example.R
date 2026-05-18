# ============================================================================
# mhtopt -- Complete Example (R)
# Viviano, Wüthrich, and Niehaus (2026)
# ============================================================================
# Demonstrates all five package functions using built-in and simulated data.
# No external data files needed.
#
# To run: install.packages("mhtopt") then source this file. For development
# use, the script will fall back to sourcing R/ from a sibling mhtopt/
# directory if the installed package is not available.
# ============================================================================

# --- Load the package (with dev fallback) ---
if (requireNamespace("mhtopt", quietly = TRUE)) {
  library(mhtopt)
} else {
  # Development fallback: source from r/mhtopt/R/
  candidates <- c("mhtopt/R", "../mhtopt/R", "../../r/mhtopt/R", "r/mhtopt/R")
  src_dir <- NULL
  for (p in candidates) {
    if (dir.exists(p) && file.exists(file.path(p, "mht_critical.R"))) {
      src_dir <- p; break
    }
  }
  if (is.null(src_dir)) {
    stop("mhtopt not installed. Run install.packages('mhtopt') ",
         "or run this script from the package root.")
  }
  for (f in list.files(src_dir, pattern = "[.]R$", full.names = TRUE)) source(f)
}

cat("\n")
cat(strrep("=", 70), "\n")
cat("  MHT Package for R -- Complete Example\n")
cat("  Viviano, Wuthrich, and Niehaus (2026)\n")
cat(strrep("=", 70), "\n\n")

# --------------------------------------------------------------------------
# 1. mht_critical: Compute optimal critical values
# --------------------------------------------------------------------------
cat("--- 1. mht_critical ---\n\n")

# Linear model (default): 5 hypotheses, benchmark alpha = 0.05
cat("Linear model, J=5, alpha_bar=0.05:\n")
r1 <- mht_critical(J = 5, alpha_bar = 0.05)
print(r1)

# Cobb-Douglas model
cat("Cobb-Douglas model, J=5, alpha_bar=0.05:\n")
r2 <- mht_critical(J = 5, alpha_bar = 0.05, model = "cobbdouglas")
print(r2)

# Larger sample (n/m = 1.5)
cat("Linear model, J=5, alpha_bar=0.05, nm_ratio=1.5:\n")
r3 <- mht_critical(J = 5, alpha_bar = 0.05, nm_ratio = 1.5)
print(r3)

# --------------------------------------------------------------------------
# 2. mht_test: Test p-values directly
# --------------------------------------------------------------------------
cat("--- 2. mht_test ---\n\n")

pvals <- c(0.003, 0.015, 0.030, 0.048, 0.120, 0.500)
cat("Testing 6 p-values: ", paste(pvals, collapse = ", "), "\n\n")

result <- mht_test(p = pvals, alpha_bar = 0.05)
print(result)

# Same test with Cobb-Douglas
cat("Same p-values, Cobb-Douglas model:\n")
result_cd <- mht_test(p = pvals, alpha_bar = 0.05, model = "cobbdouglas")
print(result_cd)

# --------------------------------------------------------------------------
# 3. mht_est: Postestimation after a regression
# --------------------------------------------------------------------------
cat("--- 3. mht_est ---\n\n")

# Simulate an RCT with 4 treatment arms
set.seed(123)
n <- 500
data_rct <- data.frame(
  treat1 = rbinom(n, 1, 0.2),
  treat2 = rbinom(n, 1, 0.2),
  treat3 = rbinom(n, 1, 0.2),
  treat4 = rbinom(n, 1, 0.2),
  x1 = rnorm(n),
  x2 = rnorm(n)
)
data_rct$y <- 0.3 * data_rct$treat1 + 0.1 * data_rct$treat2 +
              0.0 * data_rct$treat3 - 0.05 * data_rct$treat4 +
              0.5 * data_rct$x1 + rnorm(n)

fit <- lm(y ~ treat1 + treat2 + treat3 + treat4 + x1 + x2, data = data_rct)
cat("Regression: y ~ treat1 + treat2 + treat3 + treat4 + x1 + x2\n")
cat("Testing 4 treatment coefficients:\n\n")

mht_result <- mht_est(fit, vars = c("treat1", "treat2", "treat3", "treat4"),
                      alpha_bar = 0.05)
print(mht_result)

# With mbar option (benchmark per-arm sample size)
cat("Same regression, with mbar=200 (benchmark per-arm sample size):\n\n")
mht_mbar <- mht_est(fit, vars = c("treat1", "treat2", "treat3", "treat4"),
                    alpha_bar = 0.05, mbar = 200)
print(mht_mbar)

# --------------------------------------------------------------------------
# 4. mht_table: Generate reference tables
# --------------------------------------------------------------------------
cat("--- 4. mht_table ---\n\n")

# Default: reproduces Table 1 of the paper
cat("Table 1 (Linear model, default parameters):\n\n")
tbl <- mht_table()
print(tbl)

# Cobb-Douglas version
cat("Cobb-Douglas table:\n\n")
tbl_cd <- mht_table(model = "cobbdouglas", alpha_bar = c(0.025, 0.05),
                    J_range = c(1:9, Inf), nm_ratios = c(0.5, 1.0, 1.5, 2.0))
print(tbl_cd)

# --------------------------------------------------------------------------
# 5. mht_cost_estimate: Estimate cost parameters from data
# --------------------------------------------------------------------------
cat("--- 5. mht_cost_estimate ---\n\n")

# Simulate project-level cost data (mimicking J-PAL structure)
set.seed(42)
n_projects <- 300
arms_data <- sample(1:5, n_projects, replace = TRUE)
ss_data <- sample(500:5000, n_projects, replace = TRUE)
cost_data <- exp(10 + 0.2 * log(arms_data) + 0.15 * log(ss_data) +
                 rnorm(n_projects, 0, 0.4))

cat("Estimating Cobb-Douglas cost function from 300 simulated projects:\n\n")
est <- mht_cost_estimate(cost_data, arms_data, ss_data, alpha_bar = 0.05)
print(est)

# Use estimated parameters to compute critical values
cat("Using estimated parameters for critical values (J=5):\n")
r_est <- mht_critical(J = 5, alpha_bar = 0.05, model = "cobbdouglas",
                      beta = est$beta, iota = est$iota)
print(r_est)

cat(strrep("=", 70), "\n")
cat("  Example complete.\n")
cat(strrep("=", 70), "\n")
