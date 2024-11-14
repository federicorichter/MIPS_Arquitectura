import re

# Archivo de entrada y salida
input_file = 'control_unit.v'
output_file = 'control_bits.txt'

# Lista para almacenar los nombres de los bits de control en el orden correcto
control_bits_order = [
    'JUMP_OR_B', 'JUMP_SRC', 'EQorNE', 'J_RET_DST', 'MEM_2_REG',
    'ALU_OP2', 'ALU_OP1', 'ALU_OP0', 'ALU_SRC', 'SHIFT_SRC',
    'REG_DST', 'MASK_2', 'MASK_1', 'MEM_WRITE', 'MEM_READ',
    'UNSIGNED', 'BRANCH', 'REG_WRITE'
]

# Expresión regular para encontrar los comentarios
pattern = re.compile(r'//\s*(\w+)\s*=\s*(\d{1,3})')

# Leer el archivo de entrada
with open(input_file, 'r') as file:
    lines = file.readlines()

# Inicializar variables
control_bits = {bit: 0 for bit in control_bits_order}
case_lines = []
inside_case = False
current_case = ""

# Procesar cada línea del archivo
for line in lines:
    if 'casez' in line:
        inside_case = True
    elif 'endcase' in line:
        inside_case = False
    elif inside_case:
        if ':' in line and 'control_reg' in line:
            if current_case:
                # Procesar el caso actual
                binary_value = ''.join(str(control_bits[bit]) for bit in control_bits_order)
                case_lines.append(f'{current_case}: control_reg = 18\'b{binary_value};\n')
                control_bits = {bit: 0 for bit in control_bits_order}  # Reset control bits for next case
            current_case = line.split(':')[0].strip()
        match = pattern.search(line)
        if match:
            bit_name = match.group(1)
            bit_value = match.group(2)
            if bit_name == 'ALU_OP':
                control_bits['ALU_OP2'] = int(bit_value[0])
                control_bits['ALU_OP1'] = int(bit_value[1])
                control_bits['ALU_OP0'] = int(bit_value[2])
            elif bit_name in control_bits:
                control_bits[bit_name] = int(bit_value)

# Procesar el último caso si existe
if current_case:
    binary_value = ''.join(str(control_bits[bit]) for bit in control_bits_order)
    case_lines.append(f'{current_case}: control_reg = 18\'b{binary_value};\n')

# Escribir los casos procesados en el archivo de salida
with open(output_file, 'w') as file:
    file.writelines(case_lines)

print(f'Los valores binarios correspondientes a los comentarios se han guardado en {output_file}')