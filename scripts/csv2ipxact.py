#!/usr/bin/env python3
"""
CSV to IP-XACT 2022 Converter
Converts CSR register tables from CSV format to IP-XACT 2022 XML format
With validation and error handling for format compliance
"""

import csv
import os
import xml.etree.ElementTree as ET
from xml.dom import minidom
import re
import argparse
from pathlib import Path
from typing import Dict, List, Set, Optional, Any

class CSVFormatError(Exception):
    """Exception raised for CSV format validation errors"""
    pass

class IPXACTConversionError(Exception):
    """Exception raised for IP-XACT conversion errors"""
    pass

class CSVValidator:
    """Validates CSV format and content against expected standards"""
    
    # Expected column names (case-insensitive)
    REQUIRED_COLUMNS = {
        'register', 'field', 'offset', 'bits'
    }
    
    OPTIONAL_COLUMNS = {
        'access_policy', 'access policy', 'volatile', 'reset', 
        'description', 'enum_values', 'enum values'
    }
    
    # Valid access policies
    VALID_ACCESS_POLICIES = {
        'RW', 'RO', 'WO', 'R', 'W', 'RW1C', 'RW1S', 
        'read-write', 'read-only', 'write-only'
    }
    
    # Valid volatile values
    VALID_VOLATILE_VALUES = {
        'true', 'false', '1', '0', 'yes', 'no', ''
    }
    
    def __init__(self, csv_file: Path):
        self.csv_file = csv_file
        self.headers: Set[str] = set()
        self.row_count = 0
        
    def validate_headers(self, fieldnames: List[str]) -> None:
        """Validate CSV headers against expected format"""
        if not fieldnames:
            raise CSVFormatError(f"CSV file {self.csv_file.name} has no headers")
        
        # Normalize headers (lowercase and strip)
        normalized_headers = {name.lower().strip() for name in fieldnames}
        self.headers = normalized_headers
        
        # Check for required columns
        missing_required = self.REQUIRED_COLUMNS - normalized_headers
        if missing_required:
            raise CSVFormatError(
                f"CSV file {self.csv_file.name} is missing required columns: {missing_required}. "
                f"Found columns: {normalized_headers}"
            )
        
        # Check for unknown columns
        all_valid_columns = self.REQUIRED_COLUMNS | self.OPTIONAL_COLUMNS
        unknown_columns = normalized_headers - all_valid_columns
        if unknown_columns:
            print(f"Warning: CSV file {self.csv_file.name} contains unknown columns: {unknown_columns}")
    
    def validate_bit_range(self, bit_str: str, field_name: str, register_name: str, row_num: int) -> None:
        """Validate bit range format"""
        if not bit_str or bit_str.strip() == '':
            raise CSVFormatError(
                f"Row {row_num} in {self.csv_file.name}: Empty bit range for field '{field_name}' "
                f"in register '{register_name}'"
            )
        
        bit_str = bit_str.strip('[]').strip()
        
        if ':' in bit_str:
            # Range format like "7:0"
            parts = bit_str.split(':')
            if len(parts) != 2:
                raise CSVFormatError(
                    f"Row {row_num} in {self.csv_file.name}: Invalid bit range format '{bit_str}' "
                    f"for field '{field_name}'. Expected format: '[msb:lsb]' or '[bit]'"
                )
            
            try:
                msb = int(parts[0].strip())
                lsb = int(parts[1].strip())
                if msb < 0 or lsb < 0:
                    raise ValueError("Negative bit numbers")
                if msb < lsb:
                    print(f"Warning: Row {row_num} in {self.csv_file.name}: MSB < LSB in bit range '{bit_str}' "
                          f"for field '{field_name}'. This might be intentional.")
            except ValueError as e:
                raise CSVFormatError(
                    f"Row {row_num} in {self.csv_file.name}: Invalid bit numbers in range '{bit_str}' "
                    f"for field '{field_name}': {e}"
                )
        else:
            # Single bit format like "4"
            try:
                bit = int(bit_str.strip())
                if bit < 0:
                    raise ValueError("Negative bit number")
            except ValueError as e:
                raise CSVFormatError(
                    f"Row {row_num} in {self.csv_file.name}: Invalid bit number '{bit_str}' "
                    f"for field '{field_name}': {e}"
                )
    
    def validate_access_policy(self, access_str: str, field_name: str, register_name: str, row_num: int) -> None:
        """Validate access policy format"""
        if access_str and access_str.upper() not in self.VALID_ACCESS_POLICIES:
            raise CSVFormatError(
                f"Row {row_num} in {self.csv_file.name}: Invalid access policy '{access_str}' "
                f"for field '{field_name}' in register '{register_name}'. "
                f"Valid values: {self.VALID_ACCESS_POLICIES}"
            )
    
    def validate_volatile(self, volatile_str: str, field_name: str, register_name: str, row_num: int) -> None:
        """Validate volatile field format"""
        if volatile_str.lower() not in self.VALID_VOLATILE_VALUES:
            raise CSVFormatError(
                f"Row {row_num} in {self.csv_file.name}: Invalid volatile value '{volatile_str}' "
                f"for field '{field_name}' in register '{register_name}'. "
                f"Valid values: {self.VALID_VOLATILE_VALUES}"
            )
    
    def validate_offset(self, offset_str: str, register_name: str, row_num: int) -> None:
        """Validate register offset format"""
        if not offset_str or offset_str.strip() == '':
            raise CSVFormatError(
                f"Row {row_num} in {self.csv_file.name}: Empty offset for register '{register_name}'"
            )
        
        offset_str = offset_str.strip()
        
        # Try to parse the offset
        try:
            if offset_str.startswith('0x') or offset_str.startswith('0X'):
                int(offset_str, 16)
            elif offset_str.startswith('0b') or offset_str.startswith('0B'):
                int(offset_str, 2)
            else:
                int(offset_str, 0)  # Auto-detect base
        except ValueError:
            raise CSVFormatError(
                f"Row {row_num} in {self.csv_file.name}: Invalid offset format '{offset_str}' "
                f"for register '{register_name}'. Expected hex (0x1234), binary (0b1010), or decimal format"
            )
    
    def validate_reset_value(self, reset_str: str, field_name: str, register_name: str, row_num: int) -> None:
        """Validate reset value format"""
        if not reset_str or reset_str.strip() == '':
            return  # Empty reset values are allowed (defaults to 0)
        
        reset_str = reset_str.strip()
        
        try:
            if reset_str.startswith("'h"):
                int(reset_str[2:], 16)
            elif reset_str.startswith("0x"):
                int(reset_str, 16)
            elif reset_str.startswith("'b"):
                int(reset_str[2:], 2)
            else:
                int(reset_str, 0)  # Auto-detect base
        except ValueError:
            raise CSVFormatError(
                f"Row {row_num} in {self.csv_file.name}: Invalid reset value '{reset_str}' "
                f"for field '{field_name}' in register '{register_name}'. "
                f"Expected formats: 'h1A, 0xFF, 'b1010, or decimal"
            )
    
    def validate_enum_values(self, enum_str: str, field_name: str, register_name: str, row_num: int) -> None:
        """Validate enumerated values format"""
        if not enum_str or enum_str.strip() == '':
            return  # Empty enum values are allowed
        
        # Split by semicolon or comma
        parts = re.split(r'[;,]', enum_str)
        
        for i, part in enumerate(parts):
            part = part.strip()
            if not part:
                continue
                
            if ':' not in part:
                raise CSVFormatError(
                    f"Row {row_num} in {self.csv_file.name}: Invalid enum format in part {i+1} '{part}' "
                    f"for field '{field_name}' in register '{register_name}'. "
                    f"Expected format: 'value:name' (e.g., '0:Disabled; 1:Enabled')"
                )
            
            value, name = part.split(':', 1)
            value = value.strip()
            name = name.strip()
            
            if not value or not name:
                raise CSVFormatError(
                    f"Row {row_num} in {self.csv_file.name}: Empty value or name in enum '{part}' "
                    f"for field '{field_name}' in register '{register_name}'"
                )
            
            # Validate that value is a valid number
            try:
                int(value, 0)  # Auto-detect base
            except ValueError:
                raise CSVFormatError(
                    f"Row {row_num} in {self.csv_file.name}: Invalid enum value '{value}' in '{part}' "
                    f"for field '{field_name}' in register '{register_name}'. Must be a valid number"
                )
    
    def validate_row(self, row_data: Dict[str, str], row_num: int) -> None:
        """Validate a single CSV row"""
        register = row_data.get('register', '').strip()
        field = row_data.get('field', '').strip()
        
        if not register:
            raise CSVFormatError(f"Row {row_num} in {self.csv_file.name}: Empty register name")
        
        if not field:
            raise CSVFormatError(f"Row {row_num} in {self.csv_file.name}: Empty field name for register '{register}'")
        
        # Validate each field
        self.validate_offset(row_data.get('offset', ''), register, row_num)
        self.validate_bit_range(row_data.get('bits', ''), field, register, row_num)
        
        access_policy = row_data.get('access_policy', row_data.get('access policy', ''))
        if access_policy:
            self.validate_access_policy(access_policy, field, register, row_num)
        
        volatile = row_data.get('volatile', '').lower()
        if volatile:
            self.validate_volatile(volatile, field, register, row_num)
        
        reset = row_data.get('reset', '')
        if reset:
            self.validate_reset_value(reset, field, register, row_num)
        
        enum_values = row_data.get('enum_values', row_data.get('enum values', ''))
        if enum_values:
            self.validate_enum_values(enum_values, field, register, row_num)

