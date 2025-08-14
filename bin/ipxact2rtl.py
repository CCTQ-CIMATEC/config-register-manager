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
    """Extrai dados do IP-XACT para geração de CSR."""
    try:
        input_path = get_absolute_path(input_xml)
        tree = ET.parse(input_path)
        root = tree.getroot()
        
        # Informações do componente
        component = root
        name = component.find('ipxact:name', NS).text
        
        # Processa registros e campos
        registers = {}
        for addr_block in component.findall('.//ipxact:addressBlock', NS):
            for reg in addr_block.findall('ipxact:register', NS):
                reg_name = reg.find('ipxact:name', NS).text
                offset_elem = reg.find('ipxact:addressOffset', NS)
                size_elem = reg.find('ipxact:size', NS)
                
                offset = offset_elem.text if offset_elem is not None else "'h0"
                size = int(size_elem.text) if size_elem is not None else 32
                
                fields = {}
                for field in reg.findall('ipxact:field', NS):
                    field_name = field.find('ipxact:name', NS).text
                    bit_offset = int(field.find('ipxact:bitOffset', NS).text)
                    bit_width = int(field.find('ipxact:bitWidth', NS).text)
                    
                    # Acesso (read-write, read-only, write-only)
                    access_elem = field.find('ipxact:access', NS)
                    access = access_elem.text if access_elem is not None else 'read-write'
                    
                    # Volatile
                    volatile_elem = field.find('ipxact:volatile', NS)
                    volatile = volatile_elem is not None and volatile_elem.text.lower() == 'true'
                    
                    # Reset value
                    reset_elem = field.find('.//ipxact:value', NS)
                    reset_value = reset_elem.text if reset_elem is not None else "'h0"
                    
                    # Descrição
                    desc_elem = field.find('ipxact:description', NS)
                    description = desc_elem.text if desc_elem is not None else ""
                    
                    fields[field_name] = {
                        'bit_offset': bit_offset,
                        'bit_width': bit_width,
                        'access': access,
                        'volatile': volatile,
                        'reset_value': reset_value,
                        'description': description
                    }
                
                registers[reg_name] = {
                    'offset': offset,
                    'size': size,
                    'fields': fields
                }
        
        return {
            'name': name,
            'registers': registers
        }
    
    except ET.ParseError as e:
        print(f"Erro no XML: {str(e)}", file=sys.stderr)
    except FileNotFoundError:
        print(f"Arquivo não encontrado: {input_xml}", file=sys.stderr)
    except Exception as e:
        print(f"Erro inesperado: {type(e).__name__}: {str(e)}", file=sys.stderr)
    return None

def needs_hw_input(field_info):
    """Verifica se o campo precisa de entrada de hardware"""
    return (field_info['volatile'] or 
            field_info['access'] == 'read-only' or
            'master mode will be cleared' in field_info.get('description', '').lower())

def format_reset_value(reset_value, bit_width):
    """Formata o valor de reset com a largura correta"""
    if reset_value.startswith("'h"):
        return f"{bit_width}{reset_value}"
    return reset_value

