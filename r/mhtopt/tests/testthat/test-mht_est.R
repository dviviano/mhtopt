data(mtcars)
fit_lm <- lm(mpg ~ cyl + hp + wt + am, data = mtcars)

test_that("mht_est returns data.frame", {
  r <- mht_est(fit_lm, vars = c("cyl", "hp", "wt", "am"), alpha_bar = 0.05)
  expect_true(is.data.frame(r))
})

test_that("mht_est has correct columns", {
  r <- mht_est(fit_lm, vars = c("cyl", "hp", "wt", "am"), alpha_bar = 0.05)
  expect_true(all(c("term", "estimate", "std_error", "t_stat", "p_value",
                    "reject_optimal", "reject_bonferroni", "reject_holm",
                    "reject_bh", "reject_unadjusted") %in% names(r)))
})

test_that("mht_est preserves variable names", {
  r <- mht_est(fit_lm, vars = c("cyl", "hp", "wt", "am"), alpha_bar = 0.05)
  expect_identical(r$term, c("cyl", "hp", "wt", "am"))
})

test_that("mht_est: J=4 in attrs", {
  r <- mht_est(fit_lm, vars = c("cyl", "hp", "wt", "am"), alpha_bar = 0.05)
  expect_equal(attr(r, "J"), 4)
})

test_that("mht_est: onesided TRUE default (negative t -> high p)", {
  r <- mht_est(fit_lm, vars = c("cyl", "hp", "wt", "am"), alpha_bar = 0.05)
  neg_t <- r$t_stat < 0
  if (any(neg_t)) {
    expect_true(all(r$p_value[neg_t] > 0.5))
  }
})

test_that("mht_est: twosided gives valid p-values", {
  r <- mht_est(fit_lm, vars = c("cyl", "hp", "wt"), alpha_bar = 0.05, onesided = FALSE)
  expect_true(all(r$p_value > 0 & r$p_value <= 1))
})

test_that("mht_est: missing var gives error", {
  expect_error(mht_est(fit_lm, vars = c("cyl", "NOTAVAR"), alpha_bar = 0.05))
})

test_that("mht_est: NULL vars excludes intercept", {
  r <- mht_est(fit_lm, vars = NULL, alpha_bar = 0.05)
  expect_false("(Intercept)" %in% r$term)
  expect_equal(nrow(r), 4)
})

test_that("mht_est: Cobb-Douglas model works", {
  r <- mht_est(fit_lm, vars = c("cyl", "hp", "wt", "am"),
               alpha_bar = 0.05, model = "cobbdouglas")
  expect_equal(attr(r, "model"), "cobbdouglas")
})

test_that("mht_est works with glm", {
  fit_g <- glm(am ~ mpg + wt + hp, data = mtcars, family = binomial)
  r <- mht_est(fit_g, vars = c("mpg", "wt", "hp"), alpha_bar = 0.05)
  expect_equal(nrow(r), 3)
})

test_that("mht_est: mbar changes alpha_opt vs default nm_ratio=1", {
  r_default <- mht_est(fit_lm, vars = c("cyl", "hp", "wt", "am"), alpha_bar = 0.05)
  r_mbar <- mht_est(fit_lm, vars = c("cyl", "hp", "wt", "am"), alpha_bar = 0.05,
                    mbar = 50)
  # mbar=50, nobs=32, J=4 => nm_ratio = (32/4)/50 = 0.16 < 1 => more conservative
  expect_lt(attr(r_mbar, "alpha_opt"), attr(r_default, "alpha_opt"))
})

test_that("mht_est: larger study (small mbar) gives larger alpha_opt", {
  r_small <- mht_est(fit_lm, vars = c("cyl", "hp"), alpha_bar = 0.05, mbar = 1000)
  r_large <- mht_est(fit_lm, vars = c("cyl", "hp"), alpha_bar = 0.05, mbar = 10)
  expect_gt(attr(r_large, "alpha_opt"), attr(r_small, "alpha_opt"))
})
