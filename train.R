#!/usr/bin/env Rscript
# train.R - Training script for LaCiD ARIMAX model
#
# Usage: Rscript train.R <train_data.csv> <model_output.rds>

library(forecast)
source("lib.R")

#' Train ARIMAX models for all locations in the dataset
#'
#' @param train_data_path Path to training CSV file
#' @param model_path Path to save trained model(s)
train_chap <- function(train_data_path, model_path) {
  cat("Loading training data from:", train_data_path, "\n")
  df <- read.csv(train_data_path)

  # Handle missing values in disease_cases
  df$disease_cases[is.na(df$disease_cases)] <- 0

  # Get unique locations
  locations <- unique(df$location)
  cat("Training models for", length(locations), "location(s)\n")

  # Train one model per location
  models <- list()

  for (loc in locations) {
    cat("Training model for location:", loc, "\n")

    # Filter data for this location
    loc_df <- df[df$location == loc, ]

    # Prepare data with lagged features
    prepared <- prepare_arimax_data(loc_df)
    loc_df <- prepared$data
    lambda <- prepared$lambda

    # Train model
    model <- train_arimax_location(loc_df, lambda)

    if (!is.null(model)) {
      models[[as.character(loc)]] <- list(
        model = model,
        lambda = lambda
      )
      cat("  Model trained successfully\n")
    } else {
      cat("  Warning: Model training failed for location", loc, "\n")
    }
  }

  # Save models
  cat("Saving models to:", model_path, "\n")
  saveRDS(models, file = model_path)
  cat("Training complete.\n")
}

# Command line interface - only run when called directly
if (!interactive() && sys.nframe() == 0) {
  args <- commandArgs(trailingOnly = TRUE)

  if (length(args) >= 2) {
    train_data_path <- args[1]
    model_path <- args[2]
    train_chap(train_data_path, model_path)
  } else {
    cat("Usage: Rscript train.R <train_data.csv> <model_output.rds>\n")
    quit(status = 1)
  }
}
