<div align="center">

# Peripheral Sniffer Analyzer

</div>

---

## Overview

Peripheral Sniffer Analyzer is a hardware-assisted protocol monitoring system. 

The project uses a Renesas SLG47910 ForgeFPGA as a synchronization frontend and an RP2040 microcontroller for protocol decoding, packet processing, and USB serial logging.

Currently supported protocols:

- UART
- I²C

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

<p align="center">
  <img src="images/architecture/system_architecture.png" alt="System Architecture" width="500">
</p>

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


## License

MIT License

---

<div align="center">

### Author

# Pranjal Upadhyay

Indian Institute of Information Technology Design and Manufacturing, Kurnool

</div>
