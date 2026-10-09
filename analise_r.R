
library(tidyverse)
library(janitor)
library(fs)

# Leitura dos Dados -------------------------------------------------------

#Caminhos dos arquivos
caminhos_amostras_estimuladas     <- c(
  "amostras/Pesquisa_Eleitoral_Amostra_1.csv",
  "amostras/Pesquisa_Eleitoral_Amostra_2.csv"
  )
caminhos_amostras_nao_estimuladas <- c(
  "amostras/Pesquisa_Eleitoral_Amostra_3.csv",
  "amostras/Pesquisa_Eleitoral_Amostra_4.csv"
)

#Função para ler o arquivo .csv
ler_amostra <- function(caminho){
  read_csv(
    caminho,
    locale = locale(encoding = "UTF-8"),
    show_col_types = FALSE
    ) |> 
    clean_names()
}

#Amostras seperadas pelo método de coleta
dados_amostras_estimuladas     <- map_dfr(
  caminhos_amostras_estimuladas, 
  ler_amostra
  )
dados_amostras_nao_estimuladas <- map_dfr(
  caminhos_amostras_nao_estimuladas, 
  ler_amostra
)

#Amostra completa
dados_completos <- bind_rows(
  dados_amostras_estimuladas,
  dados_amostras_nao_estimuladas
)


