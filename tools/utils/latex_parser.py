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
    
    return list(set(references))

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

    return rows