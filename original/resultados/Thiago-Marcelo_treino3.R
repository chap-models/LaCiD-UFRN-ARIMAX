#######################################################
#                                                     #
# Predictions should be made for RN - Dengue          #
#                                                     #
# Autor:Thiago Valentim Marques, Marcelo Bourguignon  #
#       Eliardo Costa, Marcus Nunes                   #
#######################################################

#---- Carregar os pacotes necessários -----#
rm(list = ls())

library(tidyverse)
library(forecast)
library(data.table)

#---- Carregar os datasets -----#

dengue_original <- fread(file = "data/dengue.csv")
climate <- fread(file = "data/climate.csv")

#---- Fazendo o merge -----#
dengue_completo <- merge(dengue_original, climate,
                         by = c("date", "epiweek", "geocode"),
                         all.x = TRUE)  

dengue_completo = dengue_completo%>%
  mutate(chuva=precip_med*rainy_days)

names(dengue_completo)


####################################################
#                                                  #
#                Acumulado por estado              #
#                                                  #
####################################################

# Agregação por estado e data

dengue_estado <- dengue_completo %>%
  group_by(uf, date, epiweek) %>%
  summarise(
    casos = sum(casos, na.rm = TRUE),
    temp_med = mean(temp_med, na.rm = TRUE),
    rel_humid_med = mean(rel_humid_med, na.rm = TRUE),
    pressure_med = mean(pressure_med, na.rm = TRUE),
    chuva = sum(chuva, na.rm = TRUE),
    train_3 = all(train_3 == TRUE),
    target_3 = all(target_3 == TRUE),
    .groups = "drop"
  )



#--------------------------------------------------#
#           Previsão para todos os estados         #
#--------------------------------------------------#

library(patchwork)  # Para combinar múltiplos plots



ufs <- unique(dengue_estado$uf)
rmse_resultados <- data.frame(uf = character(), rmse = numeric(), mae = numeric())
plot_list <- list()

library(parallel)
n_cores <- detectCores()
library(doParallel)
cl <- makePSOCKcluster(n_cores)
registerDoParallel(cl)
 
for (estado in ufs) {
  ini <- Sys.time()
  print(estado)
  
  # mantem apenas o estado de interesse
  
  dados_uf <- dengue_estado %>%
    filter(uf == estado) |> 
    arrange(date)
  
  # adiciona 1 ao numero de casos dos estados que possuem algum 0
  
  if(min(dados_uf$casos) == 0){
    dados_uf <- 
      dados_uf %>%
      mutate(casos = casos + 1)
  }
  
  # encontra o melhor valor de lambda para a transformacao de box cox
  # e aplica ele logo em seguida
  
  lambda_series <- BoxCox.lambda(dados_uf$casos, lower = -1, upper = 2)
  
  dados_uf <- 
    dados_uf |> 
    mutate(
      casos_lag1 = lag(BoxCox(casos, lambda = lambda_series), 1),
      casos_lag2 = lag(BoxCox(casos, lambda = lambda_series), 2),
      casos_lag3 = lag(BoxCox(casos, lambda = lambda_series), 3),
      temp_lag1  = lag(temp_med, 1)
    )
  
  treino <- dados_uf %>%
    filter(train_3 == TRUE) %>%
    filter(if_all(c(casos_lag1, casos_lag2, casos_lag3, temp_lag1), ~ !is.na(.)))
  
  teste <- dados_uf %>%
    filter(target_3 == TRUE) %>%
    filter(if_all(c(casos_lag1, casos_lag2, casos_lag3, temp_lag1), ~ !is.na(.)))
  
  if (nrow(treino) > 52 && nrow(teste) > 5) {
    casos_ts <- ts(treino$casos, frequency = 52)
    xreg_treino <- as.matrix(treino %>% select(casos_lag1, casos_lag2, casos_lag3, temp_lag1))
    xreg_teste  <- as.matrix(teste %>% select(casos_lag1, casos_lag2, casos_lag3, temp_lag1))
    
    modelo <- tryCatch({
      auto.arima(
        y = casos_ts,
        xreg = xreg_treino,
        max.p = 10,
        max.q = 10,
        max.P = 5,
        max.Q = 5,
        max.order = 10,
        seasonal = TRUE,
        stepwise = TRUE,
        lambda = lambda_series,
        biasadj = FALSE
      )
    }, error = function(e) NULL)
    
    out <- paste("mod", estado, sep = "_")
    assign(out, modelo)
    
    if (!is.null(modelo)) {
      h <- nrow(xreg_teste)
      n_sim <- 1000
      set.seed(123)
      
      sim_matrix <- replicate(n_sim, {
        simulate(modelo, nsim = h, xreg = xreg_teste, future = TRUE)
      })
      
      sim_median  <- apply(sim_matrix, 1, median)
      sim_lower50 <- apply(sim_matrix, 1, quantile, probs = 0.25)
      sim_upper50 <- apply(sim_matrix, 1, quantile, probs = 0.75)
      sim_lower80 <- apply(sim_matrix, 1, quantile, probs = 0.10)
      sim_upper80 <- apply(sim_matrix, 1, quantile, probs = 0.90)
      sim_lower90 <- apply(sim_matrix, 1, quantile, probs = 0.05)
      sim_upper90 <- apply(sim_matrix, 1, quantile, probs = 0.95)
      sim_lower95 <- apply(sim_matrix, 1, quantile, probs = 0.025)
      sim_upper95 <- apply(sim_matrix, 1, quantile, probs = 0.975)
      
      dados_plot <- data.frame(
        date = teste$date,
        casos_reais = teste$casos,
        casos_median = sim_median,
        lower50 = sim_lower50,
        upper50 = sim_upper50,
        lower80 = sim_lower80,
        upper80 = sim_upper80,
        lower90 = sim_lower90,
        upper90 = sim_upper90,
        lower95 = sim_lower95,
        upper95 = sim_upper95
      )
      
      rmse <- sqrt(mean((dados_plot$casos_reais - dados_plot$casos_median)^2, na.rm = TRUE))
      mae  <- mean(abs(dados_plot$casos_reais - dados_plot$casos_median), na.rm = TRUE)
      
      rmse_resultados <- rbind(rmse_resultados,
                               data.frame(uf = estado, rmse = rmse, mae = mae))
      
      plot_list[[estado]] <- ggplot(dados_plot, aes(x = date)) +
        geom_ribbon(aes(ymin = lower95, ymax = upper95), fill = "blue", alpha = 0.2) +
        geom_line(aes(y = casos_reais), color = "black", size = 1) +
        geom_line(aes(y = casos_median), color = "red", linetype = "dashed", size = 1) +
        labs(
          title = paste0(estado, 
                         " | RMSE: ", round(rmse, 1)),
          y = "Casos", x = "Data"
        ) +
        theme_minimal() +
        theme(legend.position = "none")
    }
  }
  fim <- Sys.time()
  print(fim - ini)
}

stopCluster(cl)

combined_plot <- wrap_plots(plot_list) +
  plot_layout(guides = "collect") &
  theme(legend.position = "bottom")

print(rmse_resultados %>% arrange(rmse))
print(combined_plot)

ggsave(filename = "resultados/Resultados_SprintDengue_treino3.png", plot = combined_plot, width = 14, height = 8, units = "in")

save.image(file = "resultados/Resultados_SprintDengue_treino3.RData")
