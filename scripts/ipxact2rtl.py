#!/usr/bin/env python3
# -*- coding: utf-8 -*-
import xml.etree.ElementTree as ET
import os
import sys
from pathlib import Path


# Adiciona a raiz do projeto ao sys.path
sys.path.append(str(Path(__file__).resolve().parent.parent))

from tools import ipxact2rtl

# Namespace IP-XACT
NS = {'ipxact': 'http://www.accellera.org/XMLSchema/IPXACT/1685-2022'}

def parse_ipxact(input_xml):
    """Extrai dados do IP-XACT para geração de CSR."""
    try:
        input_path = ipxact2rtl.get_absolute_path(input_xml)
        tree = ET.parse(input_path)
        root = tree.getroot()
        
        component = root
        name = component.find('ipxact:name', NS).text
        
        registers = {}
        enum_definitions = {}  # Nome do enum -> valores
        enum_cache = {}        # Assinatura -> enum_name
        address_info = {}      # Informações de endereçamento

        for addr_block in component.findall('.//ipxact:addressBlock', NS):
            base_address = addr_block.find('ipxact:baseAddress', NS)
            base_addr = int(base_address.text, 0) if base_address is not None else 0
            
            for reg in addr_block.findall('ipxact:register', NS):
                reg_info = ipxact2rtl.parse_register_ipxact(reg, NS, enum_cache, enum_definitions)
                registers[reg_info['reg_name']] =  {
                    'offset': reg_info['offset'],
                    'size': reg_info['size'],
                    'fields': reg_info['fields']
                }
                
                
                address_info[reg_info['reg_name']] = {
                    'offset': reg_info['offset'],
                    'abs_offset': reg_info['abs_offset'],
                    'index': reg_info['index'],
                    'size': reg_info['size']
                }
        
        return {
            'name': name,
            'registers': registers,
            'enums': enum_definitions,
            'address_info': address_info
        }
    
    except Exception as e:
        print(f"Erro inesperado: {type(e).__name__}: {str(e)}", file=sys.stderr)
        return None

