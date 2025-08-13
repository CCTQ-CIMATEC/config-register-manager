import re
import os
import csv

def latex_table_to_csv(latex_content, output_file):
    """
    Convert a LaTeX tabular environment to CSV format
    """

    # filter table
    matches = re.findall(r'\\begin{tabular}\{[^}]*\}(.*?)\\end{tabular}', latex_content, re.DOTALL)
    
    if not matches:
        print("No tabble in file")
        return False
    

    all_csv_rows = []

    for table_i, table_content in enumerate(matches):
        
        table_content = table_content.strip()

        #remove latex macro
        table_content = re.sub(r'\\(?:hline|toprule|midrule|bottomrule|cline\{[^}]*\})', '', table_content)
        
        #handle multirow and multicolumn commands
        table_content = re.sub(r'\\multirow\{[^}]*\}\{[^}]*\}\{([^}]*)\}', r'\1',           table_content)
        table_content = re.sub(r'\\multicolumn\{[^}]*\}\{[^}]*\}\{([^}]*)\}', r'\1',        table_content)
        table_content = re.sub(r'\\(?:textbf|textit|emph)\{([^}]*)\}', r'\1',               table_content)
    
        #split into rows by \\
        rows = re.split(r'\\\\', table_content)
    
        #process each row
        csv_rows = []
        for row in rows:
            row = row.strip()
            if not row:
                continue
                
            # split by & and clean each cell
            cells = re.split(r'(?<!\\)&', row)
            cleaned_cells = []
            
            for cell in cells:
                cell = cell.strip()
                cell = re.sub(r'\\[a-zA-Z]+(?:\{[^}]*\})*', '', cell)
                cell = re.sub(r'\s+', ' ', cell)
                cleaned_cells.append(cell.strip())
            
            if cleaned_cells and any(cell.strip() for cell in cleaned_cells):
                csv_rows.append(cleaned_cells)
    
        #handle merged cells by filling empty cells with values from above
        if csv_rows:
            max_cols = max(len(row) for row in csv_rows)
            for row in csv_rows:
                while len(row) < max_cols:
                    row.append('')
            
            #fill empty cells in first few columns
            for col_idx in range(min(3, max_cols)):  #check first 3 columns
                for row_idx in range(len(csv_rows)):
                    if not csv_rows[row_idx][col_idx].strip() and row_idx > 0:
                        for prev_row_idx in range(row_idx - 1, -1, -1):
                            if csv_rows[prev_row_idx][col_idx].strip():
                                csv_rows[row_idx][col_idx] = csv_rows[prev_row_idx][col_idx]
                                break


        print(f"  Table {table_i + 1}: Found {len(csv_rows)} rows")


        if table_i > 0 and csv_rows:
            all_csv_rows.append([''] * len(csv_rows[0]))

        all_csv_rows.extend(csv_rows)

    with open(output_file, 'w', newline='', encoding='utf-8') as csvfile:
        writer = csv.writer(csvfile)
        writer.writerows(all_csv_rows)
    
    print("\nSuccess\n")
    return True

def main():
    tex_file = "src/ipMap.tex"
    csv_file = "build/ipMap.csv"
    
    #check if file exists
    if not os.path.exists(tex_file):
        print(f"Error: File not found: {tex_file}")
        return
    
    #read latex file
    try:
        with open(tex_file, 'r', encoding='utf-8') as f:
            latex_content = f.read()
    except Exception as e:
        print(f"Error reading file: {e}")
        return
    
    #convert to CSV
    success = latex_table_to_csv(latex_content, csv_file)
    
    if success:
        try:
            with open(csv_file, 'r', encoding='utf-8') as f:
                for i, line in enumerate(f):
                    if i >= 5:  # Show first 5 lines
                        break
                    print(f"  {line.rstrip()}")
        except Exception as e:
            print(f"Error reading CSV file: {e}")

if __name__ == "__main__":
    main()