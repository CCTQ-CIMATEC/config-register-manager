#!/bin/bash
set -euo pipefail

BUS_WIDTH=32
ADDR_WIDTH=3
BUS_PROTOCOL="apb4"
BUILD_DIR="build"
CLEAN_FLAG=false
VIVADO_PARMS="--R"

# Função para exibir ajuda
show_help() {
    echo "Uso: $0 [OPÇÕES]"
    echo ""
    echo "Opções:"
    echo "  -c              Limpar diretório build antes de executar"
    echo "  -b WIDTH        Largura do barramento (padrão: 32)"
    echo "  -a WIDTH        Largura do endereço (padrão: 3)"
    echo "  -p PROTOCOL     Protocolo do barramento (padrão: axi4lite)"
    echo "  -d DIR          Diretório de build (padrão: build)"
    echo "  -h              Mostrar esta ajuda"
    echo "  --v|-vivado <\"--vivado_params\">  Pass Vivado parameters"
    echo ""
    echo "Exemplos:"
    echo "  $0 -c -b 64 -a 4 -p axi4"
    echo "  $0 -b 32 -a 3"
    echo "  $0 -c"
}

# Função para exibir erro e sair
error_exit() {
    echo "❌ Erro na etapa: $1"
    exit 1
}

# Função para limpar o diretório build
clean_build() {
    echo "🧹 Limpando diretório build..."
    if [ -d "${BUILD_DIR}" ]; then
        rm -rf "${BUILD_DIR}"/*
        echo "✅ Diretório build limpo"
    else
        echo "ℹ️  Diretório build não existe, nada para limpar"
    fi
}

# Processar argumentos
while [[ $# -gt 0 ]]; do
    case $1 in
        -c)
            CLEAN_FLAG=true
            shift
            ;;
        -b)
            BUS_WIDTH="$2"
            shift 2
            ;;
        -a)
            ADDR_WIDTH="$2"
            shift 2
            ;;
        -p)
            BUS_PROTOCOL="$2"
            shift 2
            ;;
        -d)
            BUILD_DIR="$2"
            shift 2
            ;;
        -h)
            show_help
            exit 0
            ;;
        --vivado)
            shift
            VIVADO_PARMS="$1"
            echo "INFO: Parameters '${VIVADO_PARMS}' are being passed directly to Vivado"
            shift
            ;;
        -*)
            echo "❌ Opção inválida: $1" >&2
            show_help
            exit 1
            ;;
        *)
            # argumento extra inesperado
            echo "❌ Argumento inesperado: $1" >&2
            show_help
            exit 1
            ;;
    esac
done

# Executar limpeza se a flag -c foi passada
if [ "$CLEAN_FLAG" = true ]; then
    clean_build
    echo "✅ Limpeza concluída com sucesso!"
fi

echo "Etapa 0: Verificando/Criando estrutura de diretórios..."
mkdir -p "${BUILD_DIR}"

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
if ! bash scripts/ipxact2rtl.sh; then
    error_exit "IP-XACT para RTL"
fi

echo "Etapa 4: Gerando conexão com barramento para o RegMap (BUS_WIDTH=${BUS_WIDTH}, ADDR_WIDTH=${ADDR_WIDTH}, BUS_PROTOCOL=${BUS_PROTOCOL})..."
if ! python3 scripts/gen_bus_csr.py --bus "${BUS_PROTOCOL}" --data-width "${BUS_WIDTH}" --addr-width "${ADDR_WIDTH}"; then
    error_exit "Generate bus logic"
fi

echo "Etapa 5: Integração com Vivado"
# ⚠️ No Windows, esse path não existe. 
# Se você tiver Vivado instalado em C:/Xilinx, ajuste o caminho abaixo.
if [ -f "/opt/Xilinx/Vitis/2024.1/settings64.sh" ]; then
    source /opt/Xilinx/Vitis/2024.1/settings64.sh
fi

./scripts/xrun.sh -top ${BUS_PROTOCOL}_tb -vivado ${VIVADO_PARMS}

echo "✅ Pipeline concluído com sucesso!"