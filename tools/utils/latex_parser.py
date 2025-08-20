import re
import os
from pathlib import Path

def extract_table_with_label(latex_content, target_label):
    """
    Extract a specific table by its label

    Args:
        latex_content: latex content inside the .text
        target_label:  label that is gonna be used to search for

    Returns:
        table with match of ref
    """
    # Pattern to match table with specific label
    pattern = r'\\begin{table}.*?\\label{' + re.escape(target_label) + r'}.*?\\begin{tabular}\{[^}]*\}(.*?)\\end{tabular}.*?\\end{table}'
    match = re.search(pattern, latex_content, re.DOTALL)
    
    if match:
        return match.group(1)
    return None

def extract_references_from_table(table_content):
    """
    Extract references from table content

    Args:
        table: table to extract refs from

    Returns:
        list with refs
    """
    references = []
    
    # Look for \ref{} commands
    ref_matches = re.findall(r'\\ref{([^}]+)}', table_content)
    references.extend(ref_matches)
    
    # Look for patterns like "tabela_IP_B" or similar reference patterns
    text_refs = re.findall(r'tabela[_\s]*([A-Za-z0-9_-]+)', table_content, re.IGNORECASE)
    references.extend([f"table:{ref}" for ref in text_refs])
    
    # Look for other reference patterns
    other_refs = re.findall(r'table[_\s]*([A-Za-z0-9_-]+)', table_content, re.IGNORECASE)
    references.extend([f"table:{ref}" for ref in other_refs])
    
    return list(set(references))  # Remove duplicates

def clean_table_content(table_content):
        """
    Clean LaTeX table content and convert to CSV-ready format

    Args:
        table:  table input

    Returns:
        clean table fitting the csv format
    """
    table_content = table_content.strip()
    
    # Remove LaTeX commands
    table_content = re.sub(r'\\(?:hline|toprule|midrule|bottomrule|cline\{[^}]*\})', '', table_content)
    
    # Handle multirow and multicolumn commands
    table_content = re.sub(r'\\multirow\{[^}]*\}\{[^}]*\}\{([^}]*)\}', r'\1', table_content)
    table_content = re.sub(r'\\multicolumn\{[^}]*\}\{[^}]*\}\{([^}]*)\}', r'\1', table_content)
    table_content = re.sub(r'\\(?:textbf|textit|emph)\{([^}]*)\}', r'\1', table_content)
    table_content = re.sub(r'\\fontsize\{[^}]*\}\{[^}]*\}\\selectfont', '', table_content)
    
    # Split into rows by \\
    rows = re.split(r'\\\\', table_content)

def process_latex_tables(latex_content, output_dir="build"):
    """
    Main function to process LaTeX tables based on the system address map

    Args:
        latex_content : raw data inside .text
        output_dir : dir to save result

    Returns:
        True if operation sucessufl
    """
    print("Processing LaTeX tables...\n")
    
    #Find the main system address map table
    main_table_label = "table:system_address_map"
    main_table_content = extract_table_with_label(latex_content, main_table_label)
    
    if not main_table_content:
        print(f"Error: Could not find table with label '{main_table_label}'")
        return False
    
    print(f"Found main table: {main_table_label}")
    
    main_csv = clean_table_content(table_content=main_table_content)

    main_name = os.path.join(output_dir, f"table_main.csv")
    save_table_to_csv(csv_rows=main_csv, output_file=main_name)

    #extract references from the main table
    references = extract_references_from_table(main_table_content)
    print(f"Found references: {references}")
    
    #go through the refs
    for idx, ref in enumerate(references):
        #get table with certain label code
        table = extract_table_with_label(latex_content, target_label=ref)

        #keep it clean fit for an csv
        table_csv = clean_table_content(table_content=table)

        #save on an table
        ref_str = ref.replace("table:", "RegisterMap_", 1)
        file_name = os.path.join(output_dir, f"{ref_str}.csv")
        save_table_to_csv(csv_rows=table_csv, output_file=file_name)
        print(f"Table {ref} was created with name {ref}.csv\n")

    print("End of operation")
    return True