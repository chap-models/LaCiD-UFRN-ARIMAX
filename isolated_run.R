source("train.R")
source("predict.R")

# Test with weekly data
train_chap("example_data/training_data.csv", "example_data/model.rds")
predict_chap("example_data/model.rds", "example_data/training_data.csv", "example_data/future_data.csv", "example_data/predictions.csv")

cat("\nDone! Check example_data/predictions.csv for results.\n")
