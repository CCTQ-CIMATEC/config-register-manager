# LaTeX Table Specification Guide for IP-XACT 2022

## 1. General Structure

Each IP must have two main tables:

- **System Address Map**: Lists all system IPs with their base addresses and a reference to the register table of each IP.
- **IP Register Table**: Describes all registers and their detailed fields.

## 2. System Address Map Table

**Mandatory columns:**

- **IP**: Name of the IP.
- **Description**: Brief description of the IP.
- **Base Address**: Hexadecimal base address of the IP.
- **REF**: Reference to the corresponding IP register table.

**Rules:**

**- Each table must have a unique label, following the pattern `IP-{NAME}`.**
- Each row represents a different IP.
- The **REF** column must contain the label of the corresponding IP register table.
- Always use a consistent format for addresses, e.g., `0x4000_0000`.

## 3. IP Register Table

**Mandatory columns:**

- **Register**: Name of the register.
- **Offset**: Relative address of the register in hexadecimal (`0x0000`, `0x0004`, etc.).
- **Field**: Name of the field within the register.
- **Bits**: Bit position of the field, in the format `[msb:lsb]` or `[bit]`.
- **Access_Policy**: Access type, must be `RW`, `RO`, or `WO`.
- **Volatile**: Boolean indicating whether the field is volatile (`true` or `false`).
- **Reset**: Initial value of the field in hexadecimal (`'h0`, `'h1`, etc.).
- **Description**: Explanatory text of the field.
- **Enum Values**: Possible values of the field with description, in the format value:text, separated by ;. Can be left empty if there are no enums.

**Rules:**

- Each register can have multiple fields; use multirow or repeat the register name and offset across multiple rows.
- The **Bits** field must strictly follow the format `[msb:lsb]` or `[bit]`.
- Enumerations must use `value:text` for each possible value, separated by `;`. Example: `0:Idle;1:Run;2:Sleep`.
- Descriptions can be long, but avoid line breaks or special characters that the parser cannot recognize.
- All columns must be present, even if some cells are empty.

## 4. Best Practices

- Use consistent names for registers and fields, without spaces or special characters (underscores `_` only).
- Pay attention to reserved words in the language and integration platform.
- Document the purpose of each field in the **Description**.
- For status or flag fields, correctly specify whether they are volatile (`Volatile = true`) or not.
