import re
import os
import csv
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
    
    # Process each row
    csv_rows = []
    for row in rows:
        row = row.strip()
        if not row:
            continue
            
        # Split by & and clean each cell
        cells = re.split(r'(?<!\\)&', row)
        cleaned_cells = []
        
        for cell in cells:
            cell = cell.strip()
            # Remove remaining LaTeX commands
            cell = re.sub(r'\\[a-zA-Z]+(?:\{[^}]*\})*', '', cell)
            cell = re.sub(r'\s+', ' ', cell)
            cleaned_cells.append(cell.strip())
        
        if cleaned_cells and any(cell.strip() for cell in cleaned_cells):
            csv_rows.append(cleaned_cells)
    
    # Fill empty cells with values from above (for multirow handling)
    if csv_rows:
        max_cols = max(len(row) for row in csv_rows)
        for row in csv_rows:
            while len(row) < max_cols:
                row.append('')
        
        # Fill empty cells in first few columns
        for col_idx in range(min(3, max_cols)):
            for row_idx in range(len(csv_rows)):
                if not csv_rows[row_idx][col_idx].strip() and row_idx > 0:
                    for prev_row_idx in range(row_idx - 1, -1, -1):
                        if csv_rows[prev_row_idx][col_idx].strip():
                            csv_rows[row_idx][col_idx] = csv_rows[prev_row_idx][col_idx]
                            break
    
    return csv_rows

def save_table_to_csv(csv_rows, output_file):
    """
    Save CSV rows to file

    Args:
        csv rows : clean csv table
        output_file : name of the file to save/create
    """
    os.makedirs(os.path.dirname(output_file), exist_ok=True)
    
    with open(output_file, 'w', newline='', encoding='utf-8') as csvfile:
        writer = csv.writer(csvfile)
        writer.writerows(csv_rows)
    
    print(f"  Saved: {output_file} ({len(csv_rows)} rows)")

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
        file_name = os.path.join(output_dir, f"table_{idx}.csv")
        save_table_to_csv(csv_rows=table_csv, output_file=file_name)
        print(f"Table {ref} was created with name table_{idx}.csv\n")

    print("End of operation")
    return True

def main():
    tex_file = "src/ipMap.tex"
    output_dir = "build"
    
    if not os.path.exists(tex_file):
        print(f"Error: File not found: {tex_file}")
        return
    
    # Read LaTeX file
    try:
        with open(tex_file, 'r', encoding='utf-8') as f:
            latex_content = f.read()
    except Exception as e:
        print(f"Error reading file: {e}")
        return
    
    # Process tables
    process_latex_tables(latex_content, output_dir)

if __name__ == "__main__":
    main()