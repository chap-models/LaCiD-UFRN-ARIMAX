# script para instalacao dos pacotes necessarios para a 
# analise de dados da 2025 sprint:
# 
# https://sprint.mosqlimate.org/
#
# este script encontra os pacotes instalados na maquina 
# do usuario e baixa e instala apenas aqueles que estao
# faltando.
# 
# adicione ao vetor `pacotes_necessarios` abaixo aqueles
# que achar necessarios para as suas analises, de preferencia 
# em ordem alfabetica
# 
# autor: Marcus Nunes 
# site:  https://marcusnunes.me

# repositorio de pacotes

options(repos = c(CRAN = "http://cran.rstudio.com"))

# lista de pacotes necessarios

pacotes_necessarios <- c("bonsai", 
                         "corrplot",
                         "data.table",
                         "e1071", 
                         "GGally", 
                         "ggfortify", 
                         "janitor", 
                         "kknn", 
                         "lightgbm",
                         "pak", 
                         "patchwork",
                         "pROC", 
                         "prophet",
                         "randomForest", 
                         "rvest", 
                         "scales", 
                         "stringr", 
                         "switchr",
                         "themis", 
                         "tidymodels", 
                         "tidyverse",
                         "vip",
                         "xts")

# instalacao dos pacotes que faltam na maquina

pacotes_novos <- pacotes_necessarios[!(pacotes_necessarios %in% installed.packages()[,"Package"])]

if(length(pacotes_novos)) {
  install.packages(pacotes_novos, dependencies = TRUE)
  print("##########################")
  print("### Pacotes instalados ###")
  print("##########################")
} 

# atualizacao dos pacotes jah instalados

update.packages(ask = FALSE)

print("###########################")
print("### Pacotes atualizados ###")
print("###########################")

# 


