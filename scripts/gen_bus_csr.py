#!/usr/bin/env python3
"""
Script para gerar módulo APB4 a partir do template e lógica CSR gerada.
Lê CSR_IP_Map_logic.sv e apb4_template.sv para gerar apb4_csr.sv
"""

import re
import os
import math
from pathlib import Path

def extract_register_decode_struct(logic_content):
    """Extrai a estrutura de decodificação de registradores"""
    pattern = r'typedef struct\s*\{(.*?)\}\s*decoded_reg_strb_t;'
    match = re.search(pattern, logic_content, re.DOTALL)
    if match:
        # Limpa e formata o conteúdo
        struct_content = match.group(1).strip()
        # Remove comentários e espaços extras
        lines = [line.strip() for line in struct_content.split('\n') if line.strip()]
        return '\n        '.join(lines)
    return ""

def extract_register_decode_logic(logic_content):
    """Extrai a lógica de decodificação de registradores"""
    pattern = r'always_comb begin\s*(.*?decoded_reg_strb\..*?)\s*end'
    match = re.search(pattern, logic_content, re.DOTALL)
    if match:
        logic_lines = match.group(1).strip().split('\n')
        # Filtra apenas as linhas de decodificação
        decode_lines = [line.strip() for line in logic_lines 
                       if 'decoded_reg_strb.' in line and line.strip()]
        return '\n        '.join(decode_lines)
    return ""

def extract_field_storage_declaration(logic_content):
    """Extrai as declarações de armazenamento de campos"""
    # Procura pelas estruturas field_combo_t e field_storage_t
    pattern1 = r'typedef struct\s*\{(.*?)\}\s*field_combo_t;'
    pattern2 = r'typedef struct\s*\{(.*?)\}\s*field_storage_t;'
    
    combo_match = re.search(pattern1, logic_content, re.DOTALL)
    storage_match = re.search(pattern2, logic_content, re.DOTALL)
    
    result = ""
    if combo_match:
        result += f"typedef struct {{\n{combo_match.group(1).strip()}\n}} field_combo_t;\n"
        result += "field_combo_t field_combo;\n\n"
    
    if storage_match:
        result += f"typedef struct {{\n{storage_match.group(1).strip()}\n}} field_storage_t;\n"
        result += "field_storage_t field_storage;"
    
    return result

def extract_register_logic(logic_content):
    """Extrai toda a lógica dos registradores (Field logic)"""
    # Procura desde "// Field:" até antes de "READBACK_ASSIGNMENTS"
    pattern = r'// Field:.*?(?=//\s*-+\s*READBACK_ASSIGNMENTS|$)'
    match = re.search(pattern, logic_content, re.DOTALL)
    if match:
        return match.group(0).strip()
    return ""

def extract_readback_assignments(logic_content):
    """Extrai as atribuições de readback"""
    pattern = r'//\s*-+\s*READBACK_ASSIGNMENTS\s*//\s*-+(.*?)(?=//|$)'
    match = re.search(pattern, logic_content, re.DOTALL)
    if match:
        assignments = match.group(1).strip()
        # Remove linhas vazias e formata
        lines = [line.strip() for line in assignments.split('\n') 
                if line.strip() and 'assign readback_array' in line]
        return '\n    '.join(lines)
    return ""

def count_registers(logic_content):
    """Conta o número de registradores baseado nas atribuições de readback"""
    assignments = extract_readback_assignments(logic_content)
    if not assignments:
        return 4  # valor padrão
    
    # Encontra o maior índice usado em readback_array
    pattern = r'readback_array\[(\d+)\]'
    indices = [int(match.group(1)) for match in re.finditer(pattern, assignments)]
    return max(indices) + 1 if indices else 4

def determine_addr_width(logic_content):
    """Determina a largura do endereço baseado na decodificação"""
    decode_logic = extract_register_decode_logic(logic_content)
    # Procura por padrões como cpuif_addr == 2'h3
    pattern = r"cpuif_addr\s*==\s*(\d+)'h([0-9a-fA-F]+)"
    matches = re.findall(pattern, decode_logic)
    
    if matches:
        # Pega a largura declarada e o maior valor
        width = int(matches[0][0])  # largura declarada (ex: 2 de 2'h3)
        max_val = max(int(match[1], 16) for _, match in matches)
        # Verifica se a largura é suficiente
        required_width = max_val.bit_length()
        return max(width, required_width)
    return 2  # valor padrão

