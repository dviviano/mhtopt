# ============================================================================
# MHT Test Drive: Banerjee et al. (Science 2015)
# Viviano, Wuthrich, and Niehaus (2026), "A Model of Multiple Hypothesis Testing"
#
# REFERENCE RESULTS IN BANERJEE ET AL.:
#   Table 3: Pooled treatment effects on 10 indexed outcome families, with
#            BH q-values (column 2) for all 10 hypotheses jointly.
#   Figure 3: Country-specific treatment effects at endline 2.
#   Table 4: Cost-benefit analysis with per-country cost breakdowns.
#
# VERSION A: India arm, 10 outcomes (mht_test)
#   Question: Which of the 10 outcome results survive economically-grounded MHT?
#
# VERSION B: Pooled 6-country, treatment x country (mht_est)
#   Question: Which country-specific effects survive when treating 6 programs
#             as 6 distinct treatments?
#
# REQUIREMENTS: haven (for reading .dta files)
# ============================================================================

# --- Setup ---
library(haven)

# Auto-detect package root (the r/ directory containing mhtopt/R/)
if (file.exists("mhtopt/R/mht_critical.R")) {          # run from r/
  root <- getwd()
} else if (file.exists("../mhtopt/R/mht_critical.R")) { # run from r/testing/
  root <- normalizePath("..")
} else {
  stop("Please run from the r/ directory or r/testing/")
}

# Source package functions
for (f in list.files(file.path(root, "mhtopt/R"), full.names = TRUE, pattern = "\\.R$")) {
  source(f)
}

# Shared validation data lives at the repo's top-level testing/data/
dta_path <- file.path(root, "..", "testing/data")

cat("\n")
cat(strrep("=", 70), "\n")
cat("  MHT Test Drive: Banerjee et al. (Science 2015)\n")
cat("  Viviano, Wuthrich, and Niehaus (2026)\n")
cat(strrep("=", 70), "\n")

# ============================================================================
# Reference table (cf. Table 1 in VWN 2026)
# ============================================================================
cat("\n--- Reference table ---\n\n")
tbl <- mht_table(alpha_bar = 0.05, J_range = c(1, 2, 3, 5, 6, 10),
                 nm_ratios = c(0.5, 1.0, 2.0))
print(tbl)

# ============================================================================
# VERSION A: Heterogeneous Audience -- 10 Outcomes, India
# ============================================================================
cat("\n")
cat(strrep("=", 50), "\n")
cat("  VERSION A: 10 Outcomes, India\n")
cat("  Reference: Table 3, Banerjee et al. (2015)\n")
cat(strrep("=", 50), "\n\n")

# --- Data prep: run 10 regressions, collect p-values ---
hh_outcomes <- c("index_ctotal", "ind_increv", "asset_index",
                 "index_foodsecurity", "ind_fin")
mb_outcomes <- c("index_time", "index_health", "index_mental",
                 "index_political", "index_women")
outcome_labels <- c("Consumption", "Income", "Assets", "FoodSec", "Finance",
                    "TimeUse", "PhysHealth", "MentHealth", "Political", "WomenEmp")

# HH-level outcomes
hh_data <- read_dta(file.path(dta_path, "index_hh_vars.dta"))
hh_data <- hh_data[hh_data$country == 4, ]

# MB-level outcomes
mb_data <- read_dta(file.path(dta_path, "index_mb_vars.dta"))
mb_data <- mb_data[mb_data$country == 4, ]

# Collect p-values from regressions
# (simplified: OLS with available controls, mirroring the Stata approach)
collect_pvals <- function(data, outcomes) {
  results <- list()
  control_cols <- grep("^control_", names(data), value = TRUE)

  for (var in outcomes) {
    end_var <- paste0(var, "_end")
    bsl_var <- paste0(var, "_bsl")
    m_bsl <- paste0("m_", var, "_bsl")
    m_country_bsl <- paste0("m_country_", var, "_bsl")

    # Ensure baseline vars exist (set to 0 if missing)
    for (aux in c(bsl_var, m_bsl, m_country_bsl)) {
      if (!aux %in% names(data)) data[[aux]] <- 0
    }

    # Build formula: end ~ treatment + baseline + controls
    rhs_vars <- c("treatment", bsl_var, m_bsl, m_country_bsl, control_cols)
    rhs_vars <- rhs_vars[rhs_vars %in% names(data)]
    fml <- as.formula(paste(end_var, "~", paste(rhs_vars, collapse = " + ")))

    fit <- lm(fml, data = data)
    s <- coef(summary(fit))

    coef_val <- s["treatment", "Estimate"]
    se_val <- s["treatment", "Std. Error"]
    t_val <- coef_val / se_val

    # One-sided p-value (positive direction)
    if (t_val >= 0) {
      p_one <- 1 - pnorm(t_val)
    } else {
      p_one <- 1 - (1 - pnorm(abs(t_val))) / 2
    }

    results[[var]] <- data.frame(
      outcome = var, coef = coef_val, se = se_val,
      t_stat = t_val, p_value = p_one
    )
  }
  do.call(rbind, results)
}

hh_results <- collect_pvals(hh_data, hh_outcomes)
mb_results <- collect_pvals(mb_data, mb_outcomes)
all_results <- rbind(hh_results, mb_results)
all_results$label <- outcome_labels
rownames(all_results) <- NULL

cat("Regression summary (India, treatment coefficient, one-sided p):\n")
print(all_results[, c("label", "coef", "se", "t_stat", "p_value")], row.names = FALSE)

