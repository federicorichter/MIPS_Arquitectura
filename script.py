import serial
import time

# Configuración del puerto serial
ser = serial.Serial('/dev/ttyUSB1', 9600, timeout=1)  # Ajusta el puerto y la velocidad según sea necesario

def send_uart_command(command):
    ser.write(command.to_bytes(1, byteorder='big'))
    print(f"Command sent: {command:02X} (hex), {command:08b} (bin)")
    input("Presiona Enter para continuar...")

def send_uart_data(data, data_size):
    for i in range(data_size // 8):
        byte = (data >> (8 * i)) & 0xFF
        send_uart_command(byte)
        time.sleep(0.01)
        print(f"Data sent: {byte:08b} (bin), {byte:02X} (hex)")

def receive_data_from_uart(num_bytes):
    data = ser.read(num_bytes)
    print("Data received:")
    for byte in data:
        print(byte, end=" ")  # Imprimir cada byte en crudo
    print("")
    
def wait_for_ready():
    while True:
        response = ser.read(1)
        print(response)
        if response == b'R':
            break

def main():
    # Reset the system
    time.sleep(0.01)

    # Set continuous mode
    send_uart_command(0x08)  # Command to set continuous mode
    #time.sleep(0.01)

    # Load a short test program
    send_uart_command(0x07)  # Command to start loading program
    send_uart_command(12)    # Cantidad de instrucciones a cargar

    # Send the instructions
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
        0x3C2B0001
    ]

    for instruction in instructions:
        send_uart_data(instruction, 32)

    send_uart_command(0x11)  # Command to set step-by-step mode
    wait_for_ready()         # Wait for 'R'

    send_uart_command(0x0D)  # Command to start program

    time.sleep(10)  # Wait for some time

    send_uart_command(0x0B)
    send_uart_command(0x02)
    receive_data_from_uart(4)
    wait_for_ready()

    send_uart_command(0x02)  # Command to request IF/ID latch
    receive_data_from_uart(4)  # Receive 4 bytes of data
    wait_for_ready()

    send_uart_command(0x03)  # Command to request ID/EX latch
    receive_data_from_uart(17)  # Receive 17 bytes of data
    wait_for_ready()

    send_uart_command(0x04)  # Command to request EX/MEM latch
    receive_data_from_uart(10)  # Receive 10 bytes of data
    wait_for_ready()

    send_uart_command(0x05)  # Command to request MEM/WB latch
    receive_data_from_uart(9)  # Receive 9 bytes of data
    wait_for_ready()

    send_uart_command(0x0A)  # Command to step

    send_uart_command(0x02)  # Command to request IF/ID latch
    receive_data_from_uart(4)  # Receive 4 bytes of data

    send_uart_command(0x03)  # Command to request ID/EX latch
    receive_data_from_uart(17)  # Receive 17 bytes of data
    wait_for_ready()

    send_uart_command(0x04)  # Command to request EX/MEM latch
    receive_data_from_uart(10)  # Receive 10 bytes of data
    wait_for_ready()

    send_uart_command(0x05)  # Command to request MEM/WB latch
    receive_data_from_uart(9)  # Receive 9 bytes of data
    wait_for_ready()

    # Close the serial port
    ser.close()

if __name__ == "__main__":
    main()