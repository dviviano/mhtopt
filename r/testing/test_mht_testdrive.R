# ============================================================================
# MHT Test Drive: Banerjee et al. (Science 2015)
# Viviano, Wuthrich, and Niehaus (2026), "A Model of Multiple Hypothesis Testing"
#
# One outcome x J=6 country arms (reproduces results_note.pdf):
#   Pooled 6-country regression, treatment x country, J=6 hypotheses.
#   With expensive per-arm costs, the VWN correction is mild and can RETAIN
#   country effects that BH's step-up rule discards.
#
# REQUIREMENTS: haven (for reading .dta files)
# Data: top-level testing/data/ (see testing/README.md; DOI 10.7910/DVN/NHIXNT)
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
# One outcome x 6 country arms (J=6)
# ============================================================================
cat("\n\n")
cat(strrep("=", 50), "\n")
cat("  One outcome x 6 country arms (J=6)\n")
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

  cat("\n  Study-specific (cf_share=0.23, J_bar=6, countries are expensive):\n")
  r2 <- mht_est(fit, vars = treat_vars, alpha_bar = alpha_bar, cf_share = 0.23, J_bar = 6)
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
cat("  SUMMARY: One outcome x 6 country arms\n")
cat(strrep("=", 50), "\n\n")
cat("  Cost structure: adding a country arm is EXPENSIVE (cf_share ~ 0.10-0.23)\n")
cat("    => Minimal correction needed (alpha* ~ 0.02-0.04, near unadjusted)\n")
cat("    => VWN-Lin retains country effects that BH's step-up rule discards\n\n")
cat("  Correction cuts both ways: it can remove marginally-significant results\n")
cat("  or restore ones that FDR procedures discard. See results_note.pdf.\n\n")
cat("Done.\n")
