# script para download dos dados necessarios para a 
# modelagem da 2025 sprint:
# 
# https://sprint.mosqlimate.org/
#
# este script baixa na pasta dados/ os arquivos .csv compartilhados
# pela organizacao do evento em https://sprint.mosqlimate.org/data/
# 
# autor: Marcus Nunes 
# site:  https://marcusnunes.me


# vai ser necessario autenticar a sua conta no google antes de
# baixar os arquivos. rode os comandos baixo e seu browser vai abrir
# para realizar este procedimento semiautomaticamente

library(googledrive)

drive_download("https://drive.google.com/file/d/1wehdwdoStF7D7d-zQNC5HfBx8kbadpjf/view?usp=drive_link", type = "csv", path = "data/climate.csv", overwrite = TRUE)

drive_download("https://drive.google.com/file/d/1bCHZulY4Nh-QSJFy3Zan8mPb_bNfkdKe/view?usp=drive_link", type = "csv", path = "data/datasus_population_2001_2024.csv", overwrite = TRUE)

drive_download("https://drive.google.com/file/d/1sykd5edbhH77eYPBE1l7HZL4clSK19SD/view?usp=drive_link", type = "csv", path = "data/dengue.csv", overwrite = TRUE)

drive_download("https://drive.google.com/file/d/16-HHNGZUtBBFScamIFHfHwP86NVSk3aG/view?usp=drive_link", type = "csv", path = "data/environ_vars.csv", overwrite = TRUE)

drive_download("https://drive.google.com/file/d/1J75LFjc8mBnr8sZImZAAod8tpFji8MW2/view?usp=drive_link", type = "csv", path = "data/forecasting_climate.csv", overwrite = TRUE)

drive_download("https://drive.google.com/file/d/1Qa1iUpF1pzKJpskDyjJ8aFUZsOOpUeFs/view?usp=drive_link", type = "csv", path = "data/ocean_climate_oscillations.csv", overwrite = TRUE)

drive_download("https://drive.google.com/file/d/1igLtlTzZ1yYqcYSfRDfLbcKbCTxtpfLY/view?usp=drive_link", type = "csv", path = "data/shape_muni.gpkg", overwrite = TRUE)



