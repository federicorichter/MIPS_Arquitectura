import serial
import time
import sys

def setup_serial(port='/dev/ttyUSB1', baudrate=9543, timeout=1):
    try:
        ser = serial.Serial(port, baudrate, timeout=timeout, parity=serial.PARITY_NONE)
        print(f"Serial port {port} opened successfully.")
        return ser
    except Exception as e:
        print(f"Error opening serial port: {e}")
        sys.exit(1)

def load_instructions_from_coe(filename):
    try:
        with open(filename, 'r') as file:
            lines = file.readlines()

        instructions = []
        for line in lines:
            line = line.strip()
            if line.startswith("memory_initialization_vector="):
                vector_line = line.split('=')[1].strip()
                vector_line = vector_line.rstrip(';')  # Remove trailing semicolon
                instructions.extend(vector_line.split(','))  # Split instructions
            elif not line.startswith("memory_initialization_radix") and line:
                instructions.extend(line.rstrip(';').split(','))  # Handle subsequent lines
        
        # Convert hex strings to integers
        return [int(instr.strip(), 16) for instr in instructions if instr.strip()]
    
    except FileNotFoundError:
        print(f"Error: File '{filename}' not found.")
        sys.exit(1)
    except Exception as e:
        print(f"Error reading file '{filename}': {e}")
        sys.exit(1)


def send_uart_command(ser, command):
    ser.write(command.to_bytes(1, byteorder='big'))
    print(f"Command sent: {command:02X} (hex), {command:08b} (bin)")

