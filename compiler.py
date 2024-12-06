import sys

# Opcode and function code definitions for MIPS instructions
INSTRUCTION_SET = {
    "R": {
        "SLL": 0x00, "SRL": 0x02, "SRA": 0x03, "SLLV": 0x04,
        "SRLV": 0x06, "SRAV": 0x07, "ADDU": 0x21, "SUBU": 0x23,
        "AND": 0x24, "OR": 0x25, "XOR": 0x26, "NOR": 0x27,
        "SLT": 0x2A, "SLTU": 0x2B, "JR": 0x08, "JALR": 0x09
    },
    "I": {
        "LB": 0x20, "LH": 0x21, "LW": 0x23, "LWU": 0x27,
        "LBU": 0x24, "LHU": 0x25, "SB": 0x28, "SH": 0x29,
        "SW": 0x2B, "ADDI": 0x08, "ADDIU": 0x09, "ANDI": 0x0C,
        "ORI": 0x0D, "XORI": 0x0E, "LUI": 0x0F, "SLTI": 0x0A,
        "SLTIU": 0x0B, "BEQ": 0x04, "BNE": 0x05
    },
    "J": {
        "J": 0x02, "JAL": 0x03
    }
}

def parse_register(reg):
    """Parses a MIPS register and returns its binary representation."""
    if not reg.startswith("$"):
        raise ValueError(f"Invalid register format: {reg}")
    return int(reg[1:])

def assemble_line(line):
    """Assembles a single MIPS instruction into its hexadecimal representation."""
    parts = line.strip().split()
    if not parts:
        return None

    opcode, *operands = parts
    binary_instruction = 0

    if opcode in INSTRUCTION_SET["R"]:
        funct = INSTRUCTION_SET["R"][opcode]
        if opcode == "JR":
            rs = parse_register(operands[0])
            binary_instruction = (rs << 21) | funct
        elif opcode == "JALR":
            rs = parse_register(operands[0])
            rd = parse_register(operands[1])
            binary_instruction = (rs << 21) | (rd << 11) | funct
        else:
            rd = parse_register(operands[0])
            rs = parse_register(operands[1])
            rt = parse_register(operands[2])
            shamt = int(operands[3]) if len(operands) > 3 else 0
            binary_instruction = (rs << 21) | (rt << 16) | (rd << 11) | (shamt << 6) | funct

    elif opcode in INSTRUCTION_SET["I"]:
        opc = INSTRUCTION_SET["I"][opcode]
        rt = parse_register(operands[0])
        print(str(rt))
        rs = parse_register(operands[1])
        imm = int(operands[2]) & 0xFFFF
        binary_instruction = (opc << 26) | (rs << 21) | (rt << 16) | imm

    elif opcode in INSTRUCTION_SET["J"]:
        opc = INSTRUCTION_SET["J"][opcode]
        address = int(operands[0]) & 0x3FFFFFF
        binary_instruction = (opc << 26) | address

    else:
        raise ValueError(f"Unsupported instruction: {opcode}")

    return f"{binary_instruction:08X}"

def convert_asm_to_coe(input_file, output_file):
    """Converts a MIPS assembly file to a COE file."""
    try:
        with open(input_file, 'r') as asm_file:
            lines = asm_file.readlines()

        instructions = []
        for line in lines:
            line = line.split("#")[0].strip()  # Remove comments
            if not line:
                continue

            try:
                hex_instr = assemble_line(line)
                if hex_instr:
                    instructions.append(hex_instr)
            except Exception as e:
                print(f"Error processing line '{line}': {e}")

        with open(output_file, 'w') as coe_file:
            coe_file.write("memory_initialization_radix=16;\n")
            coe_file.write("memory_initialization_vector=\n")
            coe_file.write(",\n".join(instructions) + ";\n")

        print(f"COE file generated successfully: {output_file}")

    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    input_file = "mips.asm"
    output_file = "program.coe"
    convert_asm_to_coe(input_file, output_file)
