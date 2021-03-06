context("Test extraction model eefun utilies for merMod objects")
library(lme4, quietly = TRUE)
# Using VerbAagg dataset because it's including in lme4, not because it makes
# sense.
testdt   <- VerbAgg
testdt$id <- as.integer(testdt$id)
testdt$y  <- testdt$r2 == 'Y'
testdt_id1 <- subset(testdt, id == 1)
m <- glmer(y ~ Gender + (1|id), data = testdt, family = binomial(link = 'logit'))
theta <- unlist(getME(m, c('beta', 'theta')))

rf  <- get_fixed_formula(m)
X   <- get_design_matrix(rf, testdt_id1)
Y   <- get_response(formula(m), data = testdt_id1)
lnk <- m@resp$family$linkinv

test_that("model utilities worked", {
  expect_equal(rf, ~ Gender)
  expect_equal(X, matrix(1, nrow = 24, ncol = 2), check.attributes = FALSE)
  expect_equal(Y, subset(testdt, id == 1)$y, check.attributes = FALSE)
})

test_that("binomial integrand returns numeric values", {
  x <- binomial_integrand(b = c(0, 1), response = Y, xmatrix = X, parms = theta,
                          linkinv = lnk )
  expect_is(x, 'numeric')
})

test_that("binomial objFun returns single value", {
  x <- objFun_glmerMod_binomial(response = Y,
                                xmatrix  = X,
                                parms    = theta,
                                linkinv  = lnk )
  expect_is(x, 'numeric')
})

test_that("objFun_merMod returns function for binomial family", {
  x <- objFun_merMod(family   = 'binomial',
                       response = Y,
                       xmatrix  = X,
                       parms    = theta,
                       linkinv  = lnk )
  expect_is(x, 'function')
})

test_that("make_eefun.merMod returns function for binomial family", {
  ee_glmer <- make_eefun(m, testdt_id1)
  expect_is(ee_glmer, 'function')
})

test_that("eefun.merMod evaluates when passed theta", {
  ee_glmer <- make_eefun(m, testdt_id1)
  x <- ee_glmer(theta)
  expect_is(x, 'numeric')
})
