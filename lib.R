# lib.R - Shared utility functions for LaCiD ARIMAX model

#' Prepare data with lagged features for ARIMAX modeling
#'
#' @param df Data frame with columns: time_period, location, disease_cases, mean_temperature
#' @param lambda Box-Cox lambda parameter (NULL to estimate)
#' @return List with prepared data and lambda value
prepare_arimax_data <- function(df, lambda = NULL) {
  library(forecast)

  # Sort by time
  df <- df[order(df$time_period), ]

  # Add 1 to cases if there are zeros (for Box-Cox)
  if (min(df$disease_cases, na.rm = TRUE) == 0) {
    df$disease_cases <- df$disease_cases + 1
  }

  # Estimate Box-Cox lambda if not provided
  if (is.null(lambda)) {
    lambda <- BoxCox.lambda(df$disease_cases, lower = -1, upper = 2)
  }

  # Create lagged features
  df$cases_bc <- BoxCox(df$disease_cases, lambda = lambda)
  df$cases_lag1 <- c(NA, head(df$cases_bc, -1))
  df$cases_lag2 <- c(NA, NA, head(df$cases_bc, -2))
  df$cases_lag3 <- c(NA, NA, NA, head(df$cases_bc, -3))
  df$temp_lag1 <- c(NA, head(df$mean_temperature, -1))

  list(data = df, lambda = lambda)
}

#' Train ARIMAX model for a single location
#'
#' @param df Data frame with lagged features
#' @param lambda Box-Cox lambda parameter
#' @return Trained ARIMA model object
train_arimax_location <- function(df, lambda) {
  library(forecast)

  # Remove rows with NA in lagged features
  complete_idx <- complete.cases(df[, c("cases_lag1", "cases_lag2", "cases_lag3", "temp_lag1")])
  df_complete <- df[complete_idx, ]

  if (nrow(df_complete) < 10) {
    warning("Insufficient data for training")
    return(NULL)
  }

  # Create time series
  casos_ts <- ts(df_complete$disease_cases, frequency = 52)

  # Prepare exogenous regressors
  xreg <- as.matrix(df_complete[, c("cases_lag1", "cases_lag2", "cases_lag3", "temp_lag1")])

  # Fit ARIMAX model
  model <- tryCatch({
    auto.arima(
      y = casos_ts,
      xreg = xreg,
      max.p = 10,
      max.q = 10,
      max.P = 5,
      max.Q = 5,
      max.order = 10,
      seasonal = TRUE,
      stepwise = TRUE,
      lambda = lambda,
      biasadj = FALSE
    )
  }, error = function(e) {
    warning(paste("Model fitting failed:", e$message))
    NULL
  })

  model
}

#' Generate predictions with uncertainty samples
#'
#' @param model Trained ARIMA model
#' @param xreg_future Matrix of future exogenous regressors
#' @param n_samples Number of Monte Carlo samples
#' @return Matrix of predictions (rows = time points, cols = samples)
predict_with_samples <- function(model, xreg_future, n_samples = 1000) {
  library(forecast)

  h <- nrow(xreg_future)

  # Generate samples via simulation
  set.seed(123)
  sim_matrix <- replicate(n_samples, {
    simulate(model, nsim = h, xreg = xreg_future, future = TRUE)
  })

  sim_matrix
}
