#!/usr/bin/env python3

import argparse
import os
import sys


class MipsTranslator:
    def __init__(self):
        # Instruction Types and their formats
        self.R_TYPE = 0
        self.I_TYPE = 1 
        self.J_TYPE = 2

        # Register mapping
        self.registers = {
            '$zero': 0,  '$0': 0,
            '$at': 1,    '$1': 1,
            '$v0': 2,    '$2': 2,    '$v1': 3,    '$3': 3,
            '$a0': 4,    '$4': 4,    '$a1': 5,    '$5': 5,
            '$a2': 6,    '$6': 6,    '$a3': 7,    '$7': 7,
            '$t0': 8,    '$8': 8,    '$t1': 9,    '$9': 9,
            '$t2': 10,   '$10': 10,  '$t3': 11,   '$11': 11,
            '$t4': 12,   '$12': 12,  '$t5': 13,   '$13': 13,
            '$t6': 14,   '$14': 14,  '$t7': 15,   '$15': 15,
            '$s0': 16,   '$16': 16,  '$s1': 17,   '$17': 17,
            '$s2': 18,   '$18': 18,  '$s3': 19,   '$19': 19,
            '$s4': 20,   '$20': 20,  '$s5': 21,   '$21': 21,
            '$s6': 22,   '$22': 22,  '$s7': 23,   '$23': 23,
            '$t8': 24,   '$24': 24,  '$t9': 25,   '$25': 25,
            '$k0': 26,   '$26': 26,  '$k1': 27,   '$27': 27,
            '$gp': 28,   '$28': 28,  '$sp': 29,   '$29': 29,
            '$fp': 30,   '$30': 30,  '$ra': 31,   '$31': 31
        }

        # Instruction definitions
        self.instructions = {
            # R-Type
            'sll':  {'type': self.R_TYPE, 'opcode': 0x00, 'funct': 0x00},
            'srl':  {'type': self.R_TYPE, 'opcode': 0x00, 'funct': 0x02},
            'sra':  {'type': self.R_TYPE, 'opcode': 0x00, 'funct': 0x03},
            'sllv': {'type': self.R_TYPE, 'opcode': 0x00, 'funct': 0x04},
            'srlv': {'type': self.R_TYPE, 'opcode': 0x00, 'funct': 0x06},
            'srav': {'type': self.R_TYPE, 'opcode': 0x00, 'funct': 0x07},
            'addu': {'type': self.R_TYPE, 'opcode': 0x00, 'funct': 0x21},
            'subu': {'type': self.R_TYPE, 'opcode': 0x00, 'funct': 0x23},
            'and':  {'type': self.R_TYPE, 'opcode': 0x00, 'funct': 0x24},
            'or':   {'type': self.R_TYPE, 'opcode': 0x00, 'funct': 0x25},
            'xor':  {'type': self.R_TYPE, 'opcode': 0x00, 'funct': 0x26},
            'nor':  {'type': self.R_TYPE, 'opcode': 0x00, 'funct': 0x27},
            'slt':  {'type': self.R_TYPE, 'opcode': 0x00, 'funct': 0x2a},
            'sltu': {'type': self.R_TYPE, 'opcode': 0x00, 'funct': 0x2b},
            'jr':   {'type': self.R_TYPE, 'opcode': 0x00, 'funct': 0x08},
            'jalr': {'type': self.R_TYPE, 'opcode': 0x00, 'funct': 0x09},

            # I-Type
            'lb':   {'type': self.I_TYPE, 'opcode': 0x20},
            'lh':   {'type': self.I_TYPE, 'opcode': 0x21},
            'lw':   {'type': self.I_TYPE, 'opcode': 0x23},
            'lwu':  {'type': self.I_TYPE, 'opcode': 0x27},
            'lbu':  {'type': self.I_TYPE, 'opcode': 0x24},
            'lhu':  {'type': self.I_TYPE, 'opcode': 0x25},
            'sb':   {'type': self.I_TYPE, 'opcode': 0x28},
            'sh':   {'type': self.I_TYPE, 'opcode': 0x29},
            'sw':   {'type': self.I_TYPE, 'opcode': 0x2b},
            'addi': {'type': self.I_TYPE, 'opcode': 0x08},
            'addiu':{'type': self.I_TYPE, 'opcode': 0x09},
            'andi': {'type': self.I_TYPE, 'opcode': 0x0c},
            'ori':  {'type': self.I_TYPE, 'opcode': 0x0d},
            'xori': {'type': self.I_TYPE, 'opcode': 0x0e},
            'lui':  {'type': self.I_TYPE, 'opcode': 0x0f},
            'slti': {'type': self.I_TYPE, 'opcode': 0x0a},
            'sltiu':{'type': self.I_TYPE, 'opcode': 0x0b},
            'beq':  {'type': self.I_TYPE, 'opcode': 0x04},
            'bne':  {'type': self.I_TYPE, 'opcode': 0x05},

            # J-Type
            'j':    {'type': self.J_TYPE, 'opcode': 0x02},
            'jal':  {'type': self.J_TYPE, 'opcode': 0x03}
        }

    def parse_register(self, reg):
        if reg in self.registers:
            return self.registers[reg]
        raise ValueError(f"Invalid register: {reg}")

    def parse_immediate(self, imm):
        try:
            if imm.startswith('0x'):
                return int(imm, 16)
            elif imm.startswith('0b'):
                return int(imm, 2)
            return int(imm)
        except ValueError:
            raise ValueError(f"Invalid immediate value: {imm}")

    def encode_r_type(self, opcode, rs, rt, rd, shamt, funct):
        return (opcode << 26) | (rs << 21) | (rt << 16) | (rd << 11) | (shamt << 6) | funct

    def encode_i_type(self, opcode, rs, rt, imm):
        # Handle negative immediates
        if imm < 0:
            imm = imm & 0xFFFF
        return (opcode << 26) | (rs << 21) | (rt << 16) | (imm & 0xFFFF)

    def encode_j_type(self, opcode, addr):
        return (opcode << 26) | (addr & 0x3FFFFFF)

    def translate_instruction(self, instruction):
        parts = instruction.lower().replace(',', ' ').split()
        op = parts[0]

        if op not in self.instructions:
            raise ValueError(f"Unknown instruction: {op}")

        inst_type = self.instructions[op]['type']
        opcode = self.instructions[op]['opcode']

        if inst_type == self.R_TYPE:
            if op in ['jr']:
                rs = self.parse_register(parts[1])
                return self.encode_r_type(opcode, rs, 0, 0, 0, self.instructions[op]['funct'])
            elif op in ['jalr']:
                rd = self.parse_register(parts[1])
                rs = self.parse_register(parts[2])
                return self.encode_r_type(opcode, rs, 0, rd, 0, self.instructions[op]['funct'])
            else:
                rd = self.parse_register(parts[1])
                rs = self.parse_register(parts[2])
                rt = self.parse_register(parts[3])
                return self.encode_r_type(opcode, rs, rt, rd, 0, self.instructions[op]['funct'])

        elif inst_type == self.I_TYPE:
            if op in ['beq', 'bne']:
                rs = self.parse_register(parts[1])
                rt = self.parse_register(parts[2])
                imm = self.parse_immediate(parts[3])
                return self.encode_i_type(opcode, rs, rt, imm)
            elif op in ['lw', 'sw', 'lb', 'sb', 'lh', 'sh']:
                rt = self.parse_register(parts[1])
                offset_base = parts[2].replace('(', ' ').replace(')', ' ').split()
                offset = self.parse_immediate(offset_base[0])
                rs = self.parse_register(offset_base[1])
                return self.encode_i_type(opcode, rs, rt, offset)
            else:
                rt = self.parse_register(parts[1])
                rs = self.parse_register(parts[2])
                imm = self.parse_immediate(parts[3])
                return self.encode_i_type(opcode, rs, rt, imm)

        elif inst_type == self.J_TYPE:
            addr = self.parse_immediate(parts[1])
            return self.encode_j_type(opcode, addr)

