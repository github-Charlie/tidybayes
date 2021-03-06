as_constructor = function(x) UseMethod("as_constructor")

as_constructor.default = function(x) identity

as_constructor.factor = function(x) {
  x_levels = levels(x)
  x_is_ordered = is.ordered(x)
  function(x) factor(x, levels = seq_along(x_levels), labels = x_levels, ordered = x_is_ordered)
}

as_constructor.character = function(x) as_constructor(as.factor(x))

as_constructor.logical = function(x) as.logical


#' @export
apply_prototypes = function(...) {
  .Deprecated("recover_types")
  recover_types(...)
}

#' Decorate a model fit or samples with data types recovered from the input data
#'
#' Decorate the samples returned from a Bayesian sampler with types for
#' variable and index data types. Meant to be used before calling
#' \code{\link{spread_samples}} or \code{\link{gather_samples}} so that the values returned by
#' those functions are translated back into useful data types.
#'
#' Each argument in \code{...} specifies a list or data.frame. The \code{model}
#' is decorated with a list of constructors that can convert a numeric column
#' into the data types in the lists in \code{...}.
#'
#' Then, when \code{\link{spread_samples}} or \code{\link{gather_samples}} is called on the decorated
#' \code{model}, each list entry with the same name as the variable or an index
#' in varible_spec is a used as a prototype for that variable or index ---
#' i.e., its type is taken to be the expected type of that variable or index.
#' Those types are used to translate numeric values of variables back into
#' useful values (for example, levels of a factor).
#'
#' The most common use of \code{recover_types} is to automatically translate
#' indices that correspond to levels of a factor in the original data back into
#' levels of that factor. The simplest way to do this is to pass in the data
#' frame from which the original data came.
#'
#' Supported types of prototypes are factor, ordered, and logical. For example:
#'
#' \itemize{ \item if \code{prototypes$v} is a factor, the v column in the
#' returned samples is translated into a factor using \code{factor(v,
#' labels=levels(prototypes$v), ordered=is.ordered(prototypes$v))}.  \item if
#' \code{prototypes$v} is a logical, the v column is translated into a logical
#' using \code{as.logical(v)}. }
#'
#' Additional data types can be supported by providing a custom implementation
#' of the generic function \code{as_constructor}.
#'
#' @param model A supported Bayesian model fit / MCMC object. Currently
#' supported models include \code{\link[coda]{mcmc}}, \code{\link[coda]{mcmc.list}},
#' \code{\link[runjags]{runjags}}, \code{\link[rstan]{stanfit}}, \code{\link[rstanarm]{stanreg-objects}},
#' \code{\link[brms]{brm}}, and anything with its own \code{\link[coda]{as.mcmc.list}} implementation.
#' If you install the \code{tidybayes.rethinking} package (available at
#' \url{https://github.com/mjskay/tidybayes.rethinking}), \code{map} and
#' \code{map2stan} models from the \code{rethinking} package are also supported.
#' @param ...  Lists (or data frames) providing data prototypes used to convert
#' columns returned by \code{\link{spread_samples}} and \code{\link{gather_samples}} back into useful data types.
#' See `Details`.
#' @return A decorated version of \code{model}.
#' @author Matthew Kay
#' @aliases apply_prototypes
#' @seealso \code{\link{spread_samples}}, \code{\link{gather_samples}}, \code{\link{compose_data}}.
#' @keywords manip
#' @examples
#'
#' ##TODO
#'
#' @export
recover_types = function(model, ...) {
  if (!is.list(attr(model, "constructors"))) {
    attr(model, "constructors") = list()
  }

  for (prototypes in list(...)) {
    #we iterate this way instead of building a list directly
    #so that existing names are overwritten
    for (variable_name in names(prototypes)) {
      attr(model, "constructors")[[variable_name]] = as_constructor(prototypes[[variable_name]])
    }
  }

  model
}
