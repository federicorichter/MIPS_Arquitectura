import serial
import time
import sys

def setup_serial(port='/dev/ttyUSB1', baudrate=9542, timeout=1):
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
    send_uart_command(ser, len(instructions))  # Number of instructions
    for instruction in instructions:
        send_uart_data(ser, instruction, 32)
    wait_for_ready(ser)

def request_latch(ser, latch_command, expected_size):
    send_uart_command(ser, latch_command)
    latchdata = receive_data_from_uart(ser, expected_size)
    return latchdata

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
    print("0. Exit")
    choice = input("Enter your choice: ")
    return choice

def main():
    ser = setup_serial()
    instructions = [
        0x3C010001,  # LUI R1, 1
        0x3C030003,  # LUI R3, 3
        0x3C2B0001,  # NOP
        0x3C2B0001,  # NOP
        0xA8410001,  # SH, R1 -> MEM[1]
        0x3C2B0001,  # NOP
        0x3C2B0001,  # NOP
        0x88450001,  # LH, R5 <- MEM[1]
        0x00A31821,  # R7 = R5 + R3 => Anda
        0x3C2B0003,  # NOP
        0x3C2B0001,  # NOP
        0x3C2B0001,  # NOP
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
