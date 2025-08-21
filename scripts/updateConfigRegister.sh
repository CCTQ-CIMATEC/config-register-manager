#!/bin/bash
set -euo pipefail

BUS_WIDTH=32
BUILD_DIR="build"

# Função para exibir erro e sair
error_exit() {
    echo "❌ Erro na etapa: $1"
    exit 1
}

echo "Etapa 0: Verificando/Criando estrutura de diretórios..."
# Criar diretório build principal se não existir
mkdir -p "${BUILD_DIR}"

# Criar subdiretórios dentro de build se não existirem
for subdir in "csv" "rtl" "ipxact"; do
    dir_path="${BUILD_DIR}/${subdir}"
    if [ ! -d "${dir_path}" ]; then
        echo "Criando diretório: ${dir_path}"
        mkdir -p "${dir_path}"
    else
        echo "Diretório já existe: ${dir_path}"
    fi
done

echo "🔄 Iniciando pipeline de tradução LaTeX -> RTL"

echo "Etapa 1: Convertendo LaTeX para CSV..."
if ! python3 tools/latex2csv.py; then
    error_exit "LaTeX para CSV"
fi

echo "Etapa 2: Convertendo CSV para IP-XACT (BUS_WIDTH=${BUS_WIDTH})..."
if ! python3 scripts/csv2ipxact.py -s "${BUS_WIDTH}"; then
    error_exit "CSV para IP-XACT"
fi

echo "Etapa 3: Gerando RTL a partir do IP-XACT..."
if ! scripts/ipxact2rtl.sh; then
    error_exit "IP-XACT para RTL"
fi

echo "✅ Pipeline concluído com sucesso!"
