# pacotes necessarios

library(tidyverse)
library(forecast)
library(data.table)
library(reticulate)
library(prophet)
library(data.table)
library(epitools)

# registrando o modelo

API_KEY <- ""

py_require(c("mosqlient>=1.9.3"))
mosq <- import("mosqlient")

#response <- mosq$upload_model(
#  api_key = API_KEY,
#  name = "LaCiD/UFRN",
#  description = "ARIMAX model used to participate in the 2nd Infodengue-Mosqlimate Dengue Challenge (IMDC)",
#  repository = "https://github.com/lacidufrn/infodengue_sprint_2025",
#  implementation_language = "R",
#  disease = "dengue",
#  temporal = TRUE,
#  spatial = FALSE,
#  categorical = FALSE,
#  adm_level = 1,
#  time_resolution = "week",
#  sprint = TRUE
#)


################
### treino 1 ###
################

rm(list = ls())

load("resultados/Resultados_SprintDengue_treino1.RData")

estado_lista <- grep("ES", gsub("mod_", "", grep("mod_", ls(), value = TRUE)), invert = TRUE, value = TRUE)

date <- 
  dengue_estado |>
  filter(uf == estado) |>
  arrange(date) |>
  filter(target_1 == TRUE) |>
  select(date)

for (j in estado_lista) {
  
  estado <- j
  
  modelo <- get(paste0("mod_", estado))
  
  lambda_series <- as.numeric(modelo$lambda)

  xreg_teste <-
    dengue_estado |>
    filter(uf == estado) |>
    arrange(date) |>
    mutate(
      casos_lag1 = lag(BoxCox(casos, lambda = lambda_series), 1),
      casos_lag2 = lag(BoxCox(casos, lambda = lambda_series), 2),
      casos_lag3 = lag(BoxCox(casos, lambda = lambda_series), 3),
      temp_lag1  = lag(temp_med, 1)
    ) |> 
    filter(target_1 == TRUE) |>
    select(casos_lag1, casos_lag2, casos_lag3, temp_lag1)

  h <- 52
  n_sim <- 1000
  set.seed(123)

  sim_matrix <- replicate(n_sim, {
    simulate(modelo, nsim = h, xreg = xreg_teste, future = TRUE)
  })

  df_forecast <-
    tibble(
      date    = pull(date),
      pred    = apply(sim_matrix, 1, median),
      lower_50 = apply(sim_matrix, 1, quantile, probs = 0.25),
      upper_50 = apply(sim_matrix, 1, quantile, probs = 0.75),
      lower_80 = apply(sim_matrix, 1, quantile, probs = 0.10),
      upper_80 = apply(sim_matrix, 1, quantile, probs = 0.90),
      lower_90 = apply(sim_matrix, 1, quantile, probs = 0.05),
      upper_90 = apply(sim_matrix, 1, quantile, probs = 0.95),
      lower_95 = apply(sim_matrix, 1, quantile, probs = 0.025),
      upper_95 = apply(sim_matrix, 1, quantile, probs = 0.975)
    )
  
  # submissao
  
  mosq$upload_prediction(
    model_id = 121,
    description = paste("Dengue predictions for", estado, "using ARIMAX model in R", sep = " "),
    commit = "",
    predict_date = today(),
    prediction = df_forecast,
    adm_1 = estado,
    api_key = API_KEY
  )

}


################
### treino 2 ###
################

rm(list = setdiff(ls(), c("API_KEY", "response", "mosq")))

load("resultados/Resultados_SprintDengue_treino2.RData")

estado_lista <- grep("ES", gsub("mod_", "", grep("mod_", ls(), value = TRUE)), invert = TRUE, value = TRUE)

date <- 
  dengue_estado |>
  filter(uf == estado) |>
  arrange(date) |>
  filter(target_2 == TRUE) |>
  select(date)

