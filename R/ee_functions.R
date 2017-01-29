#------------------------------------------------------------------------------#
#' Make Estimating Equation functions
#'
#' Converts a model object into
#'
#' @param model a model object object
#' @param data data with which to create the estimating equation function
#' @param ... passed to methods
#' @export
#------------------------------------------------------------------------------#
make_eefun <- function(model, data, ...)
{
  UseMethod("make_eefun")
}

#------------------------------------------------------------------------------#
#' glmer Estimating Equations
#'
#' Create estimating equation function from a \code{merMod} object
#'
#' @inheritParams make_eefun
#' @export
#------------------------------------------------------------------------------#

make_eefun.merMod <- function(object, data)
{
  ## Warnings ##
  if(length(lme4::getME(object, 'theta')) > 1){
    stop('make_eefun.merMod currently does not handle >1 random effect')
  }

  fm     <- get_fixed_formula(object)
  X      <- get_design_matrix(fm, data)
  Y      <- get_response(formula(object), data = data)
  family <- object@resp$family
  lnkinv <- family$linkinv
  objfun <- objFun_merMod(family$family)

  function(theta){
    objfun(parms = theta, response = Y, xmatrix = X, linkinv = lnkinv)
  }
}

#------------------------------------------------------------------------------#
#' glmer Objective Fundtion
#'
#'@param family distribution family of objective function
#'@param ... additional arguments pass to objective function
#'@export
#------------------------------------------------------------------------------#

objFun_merMod <- function(family, ...){
  switch(family,
         binomial = objFun_glmerMod_binomial,
         stop('Objective function not defined'))
}

#------------------------------------------------------------------------------#
#' glmer Objective Function for Logistic-Normal Likelihood
#'
#' @param parms vector of parameters
#' @param response vector of response values
#' @param xmatrix the matrix of covariates
#' @param linkinv inverse link function
#' @export
#------------------------------------------------------------------------------#

objFun_glmerMod_binomial <- function(parms, response, xmatrix, linkinv)
{
  log(integrate(binomial_integrand, lower = -Inf, upper = Inf,
                parms    = parms,
                response = response,
                xmatrix  = xmatrix,
                linkinv  = linkinv)$value)

}

#------------------------------------------------------------------------------#
#' glmer Objective Function for Logistic-Normal Likelihood
#'
#' @inheritParams objFun_glmerMod_binomial
#' @export
#------------------------------------------------------------------------------#

binomial_integrand <- function(b, response, xmatrix, parms, linkinv){
  if(class(xmatrix) != 'matrix'){
    xmatrix <- as.matrix(xmatrix)
  }
  pr  <- linkinv( drop(outer(xmatrix %*% parms[-length(parms)], b, '+') ) )
  hh  <- dbinom(response, 1, prob = pr)
  hha <- apply(hh, 2, prod)
  hha * dnorm(b, mean = 0, sd = parms[length(parms)])
}