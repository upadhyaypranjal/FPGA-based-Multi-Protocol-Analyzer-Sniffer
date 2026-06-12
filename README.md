<div align="center">

# Peripheral Sniffer Analyzer

</div>

---

## Overview

Peripheral Sniffer Analyzer is a hardware-assisted protocol monitoring and analysis system designed for reliable capture, decoding, and visualization of digital communication protocols.

The system is built on the Vicharak Shrike Lite platform and combines a Renesas SLG47910 ForgeFPGA with a Raspberry Pi RP2040 microcontroller. The FPGA serves as the primary protocol analysis engine, directly capturing UART and I²C bus activity, synchronizing asynchronous signals, decoding protocol frames, packetizing events, and buffering decoded data.

Decoded packets are transferred to the RP2040 through an SPI interface. The RP2040 acts as a lightweight communication bridge, forwarding the decoded information to a host PC through USB serial for real-time monitoring and display.

This architecture separates protocol analysis from host communication, allowing the FPGA to perform deterministic hardware-based protocol decoding while the RP2040 handles data forwarding and visualization.

### Currently Supported Protocols

- **UART (Universal Asynchronous Receiver/Transmitter)**
  - Start-bit detection
  - Frame decoding
  - Byte reconstruction
  - Message reconstruction
  - Real-time monitoring

- **I²C (Inter-Integrated Circuit)**
  - START condition detection
  - STOP condition detection
  - Address decoding
  - Data-byte decoding
  - ACK/NACK detection
  - Real-time bus monitoring

### FPGA Functions

- Asynchronous signal synchronization
- UART protocol decoding
- I²C protocol decoding
- Event packet generation
- FIFO buffering
- SPI packet transmission

### RP2040 Functions

- SPI packet reception
- Packet parsing
- USB serial communication
- Host display interface

### Future Protocol Support

- SPI (Serial Peripheral Interface)
- Automatic UART baud-rate detection
- Simultaneous multi-protocol monitoring
- Timestamp generation
- Advanced packet logging and filtering

---

## Hardware

| Component | Purpose |
|------------|----------|
| Vicharak Shrike Lite | Development Platform |
| Renesas SLG47910 ForgeFPGA | Protocol Capture, Decoding and Packetization |
| Raspberry Pi RP2040 | SPI-to-USB Communication Bridge |
| ESP8266 | Test Signal Generator |
| Host PC | Real-Time Monitoring and Visualization |
---

## Software Used

| Software | Purpose |
|----------------|----------|
| Renesas Go Configure Software Hub | FPGA configuration and bitstream generation |
| Thonny IDE | RP2040 MicroPython firmware execution and protocol monitoring |
| Arduino IDE | ESP8266 firmware development and generation of UART/I²C test traffic |
| PuTTY |  User input terminal for generating test traffic through the ESP826 |

---

## Architecture

<p align="center">
  <img src="Architecture/system_architecture.png" alt="System Architecture" width="800">
</p>

---

## Build Instructions

### FPGA Bitstream Generation

1. Launch the **Renesas Go Configure Software Hub**.
2. Open the FPGA project located in the `fpga/rtl/` directory.
3. Verify the I/O pin assignments using the IO Planner.
4. Run synthesis and review resource utilization.
5. Execute Place & Route (PnR).
6. Generate the FPGA bitstream (`.bin`).
7. Save the generated bitstream for deployment.

### RP2040 Firmware Deployment

1. Open the MicroPython environment (Thonny IDE).
2. Connect the Vicharak Shrike Lite board to the host PC.
3. Ensure the required Python scripts are available in the `firmware/` directory.
4. Copy the generated FPGA bitstream (`FPGA_bitstream_MCU.bin`) to the RP2040 filesystem.
5. Upload the protocol analyzer Python firmware to the board.
6. Run the firmware to automatically configure and program the ForgeFPGA through the RP2040.
7. Verify that the FPGA programming process completes successfully.

### Validation

After FPGA configuration and firmware deployment:

1. Connect the host computer to the Shrike Lite board through USB.
2. Open a serial terminal (Arduino IDE Serial Monitor, PuTTY, or Tera Term).
3. Configure the terminal for the selected baud rate.
4. Connect the ESP8266 test generator to the UART and I²C monitoring interfaces.
5. Generate UART traffic, I²C traffic, or both simultaneously.
6. Verify that the FPGA correctly detects, decodes, and packetizes protocol activity.
7. Confirm that decoded UART messages and I²C transactions are displayed on the host terminal in real time.
8. Validate correct detection of:
   - UART messages
   - I²C START and STOP conditions
   - I²C Address frames
   - I²C Data bytes
   - ACK/NACK responses
---

### Folder Structure

Peripheral_Analyzer_Sniffer/
│
├── Architecture/
│   ├── system_architecture.png
│   │   (Overall system architecture diagram)
│   │
│   ├── signal_flow.png
│   │   (ForgeFPGA synchronization and signal-conditioning architecture)
│   │
│   ├── io_mapping_table.png
│   │   (FPGA I/O Planner pin mapping and port assignment table)
│
├── FPGA/
│   ├── top.v
│   │   (Top-level integration module)
│   │
│   ├── uart_rx_core.v
│   │   (UART receiver and frame detection logic)
│   │
│   ├── i2c_decoder.v
│   │   (I²C protocol decoder and packet extraction)
│   │
│   ├── uart_fifo.v
│   │   (Event buffer / FIFO storage)
│   │
│   ├── spi_target.v
│   │   (SPI slave interface for host communication)
│   │
│   └── io_planner.png
│       (FPGA I/O Planner configuration screenshot)
│
├── Firmware/
│   └── protocol_analyzer.ino
│       (ESP8266 traffic generator for UART and I²C validation)
│
├── Outputs/
│   ├── uart_capture.png
│   │   (UART protocol decoding results)
│   │
│   ├── i2c_capture.png
│   │   (I²C protocol decoding results)
│   │
│   └── terminal_output.png
│       (Real-time protocol analyzer output)
│
└── README.md
    (Project documentation, setup instructions, architecture and results)

--- 

<div align="center">

### Pranjal Upadhyay

Indian Institute of Information Technology Design and Manufacturing, Kurnool

</div>
