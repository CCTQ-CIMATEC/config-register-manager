# LaTeX to AMBA-Compatible Register Generator

## Overview
This project automates the generation of AMBA-compatible configuration registers for IP cores, starting from a register specification written in **LaTeX**.  
It extracts the register configuration from LaTeX tables, converts it into **IP-XACT** format, and then generates the corresponding **RTL code** for integration with AMBA bus interfaces.

## Features
- **LaTeX Parsing** – Reads register definitions from LaTeX tables.
- **IP-XACT Generation** – Converts LaTeX specifications into standard IP-XACT format.
- **RTL Generation** – Produces synthesizable RTL code for AMBA-compatible configuration registers.
- **Automation Script** – Single script to handle parsing, conversion, and generation.

## Workflow
1. **Write** the register configuration in a LaTeX table.
2. **Run** 
```bash
./bin/updateConfigRegister.sh
```
the provided shell script to:
   - LaTeX table → IP-XACT  
   - IP-XACT → RTL (AMBA-compatible)
3. **Integrate** the generated RTL into your IP core design.
