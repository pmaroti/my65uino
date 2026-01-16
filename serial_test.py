import serial
import time

# Configuration
PORT = "/dev/tty.usbserial-21110"  
BAUDRATE = 4800
TX_DELAY = 0.010        # 10 ms
RX_TIMEOUT = 1.0        # seconds
MESSAGES = [
    "R",            # set address to 0x0000
    "T",            # toggle trace on
    "A0030",        # set address to 0x0030
    "?",            # display address
    "PA9", "P55",   # put opcode for LDA #55
    "P85", "P1F",   # put opcode for STA $1F
    "P60",          # put opcode for RTS
    "A0030",        # set address to 0x0030
    "D",            # display memory
    "A0030",        # set address to 0x0030
    "G" ,           # execute from 0x0030
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
