#!/usr/bin/env python3
"""
Conversor IP-XACT para RTL (SystemVerilog) - Especializado para Enhanced_Register_Bank
Gera um banco de registros APB com interfaces UART e PWM a partir de ipMap.xml.
Saída: ../build/rtl_out/Enhanced_Register_Bank.sv
"""

import xml.etree.ElementTree as ET
import os
import sys
from datetime import datetime
from pathlib import Path

# Namespace IP-XACT
NS = {'ipxact': 'http://www.accellera.org/XMLSchema/IPXACT/1685-2014'}

def get_absolute_path(relative_path):
    """Converte caminhos relativos em absolutos baseado na localização do script."""
    script_dir = Path(__file__).parent
    return (script_dir / relative_path).resolve()

def parse_ipxact(input_xml):
    """Extrai dados do IP-XACT (registros, interfaces APB, campos)."""
    try:
        input_path = get_absolute_path(input_xml)
        tree = ET.parse(input_path)
        root = tree.getroot()
        
        # Informações do componente
        component = root
        name = component.find('ipxact:name', NS).text
        
        # Verifica interface APB
        if component.find('.//ipxact:busInterface[ipxact:name="APB"]', NS) is None:
            raise ValueError("Interface APB não encontrada no IP-XACT")
        
        # Processa registros e campos
        registers = []
        for addr_block in component.findall('.//ipxact:addressBlock', NS):
            block_name = addr_block.find('ipxact:name', NS).text
            base_addr = addr_block.find('ipxact:baseAddress', NS).text
            
            for reg in addr_block.findall('ipxact:register', NS):
                reg_name = reg.find('ipxact:name', NS).text
                offset = reg.find('ipxact:addressOffset', NS).text
                access = reg.find('ipxact:access', NS).text
                
                fields = []
                for field in reg.findall('ipxact:field', NS):
                    fields.append({
                        'name': field.find('ipxact:name', NS).text,
                        'offset': int(field.find('ipxact:bitOffset', NS).text),
                        'width': int(field.find('ipxact:bitWidth', NS).text),
                        'connect': field.find('.//ipxact:connectTo', NS).text if field.find('.//ipxact:connectTo', NS) is not None else None
                    })
                
                registers.append({
                    'block': block_name,
                    'name': reg_name,
                    'offset': offset,
                    'access': access,
                    'fields': fields,
                    'full_address': f"{base_addr[:-3]}{offset[2:]}"  # Formata endereço (ex: 0x40000000 + 0x04 -> 0x40000004)
                })
        
        return {
            'name': name,
            'interface': 'APB',
            'registers': registers
        }
    
    except ET.ParseError as e:
        print(f"Erro no XML: {str(e)}", file=sys.stderr)
    except FileNotFoundError:
        print(f"Arquivo não encontrado: {input_xml}", file=sys.stderr)
    except Exception as e:
        print(f"Erro inesperado: {type(e).__name__}: {str(e)}", file=sys.stderr)
    return None

def generate_rtl(ipxact_data, output_dir):
    """Gera o arquivo RTL em SystemVerilog."""
    try:
        output_path = get_absolute_path(output_dir)
        output_path.mkdir(parents=True, exist_ok=True)
        output_file = output_path / f"{ipxact_data['name']}.sv"
        
        with open(output_file, 'w', encoding='utf-8') as f:
            # Cabeçalho
            f.write(f"// Módulo {ipxact_data['name']} - Gerado automaticamente em {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n")
            f.write("// Interface APB com registros para UART e PWM\n\n")
            f.write("`timescale 1ns/1ps\n\n")
            
            # Declaração do módulo
            f.write(f"module {ipxact_data['name']} (\n")
            f.write("    // Interface APB\n")
            f.write("    input logic          PCLK,\n")
            f.write("    input logic          PRESETn,\n")
            f.write("    input logic          PSEL,\n")
            f.write("    input logic          PENABLE,\n")
            f.write("    input logic [31:0]   PADDR,\n")
            f.write("    input logic          PWRITE,\n")
            f.write("    input logic [31:0]   PWDATA,\n")
            f.write("    output logic [31:0]  PRDATA,\n")
            f.write("    output logic         PREADY,\n")
            f.write("    output logic         PSLVERR,\n")
            
            # Conexões externas (UART/PWM)
            f.write("\n    // Sinais externos\n")
            connections = sorted({field['connect'] for reg in ipxact_data['registers'] for field in reg['fields'] if field['connect']})
            for i, conn in enumerate(connections):
                direction = 'output' if any(reg['access'] == 'read-only' for reg in ipxact_data['registers'] for field in reg['fields'] if field['connect'] == conn) else 'input'
                f.write(f"    {direction} logic {conn}{',' if i < len(connections)-1 else ''}\n")
            
            f.write(");\n\n")
            
            # Lógica APB
            f.write("    // Decodificador de endereços\n")
            f.write("    always_ff @(posedge PCLK or negedge PRESETn) begin\n")
            f.write("        if (!PRESETn) begin\n")
            f.write("            PRDATA <= 32'h0;\n")
            f.write("            PREADY <= 1'b0;\n")
            f.write("        end\n")
            f.write("        else if (PSEL && !PENABLE) begin\n")
            f.write("            PREADY <= 1'b1;\n")
            
            # Registros
            for reg in ipxact_data['registers']:
                f.write(f"            if (PADDR == 32'h{reg['full_address']}) begin\n")
                if reg['access'] == 'read-write':
                    f.write("                if (PWRITE) begin\n")
                    for field in reg['fields']:
                        if field['connect']:
                            f.write(f"                    {field['connect']} <= PWDATA[{field['offset'] + field['width'] - 1}:{field['offset']}];\n")
                    f.write("                end else begin\n")
                    f.write("                    PRDATA <= '0;\n")
                    for field in reg['fields']:
                        if field['connect']:
                            f.write(f"                    PRDATA[{field['offset'] + field['width'] - 1}:{field['offset']}] <= {field['connect']};\n")
                    f.write("                end\n")
                else:  # read-only
                    f.write("                PRDATA <= '0;\n")
                    for field in reg['fields']:
                        if field['connect']:
                            f.write(f"                PRDATA[{field['offset'] + field['width'] - 1}:{field['offset']}] <= {field['connect']};\n")
                f.write("            end\n")
            
            f.write("        end else begin\n")
            f.write("            PREADY <= 1'b0;\n")
            f.write("        end\n")
            f.write("    end\n\n")
            
            # Finalização
            f.write("    assign PSLVERR = 1'b0;  // Sem erros\n")
            f.write("endmodule\n")
        
        print(f"RTL gerado em: {output_file}")
        return True
    
    except Exception as e:
        print(f"Falha ao gerar RTL: {str(e)}", file=sys.stderr)
        return False

if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("Uso: python3 ipxact2rtl.py <input.xml> <output_dir>")
        sys.exit(1)
        
    INPUT_XML = sys.argv[1]
    OUTPUT_DIR = sys.argv[2]
    
    print(f"⚡ Convertendo: {INPUT_XML}")
    ip_data = parse_ipxact(INPUT_XML)
    
    if ip_data:
        success = generate_rtl(ip_data, OUTPUT_DIR)
        if success:
            print(f"✅ Conversão concluída! Verifique {OUTPUT_DIR}")
            sys.exit(0)
    
    print("❌ Falha na conversão")
    sys.exit(1)