def process_asm_file(input_file):
    translator = MipsTranslator()
    instructions = []
    
    try:
        with open(input_file, 'r') as f:
            for line in f:
                # Skip empty lines and comments
                line = line.strip()
                if not line or line.startswith('#'):
                    continue
                try:
                    machine_code = translator.translate_instruction(line)
                    instructions.append(machine_code)
                except (ValueError, IndexError) as e:
                    print(f"Error in line '{line}': {e}")
                    sys.exit(1)
    except FileNotFoundError:
        print(f"Error: Input file '{input_file}' not found")
        sys.exit(1)
    
    return instructions

def generate_coe_file(instructions, output_file):
    try:
        with open(output_file, 'w') as f:
            # Write instructions in binary format with commas and newlines
            for i, inst in enumerate(instructions):
                if i < len(instructions) - 1:
                    f.write(f"{inst:032b},\n")
                else:
                    f.write(f"{inst:032b}")
                    
    except IOError as e:
        print(f"Error writing output file: {e}")
        sys.exit(1)

def main():
    # Parse command line arguments
    parser = argparse.ArgumentParser(description='MIPS Assembly to COE converter')
    parser.add_argument('input_file', help='Input .asm file path')
    args = parser.parse_args()

    # Validate input file
    if not args.input_file.endswith('.asm'):
        print("Error: Input file must have .asm extension")
        sys.exit(1)

    # Generate output filename
    output_file = os.path.splitext(args.input_file)[0] + '.coe'

    # Process input file and generate instructions
    instructions = process_asm_file(args.input_file)
    
    # Generate COE file
    generate_coe_file(instructions, output_file)
    
    print(f"Successfully converted {args.input_file} to {output_file}")

if __name__ == "__main__":
    main()