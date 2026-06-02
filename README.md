<div align="center">

# Peripheral Sniffer Analyzer

[![Platform](https://img.shields.io/badge/Platform-Vicharak%20Shrike%20Lite-blueviolet?style=for-the-badge)](https://vicharak-in.github.io/shrike/)
[![FPGA](https://img.shields.io/badge/FPGA-Renesas%20ForgeFPGA%20SLG47910-orange?style=for-the-badge)](https://www.renesas.com/us/en/products/programmable-devices/forgefpga-low-cost-fpgas)
[![MCU](https://img.shields.io/badge/MCU-RP2040%20Dual--Core-blue?style=for-the-badge)](https://datasheets.raspberrypi.com/rp2040/rp2040-datasheet.pdf)
[![License](https://img.shields.io/badge/License-MIT-yellow?style=for-the-badge)](LICENSE)

An FPGA-assisted, hardware-level UART and I²C protocol sniffer featuring high-speed metastability mitigation logic.

[Overview](#-overview) • [Architecture](#%EF%B8%8F-architecture) • [Structure](#-repository-structure) • [Build](#-build-instructions) • [Roadmap](#-roadmap)

</div>

---

## 🎯 Overview

Most protocol sniffers route external signal lines directly into an MCU's general-purpose IO registers. At high baud rates or inside electrically noisy industrial environments, this design introduces a high probability of **metastability**—where an asynchronous signal transition occurs inside a flip-flop's setup-and-hold window, causing it to settle into an unstable state that corrupts the downstream packet parsing.

This repository implements a robust architectural remedy on the **Vicharak Shrike Lite** platform. A low-cost **Renesas ForgeFPGA (SLG47910)** is inserted ahead of the processing engine to serve as a high-speed synchronization frontend. By pushing incoming bitstreams through hardware-hardened two-stage flip-flop chains, it dampens metastability before the signals ever reach the decoder.

The **Raspberry Pi RP2040 MCU** then reads a guaranteed clean, clock-domain-safe signal, utilizing its independent processing cores and Programmable IO (PIO) state machines to execute accurate frame decoding, microsecond timestamping, and host logging.

---

## 🛠️ Hardware Specification

| Component | Part / Core | Purpose |
|:---|:---|:---|
| **Development Board** | Vicharak Shrike Lite | Main development ecosystem |
| **FPGA Frontend** | Renesas SLG47910V | Asynchronous signal capture and metastability mitigation |
| **MCU Processing** | Raspberry Pi RP2040 | Protocol decoding, buffer management, and USB logging |
| **Signal Target** | ESP8266 (External) | Generates test-bench protocol traffic for validation |

---

## 🏗️ Architecture and Signal Flow

The architecture explicitly separates signal integrity constraints from analytical decoding intelligence.


  [ ESP8266 Traffic Generator ]
                │ (Asynchronous Data Stream)
                ▼
  [ Renesas SLG47910 ForgeFPGA ]
        │ 50 MHz Internal OSC
        ▼ (2-Stage FF Synchronization Frontend)
  [ Cleaned, Clock-Safe Bitstream ]
                │ (Internal PCB Bridge Traces)
                ▼
    [ Raspberry Pi RP2040 MCU ]
        ├── Core 0: PIO UART Frame Decoding
        └── Core 1: I²C Bit-Bang Parsing Engine
                │
                ▼
     [ Host USB Serial Monitor ]
Current Milestone StatusPhaseDescriptionStatusNotesPhase 1Synchronizer Core Functional✅ CompleteHardware loopback verified at 115200 baudPhase 2UART Stream Decode🔄 In ProgressImplementing byte-boundary packet assembliesPhase 3I²C Bus Capture Frontend🔄 PlannedExpanding synchronizer RTL to SDA/SCL linesPhase 4Multi-Protocol Analytics⬜ PlannedSimultaneous bus decoding and framing arrays📁 Repository StructurePlaintextshrike-peripheral-sniffer/

🚀 Build Instructions1. FPGA Synthesis and DeploymentLaunch the Renesas Go Configure Software Hub.Open the source design located in fpga/rtl/uart_bridge_sync.v.Open the IO Planner and configure your pin constraints:OSC_CLK $\rightarrow$ Map to internal 50 MHz clock resource (not standard GPIO).OSC_EN $\rightarrow$ Route to dedicated OSC_EN macro cell.uart_in $\rightarrow$ Target Pin 18 (Input).uart_out $\rightarrow$ Target Pin 17 (Output).Run Synthesize $\rightarrow$ Place & Route $\rightarrow$ Generate Bitstream.Flash the hardware target utilizing the onboard interface bridge.⚠️ Critical Toolchain Bug Warning: Any change to the Verilog source can cause Go Configure to drop IO Planner mappings without throwing an alert. Always verify your hardware pin assignments manually after re-synthesis before flashing. See docs/forgefpga_notes.md for details.2. MCU Firmware CompilationEnsure you have the ARM cross-compiler toolchain and that your PICO_SDK_PATH environment variable is defined.Bash# Clone the project source
git clone [https://github.com/YOUR_USERNAME/shrike-peripheral-sniffer.git](https://github.com/YOUR_USERNAME/shrike-peripheral-sniffer.git)
cd shrike-peripheral-sniffer/firmware

# Setup and execute the cross-compilation environment
mkdir build && cd build
cmake ..
make -j$(nproc)

# Flash Deployment:
# Hold the BOOTSEL switch on the Shrike Lite, connect the target to your 
# development PC via USB, and drop the compiled .uf2 file into the mass storage device.
🗺️ Roadmap[x] Hardware synchronization core and 50 MHz clock routing configurations[x] Stable local loopback tracking tests over bridge traces[ ] Precise PIO-driven UART byte boundary tracking and data packing loops[ ] Multi-line synchronizer RTL modifications for concurrent I²C monitoring[ ] Independent Core 1 bit-bang frame evaluation routine for SDA/SCL pins[ ] Microsecond timing indices (time_us_64()) embedded inside captured packet structures[ ] Runtime auto-baud recognition systems for uncharacterized UART streams[ ] Dedicated high-speed SPI bus decoder modules📝 License & AuthorshipThis utility framework is open-source software distributed under the terms of the MIT License.Author: Pranjal UpadhyayIndian Institute of Information Technology Design and Manufacturing, Kurnool Core Technologies: Vicharak Shrike Lite • Renesas ForgeFPGA SLG47910 • RP2040 (C / PIO Assembly)
