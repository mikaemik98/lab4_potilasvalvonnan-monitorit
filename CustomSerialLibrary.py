import serial
import time


class CustomSerialLibrary:

    def __init__(self, port, baud_rate):
        self.port = port
        self.baud_rate = baud_rate
        self.ser = None

    def initialize_serial(self):
        try:
            self.ser = serial.Serial(self.port, self.baud_rate, timeout=1)
            time.sleep(2)  # Give time for the connection to establish
            return True
        except Exception as e:
            print(f"Failed to initialize serial connection: {e}")
            return False

    def send_command(self, command):
        try:
            if self.ser:
                print(f"Sending command: {command}")
                self.ser.write((command + "\r\n").encode())  # Send command with newline
                time.sleep(0.5)  # Wait for the simulator to process the command
                response = self.ser.readline().decode().strip()  # Read the response
                print(f"Response from Pro Sim 8 Simulator: {response}")
                return response
            else:
                print("Serial connection not initialized.")
                return None
        except Exception as e:
            print(f"Error sending command: {e}")
            return None

    def close_serial(self):
        if self.ser and self.ser.is_open:
            self.ser.close()