def generate_package(ipxact_data, output_dir):
    """Gera o arquivo package SystemVerilog."""
    try:
        output_path = get_absolute_path(output_dir)
        output_path.mkdir(parents=True, exist_ok=True)
        output_file = output_path / f"{ipxact_data['name']}_pkg.sv"
        
        component_name = ipxact_data['name']
        registers = ipxact_data['registers']
        
        with open(output_file, 'w', encoding='utf-8') as f:
            # Cabeçalho
            f.write(f"// Package {component_name}_pkg - Gerado automaticamente em {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n")
            f.write("// Estruturas typedef para interface CSR\n\n")
            f.write(f"package {component_name}_pkg;\n\n")
            
            # Gera typedef structs para entrada (hardware -> registrador)
            f.write("    // Input structures (Hardware -> Register)\n")
            
            # Structs para campos individuais que precisam de entrada HW
            for reg_name, reg_info in registers.items():
                for field_name, field_info in reg_info['fields'].items():
                    if needs_hw_input(field_info):
                        f.write(f"    typedef struct {{\n")
                        
                        if field_info['bit_width'] > 1:
                            f.write(f"        logic [{field_info['bit_width']-1}:0] next;\n")
                        else:
                            f.write(f"        logic next;\n")
                            
                        f.write(f"        logic we;\n")
                        f.write(f"    }} {component_name}__{reg_name}__{field_name}__in_t;\n\n")
            
            # Structs para registradores com entrada HW
            for reg_name, reg_info in registers.items():
                hw_input_fields = [f for f, info in reg_info['fields'].items() if needs_hw_input(info)]
                if hw_input_fields:
                    f.write(f"    typedef struct {{\n")
                    for field_name in hw_input_fields:
                        f.write(f"        {component_name}__{reg_name}__{field_name}__in_t {field_name};\n")
                    f.write(f"    }} {component_name}__{reg_name}__in_t;\n\n")
            
            # Struct principal de entrada
            hw_input_regs = [r for r, info in registers.items() 
                            if any(needs_hw_input(f_info) for f_info in info['fields'].values())]
            if hw_input_regs:
                f.write(f"    typedef struct {{\n")
                for reg_name in hw_input_regs:
                    f.write(f"        {component_name}__{reg_name}__in_t {reg_name};\n")
                f.write(f"    }} {component_name}__in_t;\n\n")
            
            # Gera typedef structs para saída (registrador -> hardware)
            f.write("    // Output structures (Register -> Hardware)\n")
            
            # Structs para campos individuais
            for reg_name, reg_info in registers.items():
                for field_name, field_info in reg_info['fields'].items():
                    if field_info['access'] != 'write-only':
                        f.write(f"    typedef struct {{\n")
                        if field_info['bit_width'] > 1:
                            f.write(f"        logic [{field_info['bit_width']-1}:0] value;\n")
                        else:
                            f.write(f"        logic value;\n")
                        f.write(f"    }} {component_name}__{reg_name}__{field_name}__out_t;\n\n")
            
            # Structs para registradores
            for reg_name, reg_info in registers.items():
                output_fields = [f for f, info in reg_info['fields'].items() if info['access'] != 'write-only']
                if output_fields:
                    f.write(f"    typedef struct {{\n")
                    for field_name in output_fields:
                        f.write(f"        {component_name}__{reg_name}__{field_name}__out_t {field_name};\n")
                    f.write(f"    }} {component_name}__{reg_name}__out_t;\n\n")
            
            # Struct principal de saída
            f.write(f"    typedef struct {{\n")
            for reg_name in registers.keys():
                f.write(f"        {component_name}__{reg_name}__out_t {reg_name};\n")
            f.write(f"    }} {component_name}__out_t;\n\n")
            
            f.write("endpackage\n")
        
        print(f"Package gerado: {output_file}")
        return True
    
    except Exception as e:
        print(f"Falha ao gerar package: {str(e)}", file=sys.stderr)
        return False

