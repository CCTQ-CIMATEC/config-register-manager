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