def generate_package(ipxact_data, output_dir):
    """Gera o arquivo package SystemVerilog."""
    try:
        output_file = ipxact2rtl._setup_package_output_file(ipxact_data, output_dir)
        component_data = ipxact2rtl._extract_package_data(ipxact_data)
        
        with open(output_file, 'w', encoding='utf-8') as f:
            ipxact2rtl._write_package_header(f, component_data)
            # Gera definições de enum primeiro
            if component_data['enums']:
                f.write("    // Enum definitions\n")
                for enum_name, enum_values in component_data['enums'].items():
                    ipxact2rtl._write_single_enum(f, enum_name, enum_values)

            # Gera typedef structs para entrada (hardware -> registrador)
            f.write("    // Input structures (Hardware -> Register)\n")
            
            # Structs para campos individuais que precisam de entrada HW
            for reg_name, reg_info in component_data['registers'].items():
                for field_name, field_info in reg_info['fields'].items():
                    if ipxact2rtl.needs_hw_input(field_info):
                        f.write(f"    typedef struct {{\n")
                        
                        if field_info['enum']:
                            f.write(f"        {field_info['enum']} next;\n")
                        elif field_info['bit_width'] > 1:
                            f.write(f"        logic [{field_info['bit_width']-1}:0] next;\n")
                        else:
                            f.write(f"        logic next;\n")
                            
                        f.write(f"        logic we;\n")
                        f.write(f"    }} {component_data['name']}__{reg_name}__{field_name}__in_t;\n\n")
            
            # Structs para registradores com entrada HW
            for reg_name, reg_info in component_data['registers'].items():
                hw_input_fields = [f for f, info in reg_info['fields'].items() if ipxact2rtl.needs_hw_input(info)]
                if hw_input_fields:
                    f.write(f"    typedef struct {{\n")
                    for field_name in hw_input_fields:
                        f.write(f"        {component_data['name']}__{reg_name}__{field_name}__in_t {field_name};\n")
                    f.write(f"    }} {component_data['name']}__{reg_name}__in_t;\n\n")
            
            # Struct principal de entrada
            hw_input_regs = [r for r, info in component_data['registers'].items() 
                            if any(ipxact2rtl.needs_hw_input(f_info) for f_info in info['fields'].values())]
            if hw_input_regs:
                f.write(f"    typedef struct {{\n")
                for reg_name in hw_input_regs:
                    f.write(f"        {component_data['name']}__{reg_name}__in_t {reg_name};\n")
                f.write(f"    }} {component_data['name']}__in_t;\n\n")
            
            # Gera typedef structs para saída (registrador -> hardware)
            f.write("    // Output structures (Register -> Hardware)\n")
            
            # Structs para campos individuais
            for reg_name, reg_info in component_data['registers'].items():
                for field_name, field_info in reg_info['fields'].items():
                    if field_info['access'] != 'write-only':
                        f.write(f"    typedef struct {{\n")
                        if field_info['enum']:
                            f.write(f"        {field_info['enum']} value;\n")
                        elif field_info['bit_width'] > 1:
                            f.write(f"        logic [{field_info['bit_width']-1}:0] value;\n")
                        else:
                            f.write(f"        logic value;\n")
                        f.write(f"    }} {component_data['name']}__{reg_name}__{field_name}__out_t;\n\n")
            
            # Structs para registradores
            for reg_name, reg_info in component_data['registers'].items():
                output_fields = [f for f, info in reg_info['fields'].items() if info['access'] != 'write-only']
                if output_fields:
                    f.write(f"    typedef struct {{\n")
                    for field_name in output_fields:
                        f.write(f"        {component_data['name']}__{reg_name}__{field_name}__out_t {field_name};\n")
                    f.write(f"    }} {component_data['name']}__{reg_name}__out_t;\n\n")
            
            # Struct principal de saída
            f.write(f"    typedef struct {{\n")
            for reg_name in component_data['registers'].keys():
                f.write(f"        {component_data['name']}__{reg_name}__out_t {reg_name};\n")
            f.write(f"    }} {component_data['name']}__out_t;\n\n")
            f.write("endpackage\n")
        
        print(f"Package gerado: {output_file}")
        return True
    
    except Exception as e:
        print(f"Falha ao gerar package: {str(e)}", file=sys.stderr)
        return False

def generate_module(ipxact_data, output_dir):
    """Gera o módulo SystemVerilog completo."""
    try:
        output_file = ipxact2rtl._setup_output_file(ipxact_data, output_dir)
        component_data = ipxact2rtl._extract_component_data(ipxact_data)
        
        with open(output_file, 'w', encoding='utf-8') as f:
            ipxact2rtl._write_module_header(f, component_data)
            ipxact2rtl._write_module_interface(f, component_data)
            ipxact2rtl._write_internal_signals(f, component_data)
            ipxact2rtl._write_address_decoding(f, component_data)
            
            # Estruturas de combinacional e storage
            f.write("    //--------------------------------------------------------------------------\n")
            f.write("    // Field logic\n")
            f.write("    //--------------------------------------------------------------------------\n")
            
            ipxact2rtl._write_field_structures(f, component_data)
            
            # Lógica para cada campo
            for reg_name, reg_info in component_data['registers'].items():
                for field_name, field_info in reg_info['fields'].items():
                    if field_info['access'] == 'read-only' and not field_info['volatile']:
                        continue

                    ipxact2rtl._write_single_field_logic(f, component_data['name'], reg_name, field_info)
            
            ipxact2rtl._write_write_response(f)
            ipxact2rtl._write_readback_logic(f, component_data)

            f.write("endmodule\n")

            print(f"Lógica gerada: {output_file}")
        return True
    
    except Exception as e:
        print(f"Falha ao gerar modulo: {str(e)}", file=sys.stderr)
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
        logic_success = generate_module(ip_data, OUTPUT_DIR)
        
        if pkg_success and logic_success:
            print(f"✅ Conversão concluída! Verifique {OUTPUT_DIR}")
            sys.exit(0)
    
    print("❌ Falha na conversão")
    sys.exit(1)