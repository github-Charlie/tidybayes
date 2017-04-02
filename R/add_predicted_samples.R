# add_predicted_samples
# 
# Author: mjskay
###############################################################################

# Names that should be suppressed from global variable check by codetools
# Names used broadly should be put in _global_variables.R
globalVariables(c(".iteration", ".pred"))


#' Add samples from the posterior fit or posterior prediction of a model to a data frame
#' 
#' Given a data frame, adds samples from the posterior fit (aka the linear/link-level predictor) 
#' or the posterior predictions of the model to the data in a long format.
#' 
#' \code{add_fitted_samples} adds samples from the posterior linear predictor (or the "link") to
#' the data. It corresponds to \code{\link[rstanarm]{posterior_linpred}} in \code{rstanarm} or
#' \code{\link[brms]{fitted.brmsfit}} in \code{brms}.
#' 
#' \code{add_predicted_samples} adds samples from the posterior prediction to
#' the data. It corresponds to \code{\link[rstanarm]{posterior_predict}} in \code{rstanarm} or
#' \code{\link[brms]{predict.brmsfit}} in \code{brms}.
#' 
#' \code{add_fitted_samples} and \code{fitted_samples} are alternate spellings of the 
#' same function with opposite order of the first two arguments to facilitate use in data
#' processing pipelines that start either with a data frame or a model. Similarly,
#' \code{add_predicted_samples} and \code{predicted_samples} are alternate spellings.
#' 
#' Given equal choice between the two, \code{add_fitted_samples} and \code{add_predicted_samples}
#' are the preferred spellings.
#' 
#' @param newdata Data frame to generate predictions from. If omitted, most model types will
#' generate predictions from the data used to fit the model.
#' @param model A supported Bayesian model fit / MCMC object. Currently
#' supported models include \code{\link[coda]{mcmc}}, \code{\link[coda]{mcmc.list}},
#' \code{\link[runjags]{runjags}}, \code{\link[rstan]{stanfit}}, \code{\link[rethinking]{map}},
#' \code{\link[rethinking]{map2stan}}, and anything with its own \code{\link[coda]{as.mcmc.list}}
#' implementation.
#' @param ... Additional arguments passed to the underlying prediction method for the type of
#' model given.
#' @return A data frame (actually, a \code{\link[tibble]{tibble}}) with a \code{.row} column (a
#' factor grouping rows from the input \code{newdata}), \code{.chain} column (the chain
#' each sample came from, or \code{NA} if the model does not provide chain information),
#' \code{.iteration} column (the iteration the sample came from), and \code{.pred} column (a
#' sample from the posterior predictive distribution). For convenience, the resulting data
#' frame comes grouped by the original input rows.
#' @author Matthew Kay
#' @seealso \code{\link{gather_samples}}
#' @keywords manip
#' @importFrom magrittr %>%
#' @importFrom tidyr gather
#' @importFrom dplyr mutate
#' @export
add_predicted_samples = function(newdata, model, ...) {
    predicted_samples(model, newdata, ...)
}

#' @rdname add_predicted_samples
#' @export
add_fitted_samples = function(newdata, model, ...) {
    fitted_samples(model, newdata, ...)
}

#' @rdname add_predicted_samples
#' @export
predicted_samples = function(model, newdata, ...) UseMethod("predicted_samples")

#' @rdname add_predicted_samples
#' @export
fitted_samples = function(model, newdata, ...) UseMethod("fitted_samples")

#' @rdname add_predicted_samples
#' @export
predicted_samples.default = function(model, newdata, ...) {
    stop(paste0("Models of type ", deparse0(class(model)), " are not currently supported by `predicted_samples`"))
}

#' @rdname add_predicted_samples
#' @export
fitted_samples.default = function(model, newdata, ...) {
    stop(paste0("Models of type ", deparse0(class(model)), " are not currently supported by `fitted_samples`"))
}

# template for predicted_samples.stanreg and fitted_samples.stanreg
fitted_predicted_samples_stanreg_ = function(f_fitted_predicted, model, newdata, ...) {
    newdata %>%
        data.frame(
            #for some reason calculating row here instead of in a subsequent mutate()
            #is about 3 times faster
            .row = factor(1:nrow(.)),
            .chain = as.numeric(NA),
            t(f_fitted_predicted(model, newdata = ., ...)), 
            check.names=FALSE
        ) %>%
        gather(.iteration, .pred, (ncol(newdata)+3):ncol(.)) %>%
        mutate(
            .iteration = as.numeric(.iteration)
        ) %>%
        group_by_(".row", .dots = colnames(newdata))
}

#' @rdname add_predicted_samples
#' @export
predicted_samples.stanreg = function(model, newdata, ...) {
    if (!requireNamespace("rstantools", quietly = TRUE)) {
        stop('The `rstantools` package is needed for `predicted_samples` to support `stanreg` objects.'
            , call. = FALSE)
    }

    fitted_predicted_samples_stanreg_(rstantools::posterior_predict, model, newdata, ...)
}

#' @rdname add_predicted_samples
#' @export
fitted_samples.stanreg = function(model, newdata, ...) {
    if (!requireNamespace("rstanarm", quietly = TRUE)) {
        stop('The `rstanarm` package is needed for `fitted_samples` to support `stanreg` objects.'
            , call. = FALSE)
    }
    
    fitted_predicted_samples_stanreg_(rstanarm::posterior_linpred, model, newdata, ...)
}