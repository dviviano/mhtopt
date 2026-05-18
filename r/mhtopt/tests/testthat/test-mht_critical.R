test_that("J=1 returns alpha_bar", {
  r <- mht_critical(J = 1, alpha_bar = 0.05)
  expect_equal(r$alpha_opt, 0.05, tolerance = 1e-10)
})

test_that("Linear: alpha_opt < alpha_bar for J>1", {
  r <- mht_critical(J = 5, alpha_bar = 0.05, model = "linear")
  expect_lt(r$alpha_opt, 0.05)
})

test_that("Linear: alpha_opt > alpha_bonf for J>1", {
  r <- mht_critical(J = 5, alpha_bar = 0.05, model = "linear")
  expect_gt(r$alpha_opt, r$alpha_bonf)
})

test_that("Linear: alpha decreases with J", {
  alphas <- sapply(1:10, function(j) mht_critical(j, 0.05, "linear")$alpha_opt)
  expect_true(all(diff(alphas) <= 0))
})

test_that("Cobb-Douglas beta=0 => Bonferroni", {
  r <- mht_critical(J = 5, alpha_bar = 0.05, model = "cobbdouglas", beta = 0, iota = 0)
  expect_equal(r$alpha_opt, 0.05 / 5, tolerance = 1e-10)
})

test_that("Cobb-Douglas beta=1 => no adjustment", {
  r <- mht_critical(J = 5, alpha_bar = 0.05, model = "cobbdouglas", beta = 1, iota = 0)
  expect_equal(r$alpha_opt, 0.05, tolerance = 1e-10)
})

test_that("Table 1 spot-check: J=5, alpha=0.05, nm=1 ~0.021", {
  r <- mht_critical(J = 5, alpha_bar = 0.05, model = "linear")
  expect_true(abs(r$alpha_opt - 0.021) < 0.002)
})

test_that("Larger nm_ratio => larger alpha_opt (Linear)", {
  a1 <- mht_critical(J = 5, alpha_bar = 0.05, nm_ratio = 0.5)$alpha_opt
  a2 <- mht_critical(J = 5, alpha_bar = 0.05, nm_ratio = 1.0)$alpha_opt
  a3 <- mht_critical(J = 5, alpha_bar = 0.05, nm_ratio = 2.0)$alpha_opt
  expect_lt(a1, a2)
  expect_lt(a2, a3)
})

test_that("J=Inf works (Linear)", {
  r <- mht_critical(J = Inf, alpha_bar = 0.025, model = "linear")
  expect_true(r$alpha_opt > 0)
  expect_true(r$alpha_opt < 0.025)
})

test_that("J=Inf works (Cobb-Douglas)", {
  r <- mht_critical(J = Inf, alpha_bar = 0.025, model = "cobbdouglas")
  expect_equal(r$alpha_opt, 0, tolerance = 1e-10)
})

test_that("Input validation: J=0 errors", {
  expect_error(mht_critical(J = 0, alpha_bar = 0.05))
})

test_that("Input validation: alpha_bar=0 errors", {
  expect_error(mht_critical(J = 5, alpha_bar = 0))
})

test_that("Numeric verification: Linear formula matches closed-form", {
  ratio <- 0.46 * 3 / (1 - 0.46)
  for (j in c(1, 3, 5, 9)) {
    expected <- 0.05 * (1 + ratio / j) / (1 + ratio)
    got <- mht_critical(J = j, alpha_bar = 0.05)$alpha_opt
    expect_equal(got, expected, tolerance = 1e-8,
                 label = sprintf("J=%d", j))
  }
})
