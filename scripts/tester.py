#!/usr/bin/env python3
import serial
import time
import sys
import argparse

def setup_serial(port='/dev/ttyUSB1', baudrate=9600, timeout=1):
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
            instructions = []
            instructions.append(0)
            for line in file:
                # Remove whitespace and commas
                line = line.strip().rstrip(',')
                if line:
                    # Convert binary string to integer
                    instructions.append(int(line, 2))
        return instructions
    except FileNotFoundError:
        print(f"Error: File '{filename}' not found.")
        sys.exit(1)
    except Exception as e:
        print(f"Error reading file '{filename}': {e}")
        sys.exit(1)

def send_uart_command(ser, command):
    ser.write(command.to_bytes(1, byteorder='big'))
    #print(f"Command sent: {command:02X} (hex), {command:08b} (bin)")

def send_uart_data(ser, data, data_size):
    for i in range(data_size // 8):
        byte = (data >> (8 * i)) & 0xFF
        send_uart_command(ser, byte)
        time.sleep(0.1)

def receive_data_from_uart(ser, num_bytes):
    data = ser.read(num_bytes)
    if len(data) < num_bytes:
        print(f"Warning: Received {len(data)} bytes, expected {num_bytes}.")
    #print("Data received:", " ".join(f"{byte:02X}" for byte in data))
    return data

def wait_for_ready(ser):
    print("Waiting for 'R'...")
    start_time = time.time()
    while True:
        response = ser.read(1)
        if response == b'R':
            print("Ready signal received.")
            break
        if time.time() - start_time > 5:
            print("Timeout waiting for 'R'.")
            return False  # Indicate timeout
    return True  # Indicate success

def send_instructions(ser, instructions):
    print("Sending instructions to instruction memory...")
    send_uart_command(ser, 0x07)  # Start loading program
    send_uart_command(ser, len(instructions))  # Number of instructions
    for instruction in instructions:
        send_uart_data(ser, instruction, 32)
        time.sleep(0.01)
    if wait_for_ready(ser):
        print("Instructions loaded successfully.")
    else:
        print("Error loading instructions.")

def request_latch(ser, latch_command, expected_size):
    if latch_command not in range(0x01, 0x06):
        raise ValueError("Invalid latch command.")
    send_uart_command(ser, latch_command)
    latchdata = receive_data_from_uart(ser, expected_size)
    if latch_command == 0x01:
        print("Registers received:")
        for i in range(0, 128, 4):
            reg_value = int.from_bytes(latchdata[i:i+4], byteorder='little')
            print(f"R{i//4}: {reg_value}")
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
    print("14. Request PC")
    print("0. Exit")
    return input("Enter your choice: ")

def main():
    # Parse command line arguments
    parser = argparse.ArgumentParser(description='MIPS Instructions Loader via UART')
    parser.add_argument('coe_file', help='Path to the .coe file containing binary instructions')
    args = parser.parse_args()

    # Setup serial connection
    ser = setup_serial()

    # Load initial instructions
    instructions = load_instructions_from_coe(args.coe_file)

    latch_data = {
        "5": (0x02, 4),   # IF/ID
        "6": (0x03, 17),  # ID/EX
        "7": (0x04, 10),  # EX/MEM
        "8": (0x05, 9),   # MEM/WB
        "9": (0x01, 128)  # REGISTERS
    }

    try:
        while True:
            choice = menu()

            if choice == "1":
                send_uart_command(ser, 0x08)  # Set Continuous Mode

            elif choice == "2":
                send_uart_command(ser, 0x09)  # Set Step Mode

            elif choice == "3":
                send_instructions(ser, instructions)

            elif choice == "4":
                send_uart_command(ser, 0x0D)  # Start Program Execution

            elif choice in latch_data:
                latch_name = {"5": "IF/ID", "6": "ID/EX", "7": "EX/MEM", "8": "MEM/WB", "9": "REGISTERS"}[choice]
                print(f"Requesting {latch_name} latch...")
                command, size = latch_data[choice]
                data = request_latch(ser, command, size)
                #print(f"{latch_name} Data: {data}")
                #print(f"{latch_name} Data in bits: {' '.join(f'{byte:08b}' for byte in data)}")
                print(f"{latch_name} Data in hex: {' '.join(f'{byte:02X}' for byte in data)}")
                data_decimal = [int.from_bytes(data[i:i+4], byteorder='little') for i in range(0, len(data), 4)]
                print(f"{latch_name} Data in decimal (32-bit): {data_decimal}")
                wait_for_ready(ser)
           
            elif choice == "10":
                send_uart_command(ser, 0x0A)  # Step debugger

            elif choice == "11":
                send_uart_command(ser, 0x0B)  # Print data memory
                position = input("Enter memory position (0-1023): ")
                if position.isdigit() and 0 <= int(position) <= 1023:
                    send_uart_command(ser, int(position))
                    receive_data_from_uart(ser, 4)
                    wait_for_ready(ser)
                    send_uart_command(ser, 0x06)  # Request data memory
                    data = receive_data_from_uart(ser, 4)
                    print(f"Data Memory at position {position} in hex: {' '.join(f'{byte:02X}' for byte in data)}")
                else:
                    print("Invalid position. Please enter a number between 0 and 1023.")

            elif choice == "12":
                print(f"Reloading instructions from {args.coe_file}")
                instructions = load_instructions_from_coe(args.coe_file)

            elif choice == "13":
                print("Requesting instruction memory...")
                data = request_instruction_memory(ser)
                #print(f"Instruction Memory Data: {data}")
                #print(f"Instruction Memory Data in bits: {' '.join(f'{byte:08b}' for byte in data)}")
                print(f"Instruction Memory Data in hex: {' '.join(f'{byte:02X}' for byte in data)}")

            elif choice == "14":
                send_uart_command(ser, 0x11)  # Request PC
                pc_data = receive_data_from_uart(ser, 4)
                #print(f"PC Data: {pc_data}")
                #print(f"PC Data in bits: {' '.join(f'{byte:08b}' for byte in pc_data)}")
                #print(f"PC Data in hex: {' '.join(f'{byte:02X}' for byte in pc_data)}")
                pc_value = int.from_bytes(pc_data, byteorder='little')
                print(f"PC Value: {pc_value}")
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