def send_uart_data(ser, data, data_size):
    for i in range(data_size // 8):
        byte = (data >> (8 * i)) & 0xFF
        send_uart_command(ser, byte)
        time.sleep(0.01)

def receive_data_from_uart(ser, num_bytes):
    data = ser.read(num_bytes)
    if len(data) < num_bytes:
        print(f"Warning: Received {len(data)} bytes, expected {num_bytes}.")
    print("Data received:", " ".join(f"{byte:02X}" for byte in data))
    return data

def wait_for_ready(ser):
    print("Waiting for 'R'...")
    while True:
        response = ser.read(1)
        if response == b'R':
            print("Ready signal received.")
            break

def send_instructions(ser, instructions):
    send_uart_command(ser, 0x07)  # Start loading program
    send_uart_command(ser, len(instructions) + 15)  # Number of instructions
    for instruction in instructions:
        send_uart_data(ser, instruction, 32)
        time.sleep(0.01)
    for _ in range(15):
        send_uart_data(ser, 0, 32)
        time.sleep(0.01)
    wait_for_ready(ser)

def request_latch(ser, latch_command, expected_size):
    if latch_command not in range(0x01, 0x06):
        raise ValueError("Invalid latch command.")
    send_uart_command(ser, latch_command)
    latchdata = receive_data_from_uart(ser, expected_size)
    if(latch_command == 0x01):
        print("Registers received:")
        for i in range(0, 128, 4):
            print(f"R{i/4}: {latchdata[i:i+4].hex()}")
    return latchdata

def request_instruction_memory(ser):
    send_uart_command(ser, 0x10)
    data = receive_data_from_uart(ser, 256)
    wait_for_ready(ser)
    return data

def menu():
    print("\n--- UART Communication Menu ---")
    print("1. Set Continuous Mode")
    print("2. Set Step-by-step")
    print("3. Send Instructions to Instruction Memory")
    print("4. Start Program Execution")
    print("5. Request IF/ID Latch")
    print("6. Request ID/EX Latch")
    print("7. Request EX/MEM Latch")
    print("8. Request MEM/WB Latch")
    print("9. Request Registers")
    print("10. Step Debugger")
    print("11. Print memory data location")
    print("12. Load instructions file")
    print("13. Print instruction memory")
    print("14. Request PC")  # Nueva opción para solicitar el PC
    print("0. Exit")
    choice = input("Enter your choice: ")
    return choice

def main():
    ser = setup_serial()

    program2 = [
        0x3C010003,  # LUI R1, 3
        0x3C020001,  # LUI R2, 1
        0x3C030009,  # LUI R3, 9
        0x3C040007,  # LUI R4, 7
        0x3C050003,  # LUI R5, 3
        0x3C060065,  # LUI R6, 101
        0x3C070019,  # LUI R7, 25
        0x00022023,  # SUB R3, R1, R2 -> 2
        0x00642821,  # ADD R5, R3, R4 -> 9
        0x00663021,  # ADD R7, R3, R6 -> 103
        0x00652821,  # ADD R15, R3, R5
        0x3C0F012C,  # LUI R15, 300
        0x3C010003,  # LUI R1, 3
        0x3C010003,  # LUI R1, 3
        0x3C010003   # LUI R1, 3
    ]

    instructions = [
        0x3C010008,  # LUI R1, 8
        0x3C030006,  # LUI R3, 6
        0x3C030006,  # LUI R3, 6
        0x3C030006,  # LUI R3, 6
        0x01092009,  # JALR, R1, R9
        0x3C030003,  # LUI R3, 3
        0x3C03000F,  # LUI R3, 15
        0x3C03000D,  # LUI R3, 13
    ]

    program_2 = [
        0x200A000F, # ADDI R10, R0, 15 
        0x2014000F, # ADDI R20, R0, 15
        0x11540003, # BEQ R10, R20, 3
        0x0,        # NOP
        0x20040028, # ADDI R4, R0, 40
        0x20050032, # ADDI R5, R0, 50
        0x20060032, # ADDI R6, R0, 50
        0x2001000A, # ADDI R1, R0, 10
        0x20020012, # ADDI R2, R0, 18
        0x2003001E  # ADDI R3, R0, 30
    ]

    program_j = [
        0x8000005, # J 5
        0x0,        # NOP
        0x20040028, # ADDI R4, R0, 40
        0x20050032, # ADDI R5, R0, 50
        0x20060032, # ADDI R6, R0, 50
        0x2001000A, # ADDI R1, R0, 10
        0x20020012, # ADDI R2, R0, 18
        0x2003001E  # ADDI R3, R0, 30
    ]

    program_jal = [
        0xC000005, # JAL 5 -> Revisar R31
        0x0,        # NOP
        0x20040028, # ADDI R4, R0, 40
        0x20050032, # ADDI R5, R0, 50
        0x20060032, # ADDI R6, R0, 50
        0x2001000A, # ADDI R1, R0, 10
        0x20020012, # ADDI R2, R0, 18
        0x2003001E  # ADDI R3, R0, 30
        0x3E00008   # JR R31
    ]

    
    instructions3 = [
        0x3C010001,  # LUI R1, 1
        0x3C030003,  # LUI R3, 3
        0x3C2B0001,  # NOP
        0xA4210001,  # SH, R1 -> MEM[1]
        0x84250001,  # LH, R5 <- MEM[1]
        0x02B31C21,  # R7 = R5 + R3
    ]
    
    instructions4 = [
        0x200F000F,  # ADDI R1, R0, 15
        0xA0000000,  # SB R1, 0(0)
        0x20420007,  # ADDI R2, R1, 7
        0xA0020008,  # SB R2, 8(0)
        0x80030008,  # LB R3, 8(0)
        0x3064000B,  # ANDI R4, R3, 11
    ]
    
    instructions5 = [
        0x200A000F,  # ADDI R10, R0, 15
        0x200A000F,  # ADDI R20, R0, 15
        0x11500003,  # BNEQ R10, R20, 3
        0x20040028,  # ADDI R4, R0, 40
        0x20050032,  # ADD R5, R0, 50
    ]

    instructions6 = [
        0b00100000000000010000000000000110,  # ADDI R1, R0, 6
        0b00000000001000000101000000001001,  # JALR R10, R1
        0b00000000000000000000000000000000,  # NOP
        0b00100000000001000000000000000111,  # ADDI R4, R0, 40
        0b00100000000001010000000000000111,  # ADDI R5, R0, 40 -> Despues salta aca
        0b00100000000001100000000000000111,  # ADDI R6, R0, 40
        0b00100000000000010000000000001010,  # ADDI R1, R0, 10 -> Debería saltar acá
        0b00100000000000100000000000000101,  # ADDI R2, R0, 5
        0b00100000000000110000000000000111,  # ADDI R3, R0, 7
        0b00000001010000000000000000001000   # JR R10
    ]


    latch_data = {
        "5": (0x02, 4),  # IF/ID
        "6": (0x03, 17), # ID/EX
        "7": (0x04, 10), # EX/MEM
        "8": (0x05, 9),  # MEM/WB
        "9": (0x01, 128) # REGISTERS
    }

    try:
        while True:
            choice = menu()

            if choice == "1":
                send_uart_command(ser, 0x08)  # Set Continuous Mode

            elif choice == "2":
                send_uart_command(ser, 0x09)

            elif choice == "3":
                send_instructions(ser, instructions)

            elif choice == "4":
                send_uart_command(ser, 0x0D)  # Start Program Execution

            elif choice in latch_data:
                latch_name = {"5": "IF/ID", "6": "ID/EX", "7": "EX/MEM", "8": "MEM/WB", "9": "REGISTERS"}[choice]
                print(f"Requesting {latch_name} latch...")
                command, size = latch_data[choice]
                data = request_latch(ser, command, size)
                print(f"{latch_name} Data: {data}")
                print(f"{latch_name} Data in bits: {' '.join(f'{byte:08b}' for byte in data)}")
                wait_for_ready(ser)
           
            elif choice == "10":
                send_uart_command(ser, 0x0A) # Step debugger

            elif choice == "11":
                send_uart_command(ser, 0x0B) # Print data memory
                position = input("Enter memory position (0-1023): ")
                if position.isdigit() and 0 <= int(position) <= 1023:
                    send_uart_command(ser, int(position))
                    receive_data_from_uart(ser, 4)
                    wait_for_ready(ser)
                else:
                    print("Invalid position. Please enter a number between 0 and 1023.")

                
            elif choice == "12": 
                print("Loading instructions frome .coe file")
                coe_file = "program.coe"
                instructions = load_instructions_from_coe(coe_file)

            elif choice == "13":
                print("Requesting instruction memory...")
                data = request_instruction_memory(ser)
                print(f"Instruction Memory Data: {data}")
                print(f"Instruction Memory Data in bits: {' '.join(f'{byte:08b}' for byte in data)}")

            elif choice == "14":
                send_uart_command(ser, 0x11)  # Command to request PC
                pc_data = receive_data_from_uart(ser, 4)  # Assuming PC is 4 bytes
                print(f"PC Data: {pc_data}")
                print(f"PC Data in bits: {' '.join(f'{byte:08b}' for byte in pc_data)}")
                wait_for_ready(ser)

            elif choice == "0":
                print("Exiting...")
                break

            else:
                print("Invalid choice. Please try again.")

    except Exception as e:
        print(f"Error: {e}")

    finally:
        ser.close()
        print("Serial port closed.")

if __name__ == "__main__":
    main()