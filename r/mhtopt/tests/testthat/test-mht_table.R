test_that("mht_table returns data.frame", {
  t <- mht_table(alpha_bar = 0.05, J_range = 1:5, nm_ratios = 1.0)
  expect_true(is.data.frame(t))
})

test_that("mht_table has J column", {
  t <- mht_table(alpha_bar = 0.05, J_range = 1:5)
  expect_true("J" %in% names(t))
})

test_that("mht_table: correct number of rows", {
  t <- mht_table(alpha_bar = 0.05, J_range = c(1:9, Inf), nm_ratios = 1.0)
  expect_equal(nrow(t), 10)
})

test_that("mht_table: Cobb-Douglas model", {
  t <- mht_table(model = "cobbdouglas", alpha_bar = 0.05, J_range = 1:3,
                 nm_ratios = 1.0, beta = 0.13, iota = 0.075)
  expect_equal(nrow(t), 3)
})

test_that("mht_table: Sidak columns present by default", {
  t <- mht_table(alpha_bar = 0.05, J_range = 1:3, nm_ratios = 1.0)
  expect_true(any(grepl("sidak", names(t))))
})

test_that("mht_table: sidak_bars=NULL suppresses Sidak columns", {
  t <- mht_table(alpha_bar = 0.05, J_range = 1:3, nm_ratios = 1.0, sidak_bars = NULL)
  expect_false(any(grepl("sidak", names(t))))
})
