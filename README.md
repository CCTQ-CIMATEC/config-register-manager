# LaTeX to AMBA-Compatible Register Generator

A comprehensive tool for automating the generation of AMBA-compatible configuration registers for IP cores, streamlining the workflow from specification to RTL implementation.

## Overview
This project automates the generation of AMBA-compatible configuration registers for IP cores, starting from a register specification written in **LaTeX**.  
It extracts the register configuration from LaTeX tables, converts it into **IP-XACT** format, and then generates the corresponding **RTL code** for integration with AMBA bus interfaces.

## Features
- **LaTeX Parsing** – Reads register definitions from LaTeX tables.
- **IP-XACT Generation** – Converts LaTeX specifications into standard IEEE 1685-2022 IP-XACT format.
- **RTL Generation** – Produces synthesizable RTL code for AMBA-compatible configuration registers.
- **Automation Script** – Single script to handle parsing, conversion, and generation.

## Repo layout

```text
├── bin
│   ├── csv2ipxact.py # Convert an file from CSV to IP-XACT
│   ├── ipxact2rtl.py # Convert from IP-XACT to RTL code
│   ├── ipxact2rtl.sh # Bash Script to convert IP-XACT to rtl
│   ├── latex2csv.py  # Convert from latex table to CSV format
│   └── updateConfigRegister.sh # Bash Script to execute the pipeline
├── README.md
└── src
    └── ipMap.tex # The Latex document as input
```

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
