from datetime import datetime
import math
from pathlib import Path

def get_absolute_path(relative_path):
    """Converte caminhos relativos em absolutos baseado na localização do script."""
    script_dir = Path(__file__).parent
    return (script_dir / relative_path).resolve()

def parse_register_ipxact(reg, NS, enum_cache, enum_definitions):
    """
    Parse a single <ipxact:register> element into a Python dictionary.

    Parameters
    ----------
    reg : xml.etree.ElementTree.Element
        The XML element representing the register.
    NS : dict
        Namespace mapping for IP-XACT tags.
    enum_cache : dict
        Cache to reuse enum signatures across fields.
    enum_definitions : dict
        Dictionary to store unique enum definitions.

    Returns
    -------
    dict
        Parsed register attributes including fields.
    """
    reg_name = reg.find('ipxact:name', NS).text
    offset = reg.find('ipxact:addressOffset', NS).text
    size = int(reg.find('ipxact:size', NS).text) if reg.find('ipxact:size', NS) is not None else 32

    # Calcula endereço absoluto e índice
    abs_offset = int(offset, 0)
    reg_index = abs_offset // (size // 8)  # alinhamento por palavra (bytes)

    # Campos do registrador
    fields = {}
    for field in reg.findall('ipxact:field', NS):
        field_info = parse_field_ipxact(field, NS, reg_name, enum_cache, enum_definitions)
        fields[field_info['field_name']] = field_info

    return {
        'reg_name': reg_name,
        'offset': offset,
        'abs_offset': abs_offset,
        'index': reg_index,
        'size': size,
        'fields': fields
    }

def parse_field_ipxact(field, NS, reg_name, enum_cache, enum_definitions):
    """
    Parse a single <ipxact:field> element into a Python dictionary.

    Parameters
    ----------
    field : xml.etree.ElementTree.Element
        The XML element representing the field.
    NS : dict
        Namespace mapping for IP-XACT tags.
    reg_name : str
        Name of the parent register (used to generate enum names).
    enum_cache : dict
        Cache to reuse enum signatures across fields.
    enum_definitions : dict
        Dictionary to store unique enum definitions.

    Returns
    -------
    dict
        Parsed field attributes.
    """
    field_name = field.find('ipxact:name', NS).text
    bit_offset = int(field.find('ipxact:bitOffset', NS).text)
    bit_width = int(field.find('ipxact:bitWidth', NS).text)

    # Access type (default: read-write)
    access_elem = field.find('ipxact:access', NS)
    access = access_elem.text if access_elem is not None else 'read-write'

    # Volatile (default: False)
    volatile_elem = field.find('ipxact:volatile', NS)
    volatile = volatile_elem is not None and volatile_elem.text.lower() == 'true'

    # Reset value
    reset_value = "'h0"
    resets = field.find('ipxact:resets', NS)
    if resets is not None:
        reset = resets.find('ipxact:reset', NS)
        if reset is not None:
            reset_value_elem = reset.find('ipxact:value', NS)
            if reset_value_elem is not None:
                reset_value = reset_value_elem.text
    else:
        reset_value_elem = field.find('.//ipxact:value', NS)
        if reset_value_elem is not None:
            reset_value = reset_value_elem.text

    # Description
    desc_elem = field.find('ipxact:description', NS)
    description = desc_elem.text if desc_elem is not None else ""

    # Enumerated values
    enum_values = parse_enumerated_values(field, NS)
    enum_name = None
    if enum_values:
        # Unique signature for enum reuse
        signature = tuple(sorted(enum_values.items()))
        if signature in enum_cache:
            enum_name = enum_cache[signature]
        else:
            enum_name = f"{reg_name}_{field_name}_e"
            enum_definitions[enum_name] = enum_values
            enum_cache[signature] = enum_name

    return {
        'field_name': field_name,
        'bit_offset': bit_offset,
        'bit_width': bit_width,
        'access': access,
        'volatile': volatile,
        'reset_value': reset_value,
        'description': description,
        'enum': enum_name
    }

def parse_enumerated_values(field, NS):
    """Extrai valores enumerados de um campo."""
    enum_values = {}
    for enum in field.findall('ipxact:enumeratedValues/ipxact:enumeratedValue', NS):
        name_elem = enum.find('ipxact:name', NS)
        value_elem = enum.find('ipxact:value', NS)
        if name_elem is not None and value_elem is not None:
            enum_values[value_elem.text] = name_elem.text
    return enum_values if enum_values else None

