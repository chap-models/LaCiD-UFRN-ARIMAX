# Dockerfile for LaCiD ARIMAX Model
# Based on rocker/r-ver with forecast package

FROM rocker/r-ver:4.3.2

LABEL org.opencontainers.image.title="LaCiD UFRN ARIMAX Model"
LABEL org.opencontainers.image.description="ARIMAX model for disease prediction using R forecast package"
LABEL org.opencontainers.image.vendor="LaCiD - UFRN"
LABEL org.opencontainers.image.source="https://github.com/chap-models/LaCiD-UFRN-ARIMAX"

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    libcurl4-openssl-dev \
    libssl-dev \
    libxml2-dev \
    && rm -rf /var/lib/apt/lists/*

# Install R packages
RUN R -e "install.packages(c('forecast', 'data.table'), repos='https://cloud.r-project.org/')"

# Set working directory
WORKDIR /app

# Copy R scripts
COPY train.R predict.R lib.R isolated_run.R ./

# Create input/output directories
RUN mkdir -p /app/input /app/output

# Default command
CMD ["Rscript", "isolated_run.R"]
