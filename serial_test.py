import serial
import time

# Configuration
PORT = "/dev/tty.usbserial-21110"  
BAUDRATE = 4800
TX_DELAY = 0.010        # 10 ms
RX_TIMEOUT = 1.0        # seconds
MESSAGES = [
    "R",
    "?",
    "T",
    "A1234",
    "?"
]

# Open serial port
ser = serial.Serial(
    port=PORT,
    baudrate=BAUDRATE,
    timeout=0.1          # short read timeout
)

try:

    for MESSAGE in MESSAGES:
        # --- Transmit ---
        for ch in MESSAGE:
            ser.write(ch.encode("utf-8"))
            ser.flush()
            time.sleep(TX_DELAY)
        print(f"Transmitted: {MESSAGE}")

        # --- Receive ---
        start_time = time.time()
        received = bytearray()

        while time.time() - start_time < RX_TIMEOUT:
            data = ser.read(ser.in_waiting or 1)
            if data:
                received.extend(data)

        # Print received data
        if received:
            print("Received:")
            print(received.decode("utf-8", errors="replace"))
        else:
            print("No data received")

finally:
    ser.close()
