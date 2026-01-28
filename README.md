# LaCiD UFRN ARIMAX Model

A CHAP-compatible ARIMAX (AutoRegressive Integrated Moving Average with eXogenous variables) model for disease prediction.

## Overview

This model was developed by the [LaCiD](https://lacid.ccet.ufrn.br/) (Laboratório de Ciência de Dados) team at Federal University of Rio Grande do Norte (UFRN) for the 2025 Infodengue-Mosqlimate Dengue Forecast Sprint.

It has been adapted to be compatible with [CHAP](https://github.com/dhis2-chap/chap-core) (Climate Health Analytics Platform).

## Team

* [Marcus A. Nunes](https://lacid.ccet.ufrn.br/author/marcus-a.-nunes/) - Federal University of Rio Grande do Norte
* [Eliardo G. Costa](https://lacid.ccet.ufrn.br/author/eliardo-g.-costa/) - Federal University of Rio Grande do Norte
* [Marcelo Bourguignon](https://lacid.ccet.ufrn.br/author/marcelo-bourguignon/) - Federal University of Rio Grande do Norte
* [Thiago Valentim Marques](https://lacid.ccet.ufrn.br/author/thiago-valentim-marques/) - Federal University of Rio Grande do Norte
* [Thiago Zaqueu Lima](https://lacid.ccet.ufrn.br/author/thiago-zaqueu-lima/) - Federal University of Rio Grande do Norte

## Model Description

### Algorithm
- Uses `auto.arima()` from the R `forecast` package
- Trains separate ARIMAX models per location
- Applies Box-Cox transformation for variance stabilization
- Uses lagged features: disease_cases (lags 1-3), mean_temperature (lag 1)

### Required Data
- `disease_cases` - Target variable (case counts)
- `mean_temperature` - Temperature covariate
- `population` - Population count (required by CHAP)

### Output
- Generates probabilistic predictions with 1000 Monte Carlo samples
- Output columns: `time_period`, `location`, `sample_0` through `sample_999`

## CHAP Repository Structure

```
├── MLproject              # CHAP integration configuration
├── train.R                # Training script
├── predict.R              # Prediction script
├── isolated_run.R         # Local testing without CHAP
├── lib.R                  # Shared utility functions
├── Dockerfile             # R environment with forecast package
├── input/                 # Example data directory
│   ├── trainData.csv      # Example training data
│   └── futureClimateData.csv  # Example future data
├── output/                # Output directory for models/predictions
└── original/              # Original sprint code (reference only)
```

## Usage

### With Docker (recommended)

```bash
# Build Docker image
docker build -t lacid-arimax .

# Run isolated test
docker run -v $(pwd)/input:/app/input -v $(pwd)/output:/app/output lacid-arimax

# Or run train and predict separately
docker run -v $(pwd)/input:/app/input -v $(pwd)/output:/app/output lacid-arimax \
    Rscript train.R input/trainData.csv output/model.rds

docker run -v $(pwd)/input:/app/input -v $(pwd)/output:/app/output lacid-arimax \
    Rscript predict.R output/model.rds input/trainData.csv input/futureClimateData.csv output/predictions.csv
```

### Local R Installation

Requirements: R >= 4.0 with `forecast` and `data.table` packages.

```bash
# Install dependencies
Rscript -e "install.packages(c('forecast', 'data.table'))"

# Run isolated test
Rscript isolated_run.R

# Or run separately
Rscript train.R input/trainData.csv output/model.rds
Rscript predict.R output/model.rds input/trainData.csv input/futureClimateData.csv output/predictions.csv
```

## References

Xavier, L. L., Pessanha, J. F. M., Honório, N. A., Ribeiro, M. S., Moreira, D. M., & Peiter, P. C. (2025). A incidência da dengue explicada por variáveis climáticas em municípios da Região Metropolitana do Rio de Janeiro. *Trends in Computational and Applied Mathematics*, 26, e01476. [https://doi.org/10.5540/tcam.2025.026.e01476](https://doi.org/10.5540/tcam.2025.026.e01476)

## License

GNU General Public License v3 (GPL-3.0)