class IPXACT2022Generator:
    def __init__(self):
        self.namespaces = {
            'ipxact': 'http://www.accellera.org/XMLSchema/IPXACT/1685-2022',
            'xsi': 'http://www.w3.org/2001/XMLSchema-instance'
        }
        
    def create_root_element(self):
        """Create the root IP-XACT component element"""
        root = ET.Element('ipxact:component')
        root.set('xmlns:ipxact', self.namespaces['ipxact'])
        root.set('xmlns:xsi', self.namespaces['xsi'])
        root.set('xsi:schemaLocation', 
                f"{self.namespaces['ipxact']} "
                "http://www.accellera.org/XMLSchema/IPXACT/1685-2022/index.xsd")
        
        # Add vendor, library, name, version
        vlnv = ET.SubElement(root, 'ipxact:vendor')
        vlnv.text = "vendor.com"
        
        library = ET.SubElement(root, 'ipxact:library')
        library.text = "components"
        
        name = ET.SubElement(root, 'ipxact:name')
        name.text = "CSR_IP_Map"
        
        version = ET.SubElement(root, 'ipxact:version')
        version.text = "1.0"
        
        return root
    
    def parse_bit_range(self, bit_str):
        """Parse bit range string like '[7:0]' or '[4]' and return (msb, lsb)"""
        if not bit_str or bit_str.strip() == '':
            return None, None
            
        # Remove brackets and whitespace
        bit_str = bit_str.strip('[]').strip()
        
        if ':' in bit_str:
            # Range like "7:0"
            parts = bit_str.split(':')
            msb = int(parts[0].strip())
            lsb = int(parts[1].strip())
            return msb, lsb
        else:
            # Single bit like "4"
            bit = int(bit_str.strip())
            return bit, bit
    
    def parse_access_policy(self, access_str):
        """Convert access policy string to IP-XACT 2022 access type"""
        access_map = {
            'RW': 'read-write',
            'RO': 'read-only',
            'WO': 'write-only',
            'R': 'read-only',
            'W': 'write-only',
            'RW1C': 'read-writeOnce',
            'RW1S': 'read-writeOnce'
        }
        return access_map.get(access_str.upper(), 'read-write')
    
    def parse_reset_value(self, reset_str):
        """Parse reset value string and convert to integer"""
        if not reset_str or reset_str.strip() == '':
            return 0
            
        reset_str = reset_str.strip()
        
        # Handle Verilog-style hex values like 'h0, 'hFF
        if reset_str.startswith("'h"):
            return int(reset_str[2:], 16)
        elif reset_str.startswith("0x"):
            return int(reset_str, 16)
        elif reset_str.startswith("'b"):
            return int(reset_str[2:], 2)
        else:
            try:
                return int(reset_str, 0)  # Auto-detect base
            except ValueError:
                return 0
    
    def parse_enum_values(self, enum_str):
        """Parse enumerated values string like '0:100Hz; 1:500Hz'"""
        if not enum_str or enum_str.strip() == '':
            return []
            
        enums = []
        # Split by semicolon or comma
        parts = re.split(r'[;,]', enum_str)
        
        for part in parts:
            part = part.strip()
            if ':' in part:
                value, name = part.split(':', 1)
                enums.append({
                    'value': value.strip(),
                    'name': name.strip()
                })
        
        return enums
    
    def create_register_element(self, reg_name, reg_offset, fields_data, bus_size):
        """Create a register element with its fields"""
        register = ET.Element('ipxact:register')
        
        # Register name
        name = ET.SubElement(register, 'ipxact:name')
        name.text = reg_name
        
        # Register address offset
        address_offset = ET.SubElement(register, 'ipxact:addressOffset')
        address_offset.text = reg_offset
        
        # Register size (calculate from fields or default to 32)
        max_bit = 0
        for field_data in fields_data:
            msb, lsb = self.parse_bit_range(field_data.get('bits', ''))
            if msb is not None:
                max_bit = max(max_bit, msb)
        
        size = ET.SubElement(register, 'ipxact:size')
        size.text = bus_size  # Default to 32-bit minimum
        
        # Add fields
        for field_data in fields_data:
            field_elem = self.create_field_element(field_data)
            if field_elem is not None:
                register.append(field_elem)
        
        return register
    
    def create_field_element(self, field_data):
        """Create a field element from field data using IP-XACT 2022 format"""
        field_name = field_data.get('field', '').strip()
        if not field_name:
            return None
            
        field = ET.Element('ipxact:field')
        
        # Field name
        name = ET.SubElement(field, 'ipxact:name')
        name.text = field_name
        
        # Bit range - using bitOffset and bitWidth for IP-XACT 2022
        msb, lsb = self.parse_bit_range(field_data.get('bits', ''))
        if msb is not None and lsb is not None:
            # Calculate bitOffset (LSB) and bitWidth
            bit_offset = min(msb, lsb)
            bit_width = abs(msb - lsb) + 1
            
            bit_offset_elem = ET.SubElement(field, 'ipxact:bitOffset')
            bit_offset_elem.text = str(bit_offset)
            
            bit_width_elem = ET.SubElement(field, 'ipxact:bitWidth')
            bit_width_elem.text = str(bit_width)
        
        # Access policy
        access_policy = field_data.get('access_policy', 'RW')
        access = ET.SubElement(field, 'ipxact:access')
        access.text = self.parse_access_policy(access_policy)
        
        # Reset value
        reset_value = self.parse_reset_value(field_data.get('reset', '0'))
        if reset_value != 0:
            resets = ET.SubElement(field, 'ipxact:resets')
            reset_elem = ET.SubElement(resets, 'ipxact:reset')
            reset_type = ET.SubElement(reset_elem, 'ipxact:resetTypeRef')
            reset_type.text = "HARD"
            reset_val = ET.SubElement(reset_elem, 'ipxact:value')
            reset_val.text = f"0x{reset_value:X}"
        
        # Description
        description = field_data.get('description', '').strip()
        if description:
            desc = ET.SubElement(field, 'ipxact:description')
            desc.text = description
        
        # Enumerated values
        enum_values = self.parse_enum_values(field_data.get('enum_values', ''))
        if enum_values:
            enums = ET.SubElement(field, 'ipxact:enumeratedValues')
            for enum_data in enum_values:
                enum_val = ET.SubElement(enums, 'ipxact:enumeratedValue')
                enum_name = ET.SubElement(enum_val, 'ipxact:name')
                enum_name.text = enum_data['name']
                enum_value = ET.SubElement(enum_val, 'ipxact:value')
                enum_value.text = enum_data['value']
        
        # Volatile
        volatile = field_data.get('volatile', 'false').lower()
        if volatile in ['true', '1', 'yes']:
            vol = ET.SubElement(field, 'ipxact:volatile')
            vol.text = "true"
        
        return field
    
    def create_address_block(self, csv_name, registers, base_address, bus_size="32"):
        """Create an address block for a specific CSV table"""
        address_block = ET.Element('ipxact:addressBlock')
        
        # Address block name
        block_name = ET.SubElement(address_block, 'ipxact:name')
        block_name.text = csv_name.replace("RegisterMap_", "", 1)
        
        # Base address
        base_addr = ET.SubElement(address_block, 'ipxact:baseAddress')
        base_addr.text = base_address
        
        # Range
        max_offset = 0x1000
        for reg in registers:
            offset_str = reg.find('ipxact:addressOffset').text
            offset = int(offset_str, 0)
            size = int(reg.find('ipxact:size').text)
            max_offset = max(max_offset, offset + (size // 8))
        
        range_elem = ET.SubElement(address_block, 'ipxact:range')
        range_elem.text = f"0x{max_offset:X}"
        
        # Width
        width = ET.SubElement(address_block, 'ipxact:width')
        width.text = bus_size
        
        # Add registers to address block
        for register in registers:
            address_block.append(register)
        
        return address_block

def read_csv_data(csv_file: Path) -> Dict[str, Any]:
    """Read CSV data and return structured data with validation"""
    registers_data = {}
    
    # Create validator
    validator = CSVValidator(csv_file)
    
    try:
        with open(csv_file, 'r', encoding='utf-8') as f:
            reader = csv.DictReader(f)
            
            # Validate headers
            validator.validate_headers(reader.fieldnames)
            
            # Handle case-insensitive headers
            fieldnames = [name.lower().strip() for name in reader.fieldnames]
            
            row_num = 1  # Start from 1 (header is row 0)
            for row in reader:
                row_num += 1
                
                # Convert keys to lowercase for consistency
                row_data = {k.lower().strip(): v.strip() for k, v in row.items()}
                
                # Validate row data
                validator.validate_row(row_data, row_num)
                
                register = row_data.get('register', '').strip().lower()

                if not register:
                    continue
                    
                if register not in registers_data:
                    registers_data[register] = {
                        'offset': row_data.get('offset', '0x0000'),
                        'fields': []
                    }
                
                # Add field data
                field_data = {
                    'field': row_data.get('field', '').lower(),
                    'bits': row_data.get('bits', ''),
                    'access_policy': row_data.get('access_policy', row_data.get('access policy', 'RW')),
                    'volatile': row_data.get('volatile', 'false'),
                    'reset': row_data.get('reset', '0'),
                    'description': row_data.get('description', ''),
                    'enum_values': row_data.get('enum values', row_data.get('enum_values', ''))
                }
                
                registers_data[register]['fields'].append(field_data)
    
    except FileNotFoundError:
        raise CSVFormatError(f"CSV file not found: {csv_file}")
    except PermissionError:
        raise CSVFormatError(f"Permission denied reading CSV file: {csv_file}")
    except UnicodeDecodeError as e:
        raise CSVFormatError(f"Encoding error reading CSV file {csv_file}: {e}")
    except csv.Error as e:
        raise CSVFormatError(f"CSV format error in file {csv_file}: {e}")
    
    return registers_data

def validate_base_addresses_file(base_addresses_file: Path) -> Dict[str, str]:
    """Validate and read base addresses from table_main.csv"""
    if not base_addresses_file.exists():
        raise CSVFormatError(f"Base addresses file not found: {base_addresses_file}")
    
    base_addresses = {}
    try:
        with open(base_addresses_file, mode="r", newline="", encoding="utf-8") as f:
            reader = csv.DictReader(f)
            
            if not reader.fieldnames:
                raise CSVFormatError(f"Base addresses file {base_addresses_file.name} has no headers")
            
            # Check for required columns
            fieldnames = [name.lower().strip() for name in reader.fieldnames]
            if 'ip' not in fieldnames or 'base address' not in fieldnames:
                raise CSVFormatError(
                    f"Base addresses file {base_addresses_file.name} missing required columns. "
                    f"Expected: 'IP', 'Base Address'. Found: {reader.fieldnames}"
                )
            
            for row_num, row in enumerate(reader, start=2):  # Start from 2 (header is row 1)
                ip_name = row.get('IP', '').strip()
                base_addr = row.get('Base Address', '').strip()
                
                if not ip_name:
                    raise CSVFormatError(
                        f"Row {row_num} in {base_addresses_file.name}: Empty IP name"
                    )
                
                if not base_addr:
                    raise CSVFormatError(
                        f"Row {row_num} in {base_addresses_file.name}: Empty base address for IP '{ip_name}'"
                    )
                
                # Normalize IP name
                ip_name = re.sub("IP ", "IP-", ip_name)
                base_addr = re.sub(" ", "", base_addr)
                
                # Validate base address format
                try:
                    int(base_addr, 0)  # Try to parse as number
                except ValueError:
                    raise CSVFormatError(
                        f"Row {row_num} in {base_addresses_file.name}: Invalid base address format '{base_addr}' "
                        f"for IP '{ip_name}'"
                    )
                
                base_addresses[ip_name] = base_addr
                
    except FileNotFoundError:
        raise CSVFormatError(f"Base addresses file not found: {base_addresses_file}")
    except PermissionError:
        raise CSVFormatError(f"Permission denied reading base addresses file: {base_addresses_file}")
    except UnicodeDecodeError as e:
        raise CSVFormatError(f"Encoding error reading base addresses file {base_addresses_file}: {e}")
    except csv.Error as e:
        raise CSVFormatError(f"CSV format error in base addresses file {base_addresses_file}: {e}")
    
    return base_addresses

def convert_all_csv_to_ipxact(bus_size="32"):
    """Convert all CSV files to a single IP-XACT XML file with validation"""
    
    input_path = Path("build/csv")
    output_path = Path("build/ipxact")
    
    # Ensure output directory exists
    output_path.mkdir(parents=True, exist_ok=True)
    
    # Validate and read base addresses
    base_addresses_file = input_path / "table_main.csv"
    try:
        base_addresses = validate_base_addresses_file(base_addresses_file)
        print(f"Successfully loaded base addresses for {len(base_addresses)} IPs")
    except CSVFormatError as e:
        print(f"Error processing base addresses file: {e}")
        return False
    
    # Find CSV files
    csv_files = list(input_path.glob('RegisterMap_*.csv'))
    
    if not csv_files:
        print(f"No IP-specific CSV files found in directory: {input_path}")
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
    processed_files = 0
    for csv_file in csv_files:
        print(f"Processing {csv_file.name}...")
        
        try:
            # Read and validate CSV data
            registers_data = read_csv_data(csv_file)
            print(f"  Successfully validated and loaded {len(registers_data)} registers")
            
            if not registers_data:
                print(f"  No register data found in {csv_file.name}")
                continue
            
            # Create registers for this CSV
            registers = []
            for reg_name, reg_data in registers_data.items():
                try:
                    register = generator.create_register_element(
                        reg_name, 
                        reg_data['offset'], 
                        reg_data['fields'],
                        bus_size
                    )
                    registers.append(register)
                    print(f"    Created register: {reg_name} at {reg_data['offset']}")
                except Exception as e:
                    raise IPXACTConversionError(
                        f"Error creating register '{reg_name}' in {csv_file.name}: {e}"
                    )
            
            # Create address block
            csv_name = csv_file.stem  # remove extension
            ip_name = re.sub(r'RegisterMap_', '', csv_name)
            
            if ip_name not in base_addresses:
                raise CSVFormatError(
                    f"No base address found for IP '{ip_name}' (from file {csv_file.name}) "
                    f"in base addresses file. Available IPs: {list(base_addresses.keys())}"
                )
            
            address_block = generator.create_address_block(
                csv_name, registers, base_addresses[ip_name], bus_size
            )
            memory_map.append(address_block)
            
            print(f"  Created address block: {csv_name} at base address {base_addresses[ip_name]}")
            processed_files += 1
            
        except CSVFormatError as e:
            print(f"CSV validation error in {csv_file.name}: {e}")
            return False
        except IPXACTConversionError as e:
            print(f"IP-XACT conversion error: {e}")
            return False
        except Exception as e:
            print(f"Unexpected error processing {csv_file.name}: {e}")
            return False
    
    if processed_files == 0:
        print("No CSV files were successfully processed")
        return False
    
    # Write the combined XML file
    output_file = output_path / "ipMap.xml"
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
        print(f"Processed {processed_files} CSV files successfully")
        return True
        
    except Exception as e:
        raise IPXACTConversionError(f"Error writing XML file {output_file}: {e}")

def main():
    parser = argparse.ArgumentParser(
        description='Convert CSV register tables to IP-XACT 2022 XML format with validation'
    )
    parser.add_argument(
        '-s', '--bus-size', 
        default='32', 
        help='Size of bus in bits (default: 32)'
    )
    parser.add_argument(
        '-v', '--verbose', 
        action='store_true', 
        help='Enable verbose output'
    )

    args = parser.parse_args()

    try:
        success = convert_all_csv_to_ipxact(args.bus_size)
        if success:
            print("\nConversion completed successfully!")
        else:
            print("\nConversion failed!")
            exit(1)
    except Exception as e:
        print(f"Fatal error: {e}")
        exit(1)

if __name__ == "__main__":
    main()