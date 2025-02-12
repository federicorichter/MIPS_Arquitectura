import sys

def txt_to_mermaid(input_file, output_file):
    with open(input_file, 'r', encoding='utf-8') as f:
        lines = f.readlines()

    # Filtrar líneas relevantes (las del diagrama Mermaid)
    mermaid_lines = []
    for line in lines:
        # Puedes personalizar la lógica si quieres omitir o modificar algo
        mermaid_lines.append(line)

    # Guardar en un archivo .mmd
    with open(output_file, 'w', encoding='utf-8') as out:
        out.write(''.join(mermaid_lines))

if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("Uso: python script.py <input_diagram.txt> <output_diagram.mmd>")
        sys.exit(1)
    txt_to_mermaid(sys.argv[1], sys.argv[2])