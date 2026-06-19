# Peripheral Analyzer Sniffer

**Difficulty:** Intermediate
**Uses MCU:** Yes
**External Hardware:** ESP8266 (used only as a test traffic generator — not required for normal operation)

## Overview

This example turns your Shrike board into a hardware logic analyzer for UART, I²C, and SPI. The ForgeFPGA does all the real-time protocol decoding directly in hardware — detecting start bits, START/STOP conditions, and SPI chip-select edges — while the RP2040 forwards the decoded packets to your PC over USB serial. A companion PyQt6 desktop app displays everything live, so you can watch real digital communication happen byte-by-byte instead of just reading about it.

If you've ever wondered what's actually moving across a UART line or an I²C bus, this is a hands-on way to see it.

## Compatibility

| Board | Firmware | Status |
|-------|----------|--------|
| Shrike-Lite (RP2040) | firmware/micropython/ | :white_check_mark: Tested |
| Shrike (RP2350) | firmware/micropython/ | :white_large_square: Untested |
| Shrike-fi (ESP32-S3) | firmware/arduino-ide/ | :white_large_square: Untested |

The FPGA bitstream is the same across all boards. Only the MCU-side firmware path differs.

## Hardware Setup

No external hardware is required to use the analyzer itself — it passively monitors signals already present on your bus.

If you want to generate test traffic to try the analyzer out (recommended for first-time setup), wire up an ESP8266 as follows:

| ESP8266 Pin | Shrike Pin | Signal |
|-------------|------------|--------|
| TX | UART_RX (FPGA input) | UART data |
| SDA | I2C_SDA (FPGA input) | I²C data |
| SCL | I2C_SCL (FPGA input) | I²C clock |
| MOSI / SCK / CS | SPI_MOSI / SPI_SCK / SPI_CS (FPGA input) | SPI signals |
| GND | GND | Common ground |

> **Note:** The analyzer's monitoring inputs are passive (high-impedance reads). Always share a common ground between the Shrike board and whatever bus you're sniffing.

## Quick Start (Pre-Built Bitstream)

1. Connect your Shrike board to your PC via USB.
2. Upload `bitstream/peripheral_analyzer_sniffer.bin` to the FPGA using ShrikeFlash (via Thonny/MicroPython — see `firmware/micropython/`).
3. Install the host app dependencies and launch the GUI (see [Host Application](#host-application-pyqt6-gui) below).
4. Generate some UART, I²C, or SPI traffic on the monitored lines.
5. **Expected result:** decoded packets appear in the GUI in real time, color-coded by protocol, with timestamps and byte-level detail.

## Build From Source

### FPGA (Verilog)

1. Open `peripheral_analyzer_sniffer.ffpga` in Go Configure Software Hub (GCSH).
2. Verify I/O pin assignments in the IO Planner against your board variant.
3. Click **Synthesize** → review resource/LUT utilization.
4. Run **Place & Route (PnR)**.
5. Click **Generate Bitstream**.
6. Output will be in `ffpga/build/` — copy the resulting `.bin` into `bitstream/` if you want to refresh the pre-built copy.

### Firmware (MicroPython — primary path)

1. Open Thonny IDE and connect to your Shrike board.
2. Copy `bitstream/peripheral_analyzer_sniffer.bin` to the board's filesystem.
3. Upload `firmware/micropython/peripheral_analyzer_sniffer.py`.
4. Run it — it programs the FPGA and starts forwarding decoded packets over USB serial.

### Firmware (Arduino IDE — alternate path)

1. Open `firmware/arduino-ide/peripheral_analyzer_sniffer.ino` in Arduino IDE 2.x.
2. Select your board (Raspberry Pi Pico/RP2040, or ESP32-S3 for Shrike-fi).
3. Make sure the Shrike Arduino library is installed.
4. Upload.

### Host Application (PyQt6 GUI)

The desktop app lives in `host-app/` (outside the standard `examples/` template, added specifically for this project — see PR description).

1. `cd examples/peripheral_analyzer_sniffer/host-app`
2. `pip install -r requirements.txt`
3. `python main.py`
4. Select the Shrike board's serial port from the dropdown and click **Connect**.

**GUI features:**
- Real-time UART / I²C / SPI packet visualization
- Color-coded packet history log
- Session statistics (packet counts, error/NACK counts, throughput)
- Export captured sessions to CSV/JSON
- Per-protocol filtering, so you can isolate just UART or just I²C/SPI traffic

## How It Works

The FPGA is the heart of this example — it does all protocol decoding in hardware, deterministically, rather than relying on software polling that could miss fast transitions.

- **Synchronization:** Incoming UART, I²C, and SPI lines are asynchronous to the FPGA's internal clock, so each is first passed through a synchronizer to avoid metastability before any logic touches it.
- **UART decoding:** A start-bit detector watches the RX line for the falling edge that begins a frame, then samples at the configured baud rate to reconstruct each byte.
- **I²C decoding:** Dedicated logic watches SDA relative to SCL to catch START and STOP conditions, then decodes address and data bytes along with their ACK/NACK bit.
- **SPI decoding:** The SPI sniffer logic tracks the chip-select line to frame each transaction, then shifts in MOSI/MISO bits on the appropriate clock edge to reconstruct each transferred byte.
- **Packetization & buffering:** Decoded bytes from all three protocols are wrapped into small event packets and pushed into a FIFO, so bursts of traffic don't get dropped while the RP2040 catches up.
- **SPI bridge to RP2040:** The RP2040 polls the FPGA over SPI, pulls packets out of the FIFO, and forwards them over USB serial.
- **Host display:** The RP2040 firmware is a thin bridge — all the real decoding already happened in the FPGA. The PyQt6 app on your PC just parses incoming serial packets and renders them.

This split matters: software-only sniffers can miss events while busy doing other work, but the FPGA samples every clock edge regardless of what the RP2040 or PC is doing.

## Expected Output

When everything is wired and running correctly, you should see something like this in the GUI:

```
[12:04:01.221] UART  | TX: "Hello Shrike!"
[12:04:01.512] I2C   | ADDR: 0x42 (WRITE) | ACK
[12:04:01.513] I2C   | DATA: 0x7F | ACK
[12:04:01.514] I2C   | STOP
[12:04:01.890] SPI   | CS: LOW | MOSI: 0xA5 | MISO: 0x3C
```

Each line is color-coded by protocol in the GUI, with running counters for total packets, bytes, and any NACK/error events shown in the statistics panel.

## Future Improvements

- Automatic UART baud-rate detection
- Simultaneous multi-protocol triggering and cross-protocol timestamp correlation
- Configurable capture triggers/filters at the FPGA level (not just in the GUI)
- Persistent session logging to disk directly from firmware
- Support for SPI mode (CPOL/CPHA) auto-detection
