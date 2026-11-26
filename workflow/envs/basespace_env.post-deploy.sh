#!/usr/bin/env bash
set -euo pipefail

# Baixa o binário oficial do BaseSpace CLI para dentro do ambiente Conda
wget "https://launch.basespace.illumina.com/CLI/latest/amd64-linux/bs" \
    -O "$CONDA_PREFIX/bin/bs"

chmod u+x "$CONDA_PREFIX/bin/bs"

# Verifica a instalação
"$CONDA_PREFIX/bin/bs" --version
