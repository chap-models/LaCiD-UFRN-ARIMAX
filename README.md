# LaCiD-UFRN-ARIMAX - CHAP Compatible

[![R](https://img.shields.io/badge/R-≥4.0-blue.svg)](https://www.r-project.org/)

## Overview

This is a [CHAP-compatible](https://github.com/dhis2-chap/chap-core) version of an ARIMAX model originally developed for dengue prediction in Brazilian states. The original model was created for the [Mosqlimate Sprint competition](https://api.mosqlimate.org/vis/dashboard/?dashboard=sprint) by the LaCiD team at Federal University of Rio Grande do Norte (UFRN).

The model uses ARIMAX (AutoRegressive Integrated Moving Average with eXogenous variables) time series modeling to predict weekly disease cases, incorporating temperature as an exogenous covariate.

## Quick Start

```bash
# With Docker (recommended)
docker build -t lacid-arimax .
docker run -v $(pwd)/input:/app/input -v $(pwd)/output:/app/output lacid-arimax

# Or with local R installation
Rscript -e "install.packages(c('forecast', 'data.table'))"
Rscript isolated_run.R
```

## Repository Structure

```
├── MLproject              # CHAP integration configuration
├── Dockerfile             # R environment definition
├── train.R                # Training script
├── predict.R              # Prediction script
├── lib.R                  # Shared utility functions
├── isolated_run.R         # Local testing without CHAP
├── input/                 # Example data
│   ├── trainData.csv
│   └── futureClimateData.csv
├── output/                # Generated models and predictions
└── original/              # Original sprint code (reference)
```

## Model Methodology

### ARIMAX Configuration

- **Model selection**: `auto.arima()` with stepwise search
- **Seasonal**: Weekly periodicity (frequency = 52)
- **Transformation**: Box-Cox for variance stabilization
- **Exogenous variables**: Lagged cases (1-3 weeks), lagged temperature (1 week)
- **Training**: Separate model fitted per location

### Features Used

- `disease_cases` - Target variable (with Box-Cox transformation)
- `mean_temperature` - Temperature covariate (lagged)
- Autoregressive lags of transformed cases

### Uncertainty Quantification

- 1000 Monte Carlo simulations per prediction
- Full predictive distribution available via sample columns

## CHAP Data Format

**Training data** (`trainData.csv`):
- `time_period` - Week identifier (e.g., `2023W01`)
- `location` - Spatial identifier
- `disease_cases` - Target variable
- `population` - Population (required by CHAP)
- `mean_temperature` - Temperature covariate
- `rainfall` - Rainfall covariate (present but not used by this model)

**Future data** (`futureClimateData.csv`):
- Same columns as training, without `disease_cases`

**Output** (`predictions.csv`):
- `time_period`, `location`, `sample_0` through `sample_999`

## Usage

### Local Testing

```bash
Rscript isolated_run.R
```

### Train and Predict Separately

```bash
Rscript train.R input/trainData.csv output/model.rds
Rscript predict.R output/model.rds input/trainData.csv input/futureClimateData.csv output/predictions.csv
```

### With Docker

```bash
docker build -t lacid-arimax .
docker run -v $(pwd)/input:/app/input -v $(pwd)/output:/app/output lacid-arimax \
    Rscript train.R input/trainData.csv output/model.rds
docker run -v $(pwd)/input:/app/input -v $(pwd)/output:/app/output lacid-arimax \
    Rscript predict.R output/model.rds input/trainData.csv input/futureClimateData.csv output/predictions.csv
```

## Original Work

This model is adapted from the [LaCiD/UFRN submission](https://github.com/lacidufrn/infodengue_sprint_2025) to the 2025 Infodengue-Mosqlimate Dengue Forecast Sprint. The original implementation predicted dengue cases across 26 Brazilian states using data from the [InfoDengue surveillance system](https://info.dengue.mat.br/).

### Original Team

- Marcus A. Nunes
- Eliardo G. Costa
- Marcelo Bourguignon
- Thiago Valentim Marques
- Thiago Zaqueu Lima

### Reference

Xavier, L. L., et al. (2025). "A incidência da dengue explicada por variáveis climáticas em municípios da Região Metropolitana do Rio de Janeiro." *Trends in Computational and Applied Mathematics*, 26, e01476. [https://doi.org/10.5540/tcam.2025.026.e01476](https://doi.org/10.5540/tcam.2025.026.e01476)