def needs_hw_input(field_info):
    """Verifica se o campo precisa de entrada de hardware"""
    return (field_info['volatile'] or 
            field_info['access'] == 'read-only' or
            'master mode will be cleared' in field_info.get('description', '').lower())

def _setup_output_file(ipxact_data, output_dir):
    """Configura o arquivo de saída."""
    output_path = get_absolute_path(output_dir)
    output_path.mkdir(parents=True, exist_ok=True)
    return output_path / f"{ipxact_data['name']}.sv"

def _extract_component_data(ipxact_data):
    """Extrai e calcula dados do componente."""
    component_name = ipxact_data['name']
    registers = ipxact_data['registers']
    enums = ipxact_data.get('enums', {})
    address_info = ipxact_data.get('address_info', {})
    
    # Calcula larguras
    max_size = max([info['size'] for info in registers.values()]) if registers else 32
    data_width = max_size - 1
    num_regs = len(registers)
    addr_width = 32 #provavelmente tera um addr_width como parametro no futuro
    
    hw_input_regs = [r for r, info in registers.items() 
                    if any(needs_hw_input(f_info) for f_info in info['fields'].values())]
    
    return {
        'name': component_name,
        'registers': registers,
        'enums': enums,
        'address_info': address_info,
        'data_width': data_width,
        'addr_width': addr_width,
        'num_regs': num_regs,
        'hw_input_regs': hw_input_regs
    }

def _write_module_header(f, component_data):
    """Escreve o cabeçalho do módulo."""
    f.write(f"// Módulo {component_data['name']} - Gerado automaticamente em {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n")
    f.write("// Módulo CSR completo\n\n")
    f.write(f"import {component_data['name']}_pkg::*;\n\n")

def _write_module_interface(f, component_data):
    """Escreve a interface do módulo."""
    f.write(f"module {component_data['name']} (\n")
    f.write("     Bus2Reg_intf intf,\n\n")
    
    if component_data['hw_input_regs']:
        f.write(f"    input {component_data['name']}__in_t hwif_in,\n")
    f.write(f"    output {component_data['name']}__out_t hwif_out\n")
    f.write(");\n\n")

def _write_internal_signals(f, component_data):
    """Escreve sinais internos e mapeamentos."""
    f.write("    logic cpuif_rd_ack;\n")
    f.write("    logic cpuif_rd_err;\n")
    f.write("    logic cpuif_wr_ack;\n")
    f.write("    logic cpuif_wr_err;\n")
    f.write(f"    logic [{component_data['data_width']}:0] cpuif_rd_data;\n")
    f.write(f"    logic [{component_data['addr_width']-1}:0] cpuif_addr;\n\n")
    
    f.write("    assign cpuif_addr = intf.bus_addr;\n")
    f.write("    assign intf.bus_ready = cpuif_rd_ack | cpuif_wr_ack;\n")
    f.write("    assign intf.bus_rd_data = cpuif_rd_data;\n")
    f.write("    assign intf.bus_err = cpuif_rd_err | cpuif_wr_err;\n\n")

def get_addr_register(component_data, reg_name):

    base_addr = component_data['registers'][reg_name]['base_address']
    offset    = component_data['registers'][reg_name]['offset']

    base_int = int(base_addr, 16)
    offset_int = int(offset, 16)
    result = base_int + offset_int
    return f"{result:08X}"

def _write_address_decoding(f, component_data):
    """Escreve lógica de decodificação de endereço."""
    f.write("    typedef struct {\n")
    for reg_name in component_data['registers'].keys():
        f.write(f"        logic {reg_name};\n")
    f.write("    } decoded_reg_strb_t;\n\n")
    
    f.write("    decoded_reg_strb_t decoded_reg_strb;\n")
    f.write("    logic decoded_req;\n")
    f.write("    logic decoded_req_is_wr;\n")
    f.write(f"    logic [{component_data['data_width']}:0] decoded_wr_data;\n")
    f.write(f"    logic [{component_data['data_width']}:0] decoded_wr_biten;\n\n")
    
    f.write("    always_comb begin\n")
    reg_list = list(component_data['registers'].keys())
    for i, reg_name in enumerate(reg_list):
        if component_data['addr_width'] > 0:
            f.write(f"        decoded_reg_strb.{reg_name} = (cpuif_addr == 32'h{get_addr_register(component_data, reg_name)});\n")
        else:
            f.write(f"        decoded_reg_strb.{reg_name} = 1'b1;\n")
    f.write("    end\n\n")
    
    f.write("    assign decoded_req = intf.bus_req;\n")
    f.write("    assign decoded_req_is_wr = intf.bus_req_is_wr;\n")
    f.write("    assign decoded_wr_data = intf.bus_wr_data;\n")
    f.write(f"    assign decoded_wr_biten = intf.bus_wr_biten;\n\n")

