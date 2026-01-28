#!/usr/bin/env Rscript
# predict.R - Prediction script for LaCiD ARIMAX model
#
# Usage: Rscript predict.R <model.rds> <historic_data.csv> <future_data.csv> <predictions.csv>

library(forecast)
source("lib.R")

#' Generate predictions for future time periods
#'
#' @param model_path Path to trained model file
#' @param historic_data_path Path to historic data CSV
#' @param future_data_path Path to future climate data CSV
#' @param predictions_path Path to save predictions CSV
predict_chap <- function(model_path, historic_data_path, future_data_path, predictions_path) {
  cat("Loading model from:", model_path, "\n")
  models <- readRDS(model_path)

  cat("Loading future data from:", future_data_path, "\n")
  future_df <- read.csv(future_data_path)

  cat("Loading historic data from:", historic_data_path, "\n")
  historic_df <- read.csv(historic_data_path)

  # Prepare output
  output_rows <- list()
  n_samples <- 1000

  locations <- unique(future_df$location)
  cat("Generating predictions for", length(locations), "location(s)\n")

  for (loc in locations) {
    cat("Predicting for location:", loc, "\n")

    loc_key <- as.character(loc)

    if (!loc_key %in% names(models)) {
      cat("  Warning: No model found for location", loc, ", skipping\n")
      next
    }

    model_info <- models[[loc_key]]
    model <- model_info$model
    lambda <- model_info$lambda

    # Get future data for this location
    loc_future <- future_df[future_df$location == loc, ]
    loc_future <- loc_future[order(loc_future$time_period), ]

    # Get historic data for this location to compute lags
    loc_historic <- historic_df[historic_df$location == loc, ]
    loc_historic <- loc_historic[order(loc_historic$time_period), ]

    # Prepare lagged features for prediction
    # Use last values from historic data for initial lags
    last_cases <- model_info$last_cases
    last_temp <- model_info$last_temp

    # Add 1 if needed (matching training transformation)
    if (any(last_cases == 0)) {
      last_cases <- last_cases + 1
    }

    # Box-Cox transform
    last_cases_bc <- BoxCox(last_cases, lambda)

    n_future <- nrow(loc_future)
    xreg_future <- matrix(NA, nrow = n_future, ncol = 4)
    colnames(xreg_future) <- c("cases_lag1", "cases_lag2", "cases_lag3", "temp_lag1")

    # Fill in lagged features
    # For simplicity, use rolling averages for future lags (as in original code)
    for (i in 1:n_future) {
      if (i == 1) {
        xreg_future[i, "cases_lag1"] <- last_cases_bc[3]
        xreg_future[i, "cases_lag2"] <- last_cases_bc[2]
        xreg_future[i, "cases_lag3"] <- last_cases_bc[1]
        xreg_future[i, "temp_lag1"] <- last_temp
      } else if (i == 2) {
        xreg_future[i, "cases_lag1"] <- xreg_future[i-1, "cases_lag1"]  # approximate
        xreg_future[i, "cases_lag2"] <- last_cases_bc[3]
        xreg_future[i, "cases_lag3"] <- last_cases_bc[2]
        xreg_future[i, "temp_lag1"] <- loc_future$mean_temperature[i-1]
      } else if (i == 3) {
        xreg_future[i, "cases_lag1"] <- xreg_future[i-1, "cases_lag1"]
        xreg_future[i, "cases_lag2"] <- xreg_future[i-2, "cases_lag1"]
        xreg_future[i, "cases_lag3"] <- last_cases_bc[3]
        xreg_future[i, "temp_lag1"] <- loc_future$mean_temperature[i-1]
      } else {
        xreg_future[i, "cases_lag1"] <- xreg_future[i-1, "cases_lag1"]
        xreg_future[i, "cases_lag2"] <- xreg_future[i-2, "cases_lag1"]
        xreg_future[i, "cases_lag3"] <- xreg_future[i-3, "cases_lag1"]
        xreg_future[i, "temp_lag1"] <- loc_future$mean_temperature[i-1]
      }
    }

    # Generate predictions with samples
    sim_matrix <- tryCatch({
      predict_with_samples(model, xreg_future, n_samples)
    }, error = function(e) {
      cat("  Warning: Prediction failed:", e$message, "\n")
      matrix(NA, nrow = n_future, ncol = n_samples)
    })

    # Build output rows
    for (i in 1:n_future) {
      row_data <- list(
        time_period = loc_future$time_period[i],
        location = loc
      )

      # Add sample columns
      for (s in 1:n_samples) {
        row_data[[paste0("sample_", s - 1)]] <- max(0, sim_matrix[i, s])
      }

      output_rows[[length(output_rows) + 1]] <- row_data
    }

    cat("  Generated", n_future, "predictions\n")
  }

  # Convert to data frame
  output_df <- do.call(rbind, lapply(output_rows, as.data.frame))

  # Write output
  cat("Saving predictions to:", predictions_path, "\n")
  write.csv(output_df, predictions_path, row.names = FALSE)
  cat("Prediction complete.\n")
}

# Command line interface
args <- commandArgs(trailingOnly = TRUE)

if (length(args) >= 4) {
  model_path <- args[1]
  historic_data_path <- args[2]
  future_data_path <- args[3]
  predictions_path <- args[4]
  predict_chap(model_path, historic_data_path, future_data_path, predictions_path)
} else {
  cat("Usage: Rscript predict.R <model.rds> <historic_data.csv> <future_data.csv> <predictions.csv>\n")
  quit(status = 1)
}
