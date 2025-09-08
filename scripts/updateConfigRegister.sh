#!/bin/bash
set -euo pipefail

BUS_WIDTH=32
ADDR_WIDTH=3
BUS_PROTOCOL="apb4"
BUILD_DIR="build"
CLEAN_FLAG=false
VIVADO_PARMS="--R"

INPUT_XML="../build/ipxact/ipMap.xml"
OUTPUT_DIR="../build/rtl"

# help function
show_help() {
    echo "Use: $0 [Options]"
    echo ""
    echo "Options:"
    echo "  -c              Clean build directory before running"
    echo "  -b WIDTH        Bus width (default: 32)"
    echo "  -a WIDTH        Address width (default: 3)"
    echo "  -p PROTOCOL     Bus protocol (default: axi4lite)"
    echo "  -d DIR          Build directory (default: build)"
    echo "  -h              Show this help"
    echo "  --v|-vivado <\"--vivado_params\">  Pass Vivado parameters"
    echo ""
    echo "Examples:"
    echo "  $0 -c -b 64 -a 4 -p axi4"
    echo "  $0 -b 32 -a 3"
    echo "  $0 -c"
}

# function to show error and exit program
error_exit() {
    echo "❌ Error in step: $1"
    exit 1
}

# Function to clear build directory
clean_build() {
    echo "🧹 Cleaning build directory..."
    if [ -d "${BUILD_DIR}" ]; then
        rm -rf "${BUILD_DIR}"/*
        echo "✅ Build directory cleaned"
    else
        echo "ℹ️  Build directory does not exist, nothing to clean"
    fi
}

# Process arguments
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
            # unexpected argment
            echo "❌ Argumento inesperado: $1" >&2
            show_help
            exit 1
            ;;
    esac
done

# Perform cleanup if the -c flag was passed
if [ "$CLEAN_FLAG" = true ]; then
    clean_build
    echo "✅ Cleanup completed successfully!"
fi

echo "Step 0: Checking/Creating directory structure..."
# Create main build directory if it doesn't exist
mkdir -p "${BUILD_DIR}"

# Create subdirectories inside build if they don't exist
for subdir in "csv" "rtl" "ipxact"; do
    dir_path="${BUILD_DIR}/${subdir}"
    if [ ! -d "${dir_path}" ]; then
        echo "Creating directory: ${dir_path}"
        mkdir -p "${dir_path}"
    else
        echo "Directory already exists: ${dir_path}"
    fi
done

echo "🔄 Starting LaTeX -> RTL translation pipeline"

echo "Step 1: Converting LaTeX to CSV..."
if ! python3 scripts/latex2csv.py; then
    error_exit "LaTeX to CSV"
fi

echo "Step 2: Converting CSV to IP-XACT (BUS_WIDTH=${BUS_WIDTH})..."
if ! python3 scripts/csv2ipxact.py -s "${BUS_WIDTH}"; then
    error_exit "CSV to IP-XACT"
fi

echo "Step 3: Generating RTL from IP-XACT..."
if ! python3 "scripts/ipxact2rtl.py" "$INPUT_XML" "$OUTPUT_DIR"; then
    error_exit "IP-XACT to RTL"
fi

echo "Step 4: Generating bus connection for the RegMap (BUS_WIDTH=${BUS_WIDTH}, ADDR_WIDTH=${ADDR_WIDTH}, BUS_PROTOCOL=${BUS_PROTOCOL})..."
if ! python3 scripts/gen_bus_csr.py --bus "${BUS_PROTOCOL}" --data-width "${BUS_WIDTH}" --addr-width "${ADDR_WIDTH}"; then
    error_exit "Generate bus logic"
fi

echo "Step 5: Vivado integration"
./scripts/xrun.sh -top ${BUS_PROTOCOL}_tb -vivado ${VIVADO_PARMS}

echo "✅ Pipeline finish with success!"