def _write_field_structures(f, component_data):
    """Escreve estruturas de campo combinacional e storage."""
    f.write("    //--------------------------------------------------------------------------\n")
    f.write("    // Field logic\n")
    f.write("    //--------------------------------------------------------------------------\n")
    
    # field_combo_t
    f.write("    typedef struct {\n")
    for reg_name, reg_info in component_data['registers'].items():
        f.write(f"        struct {{\n")
        for field_name, field_info in reg_info['fields'].items():
            if field_info['access'] != 'read-only' or field_info['volatile']:
                f.write(f"            struct {{\n")
                if field_info['enum']:
                    f.write(f"                {field_info['enum']} next;\n")
                elif field_info['bit_width'] > 1:
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
    for reg_name, reg_info in component_data['registers'].items():
        f.write(f"        struct {{\n")
        for field_name, field_info in reg_info['fields'].items():
            if field_info['access'] != 'read-only' or field_info['volatile']:
                f.write(f"            struct {{\n")
                if field_info['enum']:
                    f.write(f"                {field_info['enum']} value;\n")
                elif field_info['bit_width'] > 1:
                    f.write(f"                logic [{field_info['bit_width']-1}:0] value;\n")
                else:
                    f.write(f"                logic value;\n")
                f.write(f"            }} {field_name};\n")
        f.write(f"        }} {reg_name};\n")
    f.write("    } field_storage_t;\n")
    f.write("    field_storage_t field_storage;\n\n")

def _write_single_field_logic(f, component_name, reg_name, field_info):
    """Escreve lógica para um único campo."""
    f.write(f"    // Field: {component_name}.{reg_name}.{field_info['field_name']}\n")
    
    # Lógica combinacional
    bit_range = f"[{field_info['bit_width']-1}:0]" if field_info['bit_width'] > 1 and not field_info['enum'] else ""
    bit_select = _get_bit_select(field_info)
    
    f.write("    always_comb begin\n")
    if field_info['enum']:
        f.write(f"        {field_info['enum']} next_c;\n")
    else:
        f.write(f"        logic {bit_range} next_c;\n")
    f.write(f"        logic load_next_c;\n")
    f.write(f"        next_c = field_storage.{reg_name}.{field_info['field_name']}.value;\n")
    f.write(f"        load_next_c = '0;\n")
    
    _write_field_write_logic(f, reg_name, field_info, bit_select)
    
    f.write(f"        field_combo.{reg_name}.{field_info['field_name']}.next = next_c;\n")
    f.write(f"        field_combo.{reg_name}.{field_info['field_name']}.load_next = load_next_c;\n")
    f.write("    end\n")
    
    _write_field_sequential_logic(f, reg_name, field_info)
    
    # Assignment de saída
    if field_info['access'] != 'write-only':
        f.write(f"    assign hwif_out.{reg_name}.{field_info['field_name']}.value = field_storage.{reg_name}.{field_info['field_name']}.value;\n")
    
    f.write("\n")

def _write_field_sequential_logic(f, reg_name, field_info):
    """Escreve lógica sequencial para um campo."""
    f.write("    always_ff @(posedge intf.clk or negedge intf.rst) begin\n")
    if field_info['access'] != 'write-only':
        f.write("        if(!intf.rst) begin\n")
        if field_info['enum']:
            f.write(f"            field_storage.{reg_name}.{field_info['field_name']}.value <= {field_info['enum']}'({format_reset_value(field_info['reset_value'], field_info['bit_width'])});\n")
        else:
            f.write(f"            field_storage.{reg_name}.{field_info['field_name']}.value <= {format_reset_value(field_info['reset_value'], field_info['bit_width'])};\n")
        f.write("        end else begin\n")
        f.write(f"            if(field_combo.{reg_name}.{field_info['field_name']}.load_next) begin\n")
        #f.write(f"$display(\"field_storage.{reg_name}.{field_info['field_name']}.value <= %h\",field_combo.{reg_name}.{field_info['field_name']}.next);\n")
        f.write(f"                field_storage.{reg_name}.{field_info['field_name']}.value <= field_combo.{reg_name}.{field_info['field_name']}.next;\n")
        f.write("            end\n")
        f.write("        end\n")
    else:
        f.write(f"        if(field_combo.{reg_name}.{field_info['field_name']}.load_next) begin\n")
        f.write(f"            field_storage.{reg_name}.{field_info['field_name']}.value <= field_combo.{reg_name}.{field_info['field_name']}.next;\n")
        f.write("        end\n")
    f.write("    end\n")