def generate_hwif_assignments(logic_content):
    """Gera as atribuições da interface de hardware baseado na lógica"""
    # Procura por todas as atribuições hwif_out
    pattern = r'assign\s+hwif_out\..*?;'
    matches = re.findall(pattern, logic_content, re.MULTILINE)
    return '\n    '.join(matches) if matches else ""

def generate_apb4_csr(logic_file_path, template_file_path, output_file_path):
    """Função principal para gerar o arquivo APB4 CSR"""
    
    # Lê os arquivos
    try:
        with open(logic_file_path, 'r', encoding='utf-8') as f:
            logic_content = f.read()
    except FileNotFoundError:
        print(f"Erro: Arquivo {logic_file_path} não encontrado!")
        return False
    
    try:
        with open(template_file_path, 'r', encoding='utf-8') as f:
            template_content = f.read()
    except FileNotFoundError:
        print(f"Erro: Arquivo {template_file_path} não encontrado!")
        return False
    
    # Extrai informações da lógica
    register_decode_struct = extract_register_decode_struct(logic_content)
    register_decode_logic = extract_register_decode_logic(logic_content)
    field_storage_declaration = extract_field_storage_declaration(logic_content)
    register_logic = extract_register_logic(logic_content)
    readback_assignments = extract_readback_assignments(logic_content)
    hwif_assignments = generate_hwif_assignments(logic_content)
    
    # Determina parâmetros
    num_registers = count_registers(logic_content)
    addr_width = max(1, (num_registers - 1).bit_length()) if num_registers > 0 else 0
    
    # Define os placeholders
    placeholders = {
        '{{MODULE_NAME}}': 'CSR_IP_Map',
        '{{PACKAGE_NAME}}': 'CSR_IP_Map_pkg',
        '{{ADDR_WIDTH}}': str(addr_width),
        '{{DATA_WIDTH}}': '32',  # Assumindo 32 bits baseado na lógica
        '{{NUM_REGISTERS}}': str(num_registers),
        '{{MIN_ADDR_WIDTH_PARAM}}': 'CSR_IP_MAP_MIN_ADDR_WIDTH',
        '{{DATA_WIDTH_PARAM}}': 'CSR_IP_MAP_DATA_WIDTH',
        '{{REGISTER_DECODE_STRUCT}}': register_decode_struct,
        '{{REGISTER_DECODE_LOGIC}}': register_decode_logic,
        '{{FIELD_STORAGE_DECLARATION}}': field_storage_declaration,
        '{{REGISTER_LOGIC}}': register_logic,
        '{{HWIF_ASSIGNMENTS}}': hwif_assignments,
        '{{READBACK_ASSIGNMENTS}}': readback_assignments
    }
    
    # Substitui os placeholders no template
    generated_content = template_content
    for placeholder, value in placeholders.items():
        generated_content = generated_content.replace(placeholder, value)
    
    # Cria o diretório de saída se não existir
    output_path = Path(output_file_path)
    output_path.parent.mkdir(parents=True, exist_ok=True)
    
    # Escreve o arquivo gerado
    try:
        with open(output_file_path, 'w', encoding='utf-8') as f:
            f.write(generated_content)
        print(f"Arquivo APB4 CSR gerado com sucesso: {output_file_path}")
        return True
    except Exception as e:
        print(f"Erro ao escrever arquivo {output_file_path}: {e}")
        return False

def main():
    """Função principal"""
    # Define os caminhos dos arquivos
    logic_file = "build/rtl/CSR_IP_Map_logic.sv"
    template_file = "src/apb4_template.sv"
    output_file = "build/rtl/apb4_csr.sv"
    
    # Verifica se os arquivos existem
    if not os.path.exists(logic_file):
        print(f"Erro: Arquivo de lógica não encontrado: {logic_file}")
        return False
    
    if not os.path.exists(template_file):
        print(f"Erro: Arquivo de template não encontrado: {template_file}")
        return False
    
    # Gera o arquivo APB4 CSR
    success = generate_apb4_csr(logic_file, template_file, output_file)
    
    if success:
        print("Geração concluída com sucesso!")
        print(f"Verifique o arquivo gerado em: {output_file}")
    else:
        print("Falha na geração do arquivo.")
    
    return success

if __name__ == "__main__":
    main()