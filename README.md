<div align="center">

# Peripheral Sniffer Analyzer

### FPGA-Assisted UART & I²C Protocol Sniffer

### Pranjal Upadhyay

**Indian Institute of Information Technology Design and Manufacturing, Kurnool**

---

*Built using Vicharak Shrike Lite, Renesas SLG47910 ForgeFPGA, and RP2040*

</div>

---

## Overview

Peripheral Sniffer Analyzer is a hardware-assisted protocol monitoring system built on the Vicharak Shrike Lite platform.

The project uses a Renesas SLG47910 ForgeFPGA as a synchronization frontend and an RP2040 microcontroller for protocol decoding, packet processing, and USB serial logging.

Currently supported protocols:

- UART
- I²C (Work in Progress)

---

## Hardware

| Component | Purpose |
|------------|----------|
| Vicharak Shrike Lite | Development Platform |
| Renesas SLG47910 | FPGA Synchronization Frontend |
| RP2040 | Protocol Decoder |
| ESP8266 | Test Signal Generator |

---

## Architecture

```text
ESP8266
   │
   ▼
SLG47910 FPGA
   │
   ▼
RP2040
   │
   ▼
USB Serial Monitor
```

---

## Current Status

| Phase | Status |
|---------|---------|
| FPGA Synchronizer | ✅ Complete |
| UART Decode | 🔄 In Progress |
| I²C Support | 🔄 Planned |
| Multi-Protocol Support | ⬜ Planned |

---

## Repository Structure

```text
shrike-peripheral-sniffer/

├── firmware/      RP2040 Firmware
├── fpga/          FPGA RTL Designs
├── docs/          Documentation
├── tests/         Validation Scripts
├── images/        Project Images
├── hardware/      Hardware References
└── README.md
```

---

## Build Instructions

### FPGA

1. Open ForgeFPGA tools.
2. Load the FPGA source design.
3. Configure pin assignments.
4. Generate the bitstream.
5. Flash the FPGA.

### Firmware

```bash
git clone https://github.com/YOUR_USERNAME/shrike-peripheral-sniffer.git
cd shrike-peripheral-sniffer/firmware

mkdir build
cd build

cmake ..
make
```

---

## Roadmap

- UART byte reconstruction
- I²C frame decoding
- Timestamped packet capture
- Multi-protocol support
- SPI protocol monitoring
- Automatic baud-rate detection

---

## License

MIT License

---

<div align="center">

### Author

# Pranjal Upadhyay

Indian Institute of Information Technology Design and Manufacturing, Kurnool

</div>