def _write_write_response(f):
    """Escreve lógica de resposta de escrita."""
    f.write("    //--------------------------------------------------------------------------\n")
    f.write("    // Write response\n")
    f.write("    //--------------------------------------------------------------------------\n")
    f.write("    assign cpuif_wr_ack = decoded_req & decoded_req_is_wr;\n")
    f.write("    // Writes are always granted with no error response\n")
    f.write("    assign cpuif_wr_err = '0;\n\n")

def _write_readback_logic(f, component_data):
    """Escreve lógica de readback."""
    f.write("    //--------------------------------------------------------------------------\n")
    f.write("    // Readback\n")
    f.write("    //--------------------------------------------------------------------------\n\n")
    
    f.write("    logic readback_err;\n")
    f.write("    logic readback_done;\n")
    f.write(f"    logic [{component_data['data_width']}:0] readback_data;\n\n")
    
    f.write(f"    // Assign readback values to a flattened array\n")
    f.write(f"    logic [{component_data['data_width']}:0] readback_array[{component_data['num_regs']}];\n")
    
    _write_readback_array(f, component_data)
    
    f.write("\n    // Reduce the array\n")
    f.write("    always_comb begin\n")
    f.write(f"        automatic logic [{component_data['data_width']}:0] readback_data_var;\n")
    f.write("        readback_done = decoded_req & ~decoded_req_is_wr;\n")
    f.write("        readback_err = '0;\n")
    f.write("        readback_data_var = '0;\n")
    f.write(f"        for(int i=0; i<{component_data['num_regs']}; i++) readback_data_var |= readback_array[i];\n")
    f.write("        readback_data = readback_data_var;\n")
    f.write("    end\n\n")
    
    f.write("    assign cpuif_rd_ack = readback_done;\n")
    f.write("    assign cpuif_rd_data = readback_data;\n")
    f.write("    assign cpuif_rd_err = readback_err;\n\n")

def _write_field_write_logic(f, reg_name, field_info, bit_select):
    """Escreve lógica de escrita para um campo."""
    # Software write
    if field_info['access'] in ['read-write', 'write-only']:
        f.write(f"        if(decoded_reg_strb.{reg_name} && decoded_req_is_wr) begin // SW write\n")
        if field_info['enum']:
            f.write(f"            next_c = {field_info['enum']}'(decoded_wr_data{bit_select});\n")
        elif field_info['bit_width'] > 1:
            f.write(f"            next_c = (field_storage.{reg_name}.{field_info['field_name']}.value & ~decoded_wr_biten{bit_select}) | (decoded_wr_data{bit_select} & decoded_wr_biten{bit_select});\n")
        else:
            f.write(f"            next_c = decoded_wr_data{bit_select};\n")
        f.write(f"            load_next_c = '1;\n")
        f.write("        end")
    
    # Hardware write
    if needs_hw_input(field_info):
        if field_info['access'] in ['read-write', 'write-only']:
            f.write(" else ")
        else:
            f.write("        ")
        f.write(f"if(hwif_in.{reg_name}.{field_info['field_name']}.we) begin // HW Write - we\n")
        f.write(f"            next_c = hwif_in.{reg_name}.{field_info['field_name']}.next;\n")
        f.write(f"            load_next_c = '1;\n")
        f.write("        end\n")
    elif field_info['access'] in ['read-write', 'write-only']:
        f.write("\n")

def _write_readback_array(f, component_data):
    """Escreve assignments do array de readback."""
    reg_idx = 0
    for reg_name, reg_info in component_data['registers'].items():
        f.write(f"    assign readback_array[{reg_idx}] = '0;\n")
        
        for field_name, field_info in reg_info['fields'].items():
            if field_info['access'] != 'write-only':
                bit_select = _get_bit_select(field_info)
                
                if needs_hw_input(field_info) and field_info['access'] == 'read-only':
                    f.write(f"    assign readback_array[{reg_idx}]{bit_select} = (decoded_reg_strb.{reg_name} && !decoded_req_is_wr) ? hwif_in.{reg_name}.{field_name}.next : '0;\n")
                else:
                    f.write(f"    assign readback_array[{reg_idx}]{bit_select} = (decoded_reg_strb.{reg_name} && !decoded_req_is_wr) ? field_storage.{reg_name}.{field_name}.value : '0;\n")
        
        reg_idx += 1

