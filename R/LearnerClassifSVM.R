#' @title Support Vector Machine
#'
#' @usage NULL
#' @aliases mlr_learners_classif.svm
#' @format [R6::R6Class()] inheriting from [mlr3::LearnerClassif].
#'
#' @section Construction:
#' ```
#' LearnerClassifSVM$new()
#' mlr3::mlr_learners$get("classif.svm")
#' mlr3::lrn("classif.svm")
#' ```
#'
#' @description
#' A learner for a classification support vector machine implemented in [e1071::svm()].
#'
#' @references
#' Corinna Cortes, Vladimir Vapnik (1995).
#' Machine Learning 20: 273.
#' \doi{10.1007/BF00994018}.
#'
#' @export
#' @template seealso_learner
#' @templateVar learner_name classif.svm
#' @template example
LearnerClassifSVM = R6Class("LearnerClassifSVM", inherit = LearnerClassif,
  public = list(
    initialize = function() {
      ps = ParamSet$new(list(
        ParamFct$new("type", default = "C-classification", levels = c("C-classification", "nu-classification"), tags = "train"),
        ParamDbl$new("cost", default = 1, lower = 0, tags = "train"), # requires = quote(type == "C-classification")),
        ParamDbl$new("nu", default = 0.5, tags = "train"), # requires = quote(type == "nu-classification")),
        ParamFct$new("kernel", default = "radial", levels = c("linear", "polynomial", "radial", "sigmoid"), tags = "train"),
        ParamInt$new("degree", default = 3L, lower = 1L, tags = "train"), # requires = quote(kernel == "polynomial")),
        ParamDbl$new("coef0", default = 0, tags = "train"), # requires = quote(kernel == "polynomial" || kernel == "sigmoid")),
        ParamDbl$new("gamma", lower = 0, tags = "train"), # requires = quote(kernel != "linear")),
        ParamDbl$new("cachesize", default = 40L, tags = "train"),
        ParamDbl$new("tolerance", default = 0.001, lower = 0, tags = "train"),
        ParamLgl$new("shrinking", default = TRUE, tags = "train"),
        ParamInt$new("cross", default = 0L, lower = 0L, tags = "train"), # tunable = FALSE),
        ParamLgl$new("fitted", default = TRUE, tags = "train"), # tunable = FALSE),
        ParamUty$new("scale", default = TRUE, tags = "train") # , tunable = TRUE)
      ))

      super$initialize(
        id = "classif.svm",
        param_set = ps,
        predict_types = c("response", "prob"),
        feature_types = c("integer", "numeric"),
        properties = c("twoclass", "multiclass"),
        packages = "e1071"
      )
    },

    train_internal = function(task) {
      pars = self$param_set$get_values(tags = "train")

      invoke(e1071::svm,
        x = as.matrix(task$data(cols = task$feature_names)),
        y = task$truth(),
        probability = (self$predict_type == "prob"),
        .args = pars
      )
    },

    predict_internal = function(task) {
      pars = self$param_set$get_values(tags = "predict")
      newdata = as.matrix(task$data(cols = task$feature_names))
      p = invoke(predict, self$model, newdata = newdata, probability = (self$predict_type == "prob"), .args = pars)

      PredictionClassif$new(task = task,
        response = as.character(p),
        prob = attr(p, "probabilities") # is NULL if not requested during predict
      )
    }
  )
)
