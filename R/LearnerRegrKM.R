#' @title Kriging Regression Learner
#'
#' @usage NULL
#' @aliases mlr_learners_regr.km
#' @format [R6::R6Class()] inheriting from [mlr3::LearnerRegr].
#'
#' @section Construction:
#' ```
#' LearnerRegrKM$new()
#' mlr3::mlr_learners$get("regr.km")
#' mlr3::lrn("regr.km")
#' ```
#'
#' @description
#' Kriging regression.
#' Calls [DiceKriging::km()] from package \CRANpkg{DiceKriging}.
#'
#' * The predict type hyperparameter "type" defaults to "SK" (simple Kriging).
#' * The additional hyperparameter `nugget.stability` is used to overwrite the hyperparameter `nugget` with `nugget.stability * var(y)` before training to improve the numerical stability.
#'   We recommend a value of `1e-8`.
#' * The additional hyperparameter `jitter` can be set to add `N(0, [jitter])`-distributed noise to the data before prediction to avoid perfect interpolation. We recommend a value of `1e-12`.
#'
#' @references
#' Olivier Roustant, David Ginsbourger, Yves Deville (2012).
#' DiceKriging, DiceOptim: Two R Packages for the Analysis of Computer Experiments by Kriging-Based Metamodeling and Optimization.
#' Journal of Statistical Software, 51(1), 1-55.
#' \doi{10.18637/jss.v051.i01}.
#'
#' @export
#' @template seealso_learner
#' @templateVar learner_name regr.km
#' @template example
LearnerRegrKM = R6Class("LearnerRegrKM", inherit = LearnerRegr,
  public = list(
    initialize = function() {
      ps = ParamSet$new(list(
        ParamFct$new("covtype", default = "matern5_2", levels = c("gauss", "matern5_2", "matern3_2", "exp", "powexp"), tags = "train"),
        ParamDbl$new("nugget", tags = "train"),
        ParamLgl$new("nugget.estim", default = FALSE, tags = "train"),
        ParamFct$new("type", default = "SK", levels = c("SK", "UK"), tags = "predict"),
        ParamDbl$new("nugget.stability", default = 0, lower = 0, tags = "train"),
        ParamDbl$new("jitter", default = 0, lower = 0, tags = "predict")
      ))

      super$initialize(
        id = "regr.km",
        param_set = ps,
        predict_types = c("response", "se"),
        feature_types = c("integer", "numeric"),
        packages = "DiceKriging"
      )
    },

    train_internal = function(task) {
      pars = self$param_set$get_values(tags = "train")
      data = as.matrix(task$data(cols = task$feature_names))
      truth = task$truth()

      ns = pars$nugget.stability
      if (!is.null(ns)) {
        pars$nugget = if (ns == 0) 0 else ns * var(truth)
      }

      invoke(DiceKriging::km,
        response = task$truth(),
        design = data,
        control = list(trace = FALSE),
        .args = remove_named(pars, "nugget.stability")
      )
    },

    predict_internal = function(task) {
      pars = self$param_set$get_values(tags = "predict")
      newdata = as.matrix(task$data(cols = task$feature_names))

      jitter = pars$jitter
      if (!is.null(jitter) && jitter > 0) {
        newdata = newdata + rnorm(length(newdata), mean = 0, sd = jitter)
      }

      p = invoke(DiceKriging::predict.km,
        self$model,
        newdata = newdata,
        type = pars$type %??% "SK",
        se.compute = self$predict_type == "se",
        .args = remove_named(pars, "jitter")
      )

      PredictionRegr$new(task = task, response = p$mean, se = p$sd)
    }
  )
)