for (j in estado_lista) {
  
  estado <- j
  
  modelo <- get(paste0("mod_", estado))
  
  lambda_series <- as.numeric(modelo$lambda)
  
  xreg_teste <-
    dengue_estado |>
    filter(uf == estado) |>
    arrange(date) |>
    mutate(
      casos_lag1 = lag(BoxCox(casos, lambda = lambda_series), 1),
      casos_lag2 = lag(BoxCox(casos, lambda = lambda_series), 2),
      casos_lag3 = lag(BoxCox(casos, lambda = lambda_series), 3),
      temp_lag1  = lag(temp_med, 1)
    ) |> 
    filter(target_2 == TRUE) |>
    select(casos_lag1, casos_lag2, casos_lag3, temp_lag1)
  
  h <- 52
  n_sim <- 1000
  set.seed(123)
  
  sim_matrix <- replicate(n_sim, {
    simulate(modelo, nsim = h, xreg = xreg_teste, future = TRUE)
  })
  
  df_forecast <-
    tibble(
      date    = pull(date),
      pred    = apply(sim_matrix, 1, median),
      lower_50 = apply(sim_matrix, 1, quantile, probs = 0.25),
      upper_50 = apply(sim_matrix, 1, quantile, probs = 0.75),
      lower_80 = apply(sim_matrix, 1, quantile, probs = 0.10),
      upper_80 = apply(sim_matrix, 1, quantile, probs = 0.90),
      lower_90 = apply(sim_matrix, 1, quantile, probs = 0.05),
      upper_90 = apply(sim_matrix, 1, quantile, probs = 0.95),
      lower_95 = apply(sim_matrix, 1, quantile, probs = 0.025),
      upper_95 = apply(sim_matrix, 1, quantile, probs = 0.975)
    )
  
  # submissao
  
  mosq$upload_prediction(
    model_id = 121,
    description = paste("Dengue predictions for", estado, "using ARIMAX model in R", sep = " "),
    commit = "",
    predict_date = today(),
    prediction = df_forecast,
    adm_1 = estado,
    api_key = API_KEY
  )
  
}



################
### treino 3 ###
################

rm(list = setdiff(ls(), c("API_KEY", "response", "mosq")))

load("resultados/Resultados_SprintDengue_treino3.RData")

estado_lista <- grep("ES", gsub("mod_", "", grep("mod_", ls(), value = TRUE)), invert = TRUE, value = TRUE)

date <- 
  dengue_estado |>
  filter(uf == estado) |>
  arrange(date) |>
  filter(target_3 == TRUE) |>
  select(date) |> 
  mutate(date = as.Date(date))

# adiciona as 18 semanas que faltam no target 3

aux <- tibble(date = seq.Date(from = last(date$date)+7, by = "week", length.out = 18))

date <- 
  date |> 
  bind_rows(aux)


for (j in estado_lista) {
  
  j <- estado_lista[23]
  estado <- j
  
  modelo <- get(paste0("mod_", estado))
  
  lambda_series <- as.numeric(modelo$lambda)
  
  xreg_teste <-
    dengue_estado |>
    filter(uf == estado) |>
    arrange(date) |>
    mutate(
      casos_lag1 = lag(BoxCox(casos, lambda = lambda_series), 1),
      casos_lag2 = lag(BoxCox(casos, lambda = lambda_series), 2),
      casos_lag3 = lag(BoxCox(casos, lambda = lambda_series), 3),
      temp_lag1  = lag(temp_med, 1)
    ) |> 
    filter(target_3 == TRUE) |>
    select(casos_lag1, casos_lag2, casos_lag3, temp_lag1)
  
  # completar o dataset com medias moveis
  
  n <- nrow(xreg_teste)
  
  k <- 12
  
  for (j in (n+1):52){
    xreg_teste[j, 1] <- mean(pull(xreg_teste[(j-k):(j-1), 1]))
    xreg_teste[j, 2] <- mean(pull(xreg_teste[(j-k):(j-1), 2]))
    xreg_teste[j, 3] <- mean(pull(xreg_teste[(j-k):(j-1), 3]))
  }
  
  for (j in (n-3):52){
    xreg_teste[j, 4] <- mean(pull(xreg_teste[(j-k):(j-1), 4]))
  }
  
  h <- 52
  n_sim <- 1000
  set.seed(123)
  
  sim_matrix <- replicate(n_sim, {
    simulate(modelo, nsim = h, xreg = xreg_teste, future = TRUE)
  })
  
  df_forecast <-
    tibble(
      date    = pull(date),
      pred    = apply(sim_matrix, 1, median),
      lower_50 = apply(sim_matrix, 1, quantile, probs = 0.25),
      upper_50 = apply(sim_matrix, 1, quantile, probs = 0.75),
      lower_80 = apply(sim_matrix, 1, quantile, probs = 0.10),
      upper_80 = apply(sim_matrix, 1, quantile, probs = 0.90),
      lower_90 = apply(sim_matrix, 1, quantile, probs = 0.05),
      upper_90 = apply(sim_matrix, 1, quantile, probs = 0.95),
      lower_95 = apply(sim_matrix, 1, quantile, probs = 0.025),
      upper_95 = apply(sim_matrix, 1, quantile, probs = 0.975)
    )
  
  # submissao
  
  mosq$upload_prediction(
    model_id = 121,
    description = paste("Dengue predictions for", estado, "using ARIMAX model in R", sep = " "),
    commit = "",
    predict_date = today(),
    prediction = df_forecast,
    adm_1 = estado,
    api_key = API_KEY
  )
  
}