def format_reset_value(reset_value, bit_width):
    """Formata o valor de reset com a largura correta"""
    if reset_value.startswith("'h"):
        return f"{bit_width}'h{reset_value[2:]}"
    elif reset_value.startswith("0x"):
        return f"{bit_width}'h{reset_value[2:]}"
    elif reset_value.startswith("'b"):
        return f"{bit_width}'b{reset_value[2:]}"
    elif reset_value.startswith("'d"):
        return f"{bit_width}'d{reset_value[2:]}"
    return f"{bit_width}'h0"

def _get_bit_select(field_info):
    """Retorna a string de seleção de bits apropriada."""
    if field_info['bit_width'] > 1:
        return f"[{field_info['bit_offset']+field_info['bit_width']-1}:{field_info['bit_offset']}]"
    else:
        return f"[{field_info['bit_offset']}]"
    
def _setup_package_output_file(ipxact_data, output_dir):
    """Configura o arquivo de saída do package."""
    output_path = get_absolute_path(output_dir)
    output_path.mkdir(parents=True, exist_ok=True)
    return output_path / f"{ipxact_data['name']}_pkg.sv"


def _extract_package_data(ipxact_data):
    """Extrai dados necessários para gerar o package."""
    component_name = ipxact_data['name']
    registers = ipxact_data['registers']
    enums = ipxact_data.get('enums', {})
    
    # Identifica registradores com campos de entrada HW
    hw_input_regs = [
        reg_name for reg_name, reg_info in registers.items()
        if any(needs_hw_input(f_info) for f_info in reg_info['fields'].values())
    ]
    
    return {
        'name': component_name,
        'registers': registers,
        'enums': enums,
        'hw_input_regs': hw_input_regs
    }


def _write_package_header(f, component_data):
    """Escreve o cabeçalho do package."""
    f.write(f"// Package {component_data['name']}_pkg - Gerado automaticamente em {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n")
    f.write("// Estruturas typedef para interface CSR\n\n")
    f.write(f"package {component_data['name']}_pkg;\n\n")

def _write_single_enum(f, enum_name, enum_values):
    """Escreve uma única definição de enum."""
    enum_size = max(len(bin(len(enum_values))) - 3, 1)
    f.write(f"    typedef enum logic [{enum_size}:0] {{\n")
    
    items = list(enum_values.items())
    last_value, _ = items[-1]
    
    for value, name in items:
        clean_name = name.replace('\\', '').replace(' ', '_')
        separator = ",\n" if value != last_value else "\n"
        f.write(f"        {clean_name} = {value}{separator}")
    
    f.write(f"    }} {enum_name};\n\n")

def _write_input_structures(f, component_data):
    """Escreve estruturas de entrada (hardware -> registrador)."""
    f.write("    // Input structures (Hardware -> Register)\n")
    # Structs para campos individuais que precisam de entrada HW
    for reg_name, reg_info in component_data['registers'].items():
        for field_name, field_info in reg_info['fields'].items():
            if needs_hw_input(field_info):
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
        hw_input_fields = [f for f, info in reg_info['fields'].items() if needs_hw_input(info)]
        if hw_input_fields:
            f.write(f"    typedef struct {{\n")
            for field_name in hw_input_fields:
                f.write(f"        {component_data['name']}__{reg_name}__{field_name}__in_t {field_name};\n")
            f.write(f"    }} {component_data['name']}__{reg_name}__in_t;\n\n")
    
    # Struct principal de entrada
    hw_input_regs = [r for r, info in component_data['registers'].items() 
                    if any(needs_hw_input(f_info) for f_info in info['fields'].values())]
    if hw_input_regs:
        f.write(f"    typedef struct {{\n")
        for reg_name in hw_input_regs:
            f.write(f"        {component_data['name']}__{reg_name}__in_t {reg_name};\n")
        f.write(f"    }} {component_data['name']}__in_t;\n\n")

def _write_output_structures(f, component_data):
    """Escreve estruturas de saída (registrador -> hardware)."""
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