# --- mht_test: Linear model (FDA calibration) ---
cat("\n--- mht_test: Linear model (cf_share=0.46), alpha_bar=0.05 ---\n\n")
result_linear <- mht_test(p = all_results$p_value, alpha_bar = 0.05)
print(result_linear)

# --- mht_test: Cobb-Douglas model ---
cat("\n--- mht_test: Cobb-Douglas (beta=0.13, iota=0.075) ---\n\n")
result_cd <- mht_test(p = all_results$p_value, alpha_bar = 0.05, model = "cobbdouglas")
print(result_cd)

# --- Comparison ---
cat("\n--- Comparison with Banerjee et al. Table 3 ---\n")
cat("  Paper uses BH q-values (FDR control) on pooled 6-country sample.\n")
cat("  Our analysis: India only, with cost-based optimal correction.\n\n")
cat("  Paper Table 3 q-values (endline 1, pooled):\n")
cat("    Most indices: q = 0.001  => significant under BH\n")
cat("    Physical health: q = 0.078 => NOT significant at 5% under BH\n")
cat("    Women's empowerment: q = 0.049 => borderline under BH\n\n")

# --- Study-specific calibration ---
cat("\n--- Study-specific calibration (Table 4 cost data) ---\n")
cat("  From Table 4 (India): program+overhead ~$1,268, survey ~$100-150\n")
cat("  => cf_share_outcomes ~ 0.80-0.90 (most costs fixed w.r.t. outcomes)\n\n")

J <- 10
for (cf in c(0.46, 0.75, 0.82, 0.90)) {
  r <- mht_critical(J = J, alpha_bar = 0.05, cf_share = cf)
  cat(sprintf("  cf_share=%.2f: alpha* = %.5f\n", cf, r$alpha_opt))
}
cat(sprintf("  Bonferroni:     alpha* = %.5f\n", 0.05 / J))


# ============================================================================
# VERSION B: Multiple Treatments -- 6 Countries as 6 Programs
# ============================================================================
cat("\n\n")
cat(strrep("=", 50), "\n")
cat("  VERSION B: 6 Countries as 6 Treatments\n")
cat("  Reference: Figure 3, Table 4, Banerjee et al. (2015)\n")
cat(strrep("=", 50), "\n\n")

# Load pooled data and create country-treatment indicators
hh_all <- read_dta(file.path(dta_path, "index_hh_vars.dta"))

for (c in 1:6) {
  hh_all[[paste0("treat_c", c)]] <- as.numeric(hh_all$treatment == 1 & hh_all$country == c)
}

treat_vars <- paste0("treat_c", 1:6)
control_cols <- grep("^control_", names(hh_all), value = TRUE)

# Function to run country-treatment regression and apply mht_est
run_country_mht <- function(data, outcome_var, label, alpha_bar = 0.05) {
  end_var <- paste0(outcome_var, "_end")
  bsl_var <- paste0(outcome_var, "_bsl")
  m_bsl <- paste0("m_", outcome_var, "_bsl")

  for (aux in c(bsl_var, m_bsl)) {
    if (!aux %in% names(data)) data[[aux]] <- 0
  }

  rhs_vars <- c(treat_vars, bsl_var, m_bsl, control_cols)
  rhs_vars <- rhs_vars[rhs_vars %in% names(data)]
  fml <- as.formula(paste(end_var, "~", paste(rhs_vars, collapse = " + ")))

  fit <- lm(fml, data = data)

  cat(sprintf("\n--- %s: 6 country-specific treatments ---\n", label))
  cat("    (1=Ethiopia, 2=Ghana, 3=Honduras, 4=India, 5=Pakistan, 6=Peru)\n\n")

  cat("  FDA default (cf_share=0.46):\n")
  r1 <- mht_est(fit, vars = treat_vars, alpha_bar = alpha_bar)
  print(r1)

  cat("\n  Study-specific (cf_share=0.10, countries are expensive):\n")
  r2 <- mht_est(fit, vars = treat_vars, alpha_bar = alpha_bar, cf_share = 0.10)
  print(r2)
}

run_country_mht(hh_all, "index_ctotal", "Consumption")
run_country_mht(hh_all, "ind_increv", "Income & revenues")
run_country_mht(hh_all, "asset_index", "Assets")
run_country_mht(hh_all, "index_foodsecurity", "Food security")
run_country_mht(hh_all, "ind_fin", "Financial inclusion")


# ============================================================================
# Summary
# ============================================================================
cat("\n\n")
cat(strrep("=", 50), "\n")
cat("  SUMMARY: Version A vs Version B\n")
cat(strrep("=", 50), "\n\n")
cat("  Version A (10 outcomes, India):\n")
cat("    Cost structure: adding outcomes is CHEAP (cf_share ~ 0.82)\n")
cat("    => Strict correction needed (alpha* ~ 0.008, near Bonferroni)\n")
cat("    => Confirms 5 core results; physical health is borderline\n\n")
cat("  Version B (6 countries, pooled):\n")
cat("    Cost structure: adding a country is EXPENSIVE (cf_share ~ 0.10)\n")
cat("    => Minimal correction needed (alpha* ~ 0.040, near unadjusted)\n")
cat("    => Retains effects that Bonferroni would discard\n\n")
cat("  Same data, two framings, opposite corrections.\n")
cat("  This is the core insight of VWN (2026).\n\n")
cat("Done.\n")
