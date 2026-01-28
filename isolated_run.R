#!/usr/bin/env Rscript
# isolated_run.R - Local testing script for LaCiD ARIMAX model
#
# This script runs the full train-predict pipeline without CHAP

cat("=== LaCiD ARIMAX Model - Isolated Run ===\n\n")

# Source the training and prediction scripts
source("train.R")
source("predict.R")

# Define paths
train_data_path <- "input/trainData.csv"
future_data_path <- "input/futureClimateData.csv"
model_path <- "output/model.rds"
predictions_path <- "output/predictions.csv"

# Check if input files exist
if (!file.exists(train_data_path)) {
  stop("Training data not found: ", train_data_path)
}
if (!file.exists(future_data_path)) {
  stop("Future climate data not found: ", future_data_path)
}

# Create output directory if it doesn't exist
if (!dir.exists("output")) {
  dir.create("output")
}

# Run training
cat("\n--- Training Phase ---\n")
train_chap(train_data_path, model_path)

# Run prediction
cat("\n--- Prediction Phase ---\n")
predict_chap(model_path, train_data_path, future_data_path, predictions_path)

cat("\n=== Done! ===\n")
cat("Model saved to:", model_path, "\n")
cat("Predictions saved to:", predictions_path, "\n")
