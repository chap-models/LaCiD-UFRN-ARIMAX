# script para analise exploratoria dos dados, a fim de conhecê-los e gerar 
# ideias para a modelagem. de acordo com o regulamento,
# 
# Predictions should be made for all 27 Brazilian federative 
# units
# 
# dessa forma, é interessante agregar os dados que temos 
# por uf
# 
# o dicionário de dados está disponível em
# 
# https://sprint.mosqlimate.org/data/
# 
# IMPORTANTE: Data for the state of ES are not available due to reporting issues

###############
### dengue ####
###############

library(tidyverse)
theme_set(theme_minimal())
library(data.table)

dengue_original <- fread(file = "data/dengue.csv")

head(dengue_original)

# as colunas train_i e test_i, i \in {1, 2, 3}, indicam que linhas
# devem ser usadas para os treinos e validações das etapas 1, 2, e 3


###########
### train 1

dengue_treino_1 <- 
  dengue_original |> 
  filter(train_1 == TRUE) |> 
  group_by(uf, epiweek, date) |> 
  summarise(casos = sum(casos)) |> 
  ungroup()
  
dengue_treino_1 |> 
  filter(uf == "RN") |> 
  ggplot(aes(x = date, y = casos)) + 
  geom_line() + 
  labs(x = "Data", y = "Casos", title = "Muitos picos, talvez seja mais complicado modelar")

dengue_treino_1 |> 
  filter(uf == "RN") |> 
  ggplot(aes(x = date, y = casos)) + 
  geom_line() + 
  scale_y_continuous(transform = "log10") + 
  labs(x = "Data", y = "log10(Casos)", title = "Dá uma suavizada boa, talvez facilite")

dengue_treino_1 |> 
  ggplot(aes(x = date, y = casos)) + 
  geom_line() + 
  facet_wrap(~ uf, scales = "free") + 
  labs(x = "Data", y = "log10(Casos)")

dengue_treino_1 |> 
  ggplot(aes(x = date, y = casos)) + 
  geom_line() + 
  facet_wrap(~ uf, scales = "free") + 
  scale_y_continuous(transform = "log10") + 
  labs(x = "Data", y = "log10(Casos)", title = "Há UFs com zero casos em algumas semanas")







