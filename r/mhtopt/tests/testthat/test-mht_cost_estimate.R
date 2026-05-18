test_that("Cobb-Douglas recovers beta approx 0.2", {
  set.seed(42)
  n <- 300
  arms_sim <- sample(1:5, n, replace = TRUE)
  ss_sim <- sample(500:5000, n, replace = TRUE)
  cost_sim <- exp(10 + 0.2 * log(arms_sim) + 0.15 * log(ss_sim) + rnorm(n, 0, 0.4))
  est <- mht_cost_estimate(cost_sim, arms_sim, ss_sim, alpha_bar = 0.05)
  expect_equal(est$beta, 0.2, tolerance = 0.1)
})

test_that("Cobb-Douglas recovers iota approx 0.15", {
  set.seed(42)
  n <- 300
  arms_sim <- sample(1:5, n, replace = TRUE)
  ss_sim <- sample(500:5000, n, replace = TRUE)
  cost_sim <- exp(10 + 0.2 * log(arms_sim) + 0.15 * log(ss_sim) + rnorm(n, 0, 0.4))
  est <- mht_cost_estimate(cost_sim, arms_sim, ss_sim, alpha_bar = 0.05)
  expect_equal(est$iota, 0.15, tolerance = 0.1)
})

test_that("Linear share estimation runs and returns valid share", {
  set.seed(42)
  n <- 300
  arms_sim <- sample(1:5, n, replace = TRUE)
  ss_sim <- sample(500:5000, n, replace = TRUE)
  cost_lin <- 50000 + 10 * arms_sim * ss_sim + rnorm(n, 0, 5000)
  est <- mht_cost_estimate(cost_lin, arms_sim, ss_sim, alpha_bar = 0.05,
                           model = "linear_share")
  expect_gt(est$cf_share, 0)
  expect_lt(est$cf_share, 1)
})

test_that("beta significantly different from 0", {
  set.seed(42)
  n <- 300
  arms_sim <- sample(1:5, n, replace = TRUE)
  ss_sim <- sample(500:5000, n, replace = TRUE)
  cost_sim <- exp(10 + 0.2 * log(arms_sim) + 0.15 * log(ss_sim) + rnorm(n, 0, 0.4))
  est <- mht_cost_estimate(cost_sim, arms_sim, ss_sim, alpha_bar = 0.05)
  expect_lt(est$p_beta0, 0.05)
})
