#!/usr/bin/env python3
"""
CSV to IP-XACT 2022 Converter
Converts CSR register tables from CSV format to IP-XACT 2022 XML format
"""
import sys
import csv
import xml.etree.ElementTree as ET
from xml.dom import minidom
import re
import argparse
from pathlib import Path

sys.path.append(str(Path(__file__).resolve().parent.parent))
from tools.utils import IPXACT2022Generator


def read_csv_data(csv_file):
    """Read CSV data, validate structure and return structured data"""
    registers_data = {}

    # Definição das colunas obrigatórias (esperadas no CSV)
    expected_columns = {
        "register",
        "offset",
        "field",
        "bits",
        "access policy",
        "volatile",
        "reset",
        "description",
        "enum values"
    }

    # Valores permitidos para o campo access_policy (padrão IP-XACT)
    valid_access_policies = {"RW", "RO", "WO", "W1C", "W0C", "RC"}

    with open(csv_file, 'r', encoding='utf-8') as f:
        reader = csv.DictReader(f)

        if not reader.fieldnames:
            raise ValueError(f"Arquivo CSV {csv_file} não contém cabeçalho.")

        # Normaliza nomes de colunas para minúsculo
        fieldnames = {name.lower().strip() for name in reader.fieldnames}

        # Valida colunas
        missing = expected_columns - fieldnames
        extra = fieldnames - expected_columns
        if missing:
            raise ValueError(f"CSV {csv_file} está faltando colunas obrigatórias: {missing}")
        if extra:
            raise ValueError(f"CSV {csv_file} contém colunas inesperadas: {extra}")

        for row in reader:
            row_data = {k.lower().strip(): v.strip() for k, v in row.items()}

            register = row_data.get('register', '').strip().lower()
            if not register:
                continue

            if register not in registers_data:
                registers_data[register] = {
                    'offset': row_data.get('offset', '0x0000'),
                    'fields': []
                }

            # Validação do access_policy
            access_policy = row_data.get('Access_Policy', row_data.get('Access Policy', 'RW')).upper()
            if access_policy not in valid_access_policies:
                raise ValueError(
                    f"CSV {csv_file}: AccessPolicy inválido '{access_policy}' "
                    f"para register '{register}', esperado um de {valid_access_policies}"
                )

            # Monta campo
            field_data = {
                'field': row_data.get('field', '').lower(),
                'bits': row_data.get('bits', ''),
                'access_policy': access_policy,
                'volatile': row_data.get('volatile', 'false').lower(),
                'reset': row_data.get('reset', '0'),
                'description': row_data.get('description', ''),
                'enum_values': row_data.get('enum_values', row_data.get('enum values', ''))
            }

            registers_data[register]['fields'].append(field_data)

    return registers_data


def convert_all_csv_to_ipxact(bus_size="32"):
    """Convert all CSV files to a single IP-XACT XML file"""
    
    build_path_csv    = Path("build/csv")
    build_path_ipxact = Path("build/ipxact")
    csv_files = list(build_path_csv.glob('RegisterMap_*.csv'))

    base_addresses = {}
    with open ("build/csv/table_main.csv", mode="r", newline="", encoding="utf-8") as f:
        reader = csv.DictReader(f)
        for row in reader:
            print(f"{row}")
            row["IP"] = re.sub("IP ", "IP-", row["IP"])
            row["Base Address"] = re.sub(" ", "", row["Base Address"])
            base_addresses[row["IP"]] = row["Base Address"]
            
    print(f" CSV: {csv_files} \n")

    if not csv_files:
        print(f"No IPs specific CSV files found in directory: {build_path_csv}")
        return False
    
    print(f"Found {len(csv_files)} CSV files")
    
    # Create IP-XACT generator
    generator = IPXACT2022Generator()
    
    # Create root element
    root = generator.create_root_element()
    
    # Create memory maps container
    memory_maps = ET.SubElement(root, 'ipxact:memoryMaps')
    memory_map = ET.SubElement(memory_maps, 'ipxact:memoryMap')
    
    # Memory map name
    map_name = ET.SubElement(memory_map, 'ipxact:name')
    map_name.text = "CSR_MemoryMap"
    
    # Process each CSV file
    for csv_file in csv_files:
        print(f"Processing {csv_file.name}...")
        
        try:
            # Read CSV data (com validações)
            registers_data = read_csv_data(csv_file)
            print(f"  Found {len(registers_data)} registers")
            
            if not registers_data:
                print(f"  No register data found in {csv_file.name}")
                continue
            
            # Create registers for this CSV
            registers = []
            for reg_name, reg_data in registers_data.items():
                register = generator.create_register_element(
                    reg_name, 
                    reg_data['offset'], 
                    reg_data['fields'],
                    bus_size
                )
                registers.append(register)
                print(f"    Created register: {reg_name} at {reg_data['offset']}")
            
            # Creation of address block
            csv_name = csv_file.stem  # remove extension
            ip_name = re.sub(r'RegisterMap_', '', csv_name)
            address_block = generator.create_address_block(csv_name, registers, base_addresses.get(ip_name), bus_size)
            memory_map.append(address_block)
            
            print(f"  Created address block: {csv_name}")
            
        except ValueError as e:
            print(f"Error processing {csv_file.name}: {e}")
            raise  # <-- interrupção imediata se CSV inválido
    
    # Write the combined XML file
    output_file = build_path_ipxact / "ipMap.xml"

    try:
        # Pretty print the XML
        xml_str = ET.tostring(root, encoding='unicode')
        parsed = minidom.parseString(xml_str)
        pretty_xml = parsed.toprettyxml(indent="  ")
        
        # Remove extra empty lines
        lines = [line for line in pretty_xml.split('\n') if line.strip()]
        pretty_xml = '\n'.join(lines)
        
        with open(output_file, 'w', encoding='utf-8') as f:
            f.write(pretty_xml)
        
        print(f"\nSuccessfully created combined IP-XACT file: {output_file}")
        return True
        
    except Exception as e:
        print(f"Error writing XML file: {e}")
        return False


def main():
    parser = argparse.ArgumentParser(description='Convert CSV register tables to IP-XACT 2022 XML format')
    parser.add_argument('-s', '--bus-size', default='32', help='size of bus (default: 32)')

    args = parser.parse_args()

    try:
        convert_all_csv_to_ipxact(args.bus_size)
    except ValueError as e:
        print("\n❌ Conversão nao finalizada: erro na geração do CSV.")
        print(e)


if __name__ == "__main__":
    main()