def generate_logic(ipxact_data, output_dir):
    """Gera o arquivo de lógica SystemVerilog."""
    try:
        output_path = get_absolute_path(output_dir)
        output_path.mkdir(parents=True, exist_ok=True)
        output_file = output_path / f"{ipxact_data['name']}_logic.sv"
        
        component_name = ipxact_data['name']
        registers = ipxact_data['registers']
        
        with open(output_file, 'w', encoding='utf-8') as f:
            # Cabeçalho
            f.write(f"// Lógica {component_name} - Gerado automaticamente em {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n")
            f.write("// Lógica dos registradores CSR\n\n")
            
            # Estruturas de combinacional e storage
            f.write("    //--------------------------------------------------------------------------\n")
            f.write("    // Field logic\n")
            f.write("    //--------------------------------------------------------------------------\n")
            
            # field_combo_t
            f.write("    typedef struct {\n")
            for reg_name, reg_info in registers.items():
                f.write(f"        struct {{\n")
                for field_name, field_info in reg_info['fields'].items():
                    if field_info['access'] != 'read-only' or field_info['volatile']:
                        f.write(f"            struct {{\n")
                        if field_info['bit_width'] > 1:
                            f.write(f"                logic [{field_info['bit_width']-1}:0] next;\n")
                        else:
                            f.write(f"                logic next;\n")
                        f.write(f"                logic load_next;\n")
                        f.write(f"            }} {field_name};\n")
                f.write(f"        }} {reg_name};\n")
            f.write("    } field_combo_t;\n")
            f.write("    field_combo_t field_combo;\n\n")
            
            # field_storage_t
            f.write("    typedef struct {\n")
            for reg_name, reg_info in registers.items():
                f.write(f"        struct {{\n")
                for field_name, field_info in reg_info['fields'].items():
                    if field_info['access'] != 'read-only' or field_info['volatile']:
                        f.write(f"            struct {{\n")
                        if field_info['bit_width'] > 1:
                            f.write(f"                logic [{field_info['bit_width']-1}:0] value;\n")
                        else:
                            f.write(f"                logic value;\n")
                        f.write(f"            }} {field_name};\n")
                f.write(f"        }} {reg_name};\n")
            f.write("    } field_storage_t;\n")
            f.write("    field_storage_t field_storage;\n\n")
            
            # Lógica para cada campo
            for reg_name, reg_info in registers.items():
                for field_name, field_info in reg_info['fields'].items():
                    if field_info['access'] == 'read-only' and not field_info['volatile']:
                        continue
                        
                    f.write(f"    // Field: {component_name}.{reg_name}.{field_name}\n")
                    
                    # Lógica combinacional
                    bit_range = f"[{field_info['bit_width']-1}:0]" if field_info['bit_width'] > 1 else "[0:0]"
                    bit_select = f"[{field_info['bit_offset']+field_info['bit_width']-1}:{field_info['bit_offset']}]"
                    
                    f.write("    always_comb begin\n")
                    f.write(f"        automatic logic {bit_range} next_c;\n")
                    f.write(f"        automatic logic load_next_c;\n")
                    f.write(f"        next_c = field_storage.{reg_name}.{field_name}.value;\n")
                    f.write(f"        load_next_c = '0;\n")
                    
                    # Software write
                    if field_info['access'] in ['read-write', 'write-only']:
                        f.write(f"        if(decoded_reg_strb.{reg_name} && decoded_req_is_wr) begin // SW write\n")
                        f.write(f"            next_c = (field_storage.{reg_name}.{field_name}.value & ~decoded_wr_biten{bit_select}) | (decoded_wr_data{bit_select} & decoded_wr_biten{bit_select});\n")
                        f.write(f"            load_next_c = '1;\n")
                        f.write("        end")
                        
                    # Hardware write
                    if needs_hw_input(field_info):
                        if field_info['access'] in ['read-write', 'write-only']:
                            f.write(" else ")
                        else:
                            f.write("        ")
                        f.write(f"if(hwif_in.{reg_name}.{field_name}.we) begin // HW Write - we\n")
                        f.write(f"            next_c = hwif_in.{reg_name}.{field_name}.next;\n")
                        f.write(f"            load_next_c = '1;\n")
                        f.write("        end\n")
                    elif field_info['access'] in ['read-write', 'write-only']:
                        f.write("\n")
                        
                    f.write(f"        field_combo.{reg_name}.{field_name}.next = next_c;\n")
                    f.write(f"        field_combo.{reg_name}.{field_name}.load_next = load_next_c;\n")
                    f.write("    end\n")
                    
                    # Lógica sequencial
                    f.write("    always_ff @(posedge clk) begin\n")
                    if field_info['access'] != 'write-only':
                        f.write("        if(rst) begin\n")
                        f.write(f"            field_storage.{reg_name}.{field_name}.value <= {format_reset_value(field_info['reset_value'], field_info['bit_width'])};\n")
                        f.write("        end else begin\n")
                        f.write(f"            if(field_combo.{reg_name}.{field_name}.load_next) begin\n")
                        f.write(f"                field_storage.{reg_name}.{field_name}.value <= field_combo.{reg_name}.{field_name}.next;\n")
                        f.write("            end\n")
                        f.write("        end\n")
                    else:
                        f.write(f"        if(field_combo.{reg_name}.{field_name}.load_next) begin\n")
                        f.write(f"            field_storage.{reg_name}.{field_name}.value <= field_combo.{reg_name}.{field_name}.next;\n")
                        f.write("        end\n")
                    f.write("    end\n")
                    
                    # Assignment de saída
                    if field_info['access'] != 'write-only':
                        f.write(f"    assign hwif_out.{reg_name}.{field_name}.value = field_storage.{reg_name}.{field_name}.value;\n")
                    
                    f.write("\n")
        
        print(f"Lógica gerada: {output_file}")
        return True
    
    except Exception as e:
        print(f"Falha ao gerar lógica: {str(e)}", file=sys.stderr)
        return False

if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("Uso: python3 ipxact_csr_gen.py <input.xml> <output_dir>")
        sys.exit(1)
        
    INPUT_XML = sys.argv[1]
    OUTPUT_DIR = sys.argv[2]
    
    print(f"⚡ Convertendo: {INPUT_XML}")
    ip_data = parse_ipxact(INPUT_XML)
    
    if ip_data:
        pkg_success = generate_package(ip_data, OUTPUT_DIR)
        logic_success = generate_logic(ip_data, OUTPUT_DIR)
        
        if pkg_success and logic_success:
            print(f"Conversão concluída! Verifique {OUTPUT_DIR}")
            sys.exit(0)
    
    print("Falha na conversão")
    sys.exit(1)