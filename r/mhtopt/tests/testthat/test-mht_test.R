pvals <- c(0.003, 0.015, 0.030, 0.048, 0.120, 0.500)

test_that("returns mht_test class", {
  r <- mht_test(p = pvals, alpha_bar = 0.05)
  expect_s3_class(r, "mht_test")
})

test_that("has correct columns", {
  r <- mht_test(p = pvals, alpha_bar = 0.05)
  expect_true(all(c("p_value", "reject_optimal", "reject_bonferroni",
                    "reject_holm", "reject_bh", "reject_unadjusted") %in% names(r)))
})

test_that("z-stats give same result as p-values", {
  zs <- qnorm(1 - pvals)
  r1 <- mht_test(p = pvals, alpha_bar = 0.05)
  r2 <- mht_test(z = zs, alpha_bar = 0.05)
  expect_identical(r1$reject_optimal, r2$reject_optimal)
})

test_that("optimal >= bonferroni rejections", {
  r <- mht_test(p = pvals, alpha_bar = 0.05)
  expect_gte(sum(r$reject_optimal), sum(r$reject_bonferroni))
})

test_that("optimal <= unadjusted rejections", {
  r <- mht_test(p = pvals, alpha_bar = 0.05)
  expect_lte(sum(r$reject_optimal), sum(r$reject_unadjusted))
})

test_that("all tiny p-values rejected by all methods", {
  r <- mht_test(p = c(0.001, 0.001, 0.001), alpha_bar = 0.05)
  expect_true(all(r$reject_optimal))
  expect_true(all(r$reject_bonferroni))
})

test_that("all large p-values not rejected by any method", {
  r <- mht_test(p = c(0.5, 0.6, 0.7), alpha_bar = 0.05)
  expect_false(any(r$reject_optimal))
  expect_false(any(r$reject_bonferroni))
  expect_false(any(r$reject_unadjusted))
})

test_that("Holm >= Bonferroni, BH >= Holm in rejections", {
  r <- mht_test(p = pvals, alpha_bar = 0.05)
  expect_gte(sum(r$reject_holm), sum(r$reject_bonferroni))
  expect_gte(sum(r$reject_bh), sum(r$reject_holm))
})

test_that("must provide p or z, not both", {
  expect_error(mht_test(alpha_bar = 0.05))
  expect_error(mht_test(p = pvals, z = qnorm(1 - pvals), alpha_bar = 0.05))
})

test_that("Cobb-Douglas model works", {
  r <- mht_test(p = pvals, alpha_bar = 0.05, model = "cobbdouglas")
  expect_equal(attr(r, "model"), "cobbdouglas")
})
