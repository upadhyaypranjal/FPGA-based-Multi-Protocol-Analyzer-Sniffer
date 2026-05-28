# Peripheral Analyzer Sniffer

A hardware-level protocol sniffer and analyzer built on the [Vicharak Shrike Lite](https://vicharak-in.github.io/shrike/) development board, pairing a **Renesas ForgeFPGA (SLG47910)** with a **Raspberry Pi RP2040** microcontroller.

The FPGA acts as a metastability-safe asynchronous capture and synchronization frontend. The RP2040 handles all protocol decoding, timestamping, and USB logging.

---

## Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Hardware](#hardware)
- [FPGA Synchronization Design](#fpga-synchronization-design)
- [RP2040 Firmware](#rp2040-firmware)
- [Current Progress](#current-progress)
- [UART Validation](#uart-validation)
- [I2C Integration](#i2c-integration-in-progress)
- [Repository Structure](#repository-structure)
- [Build Instructions](#build-instructions)
- [Roadmap](#roadmap)

---

## Overview

Most protocol sniffers sample external signals directly into a microcontroller GPIO. At higher baud rates or on noisy lines, this creates a real risk of metastability — the MCU's input flip-flop captures a signal mid-transition and enters an undefined logic state, corrupting the decoded data.

This project puts the FPGA between the external signal and the RP2040. The FPGA runs a two-stage synchronizer on every incoming line, removing metastability before the signal reaches the decoder. The RP2040 then operates on a clean, stable input.

```
External Signal
      │
      ▼
┌─────────────────┐
│  FPGA Frontend  │   Renesas SLG47910 ForgeFPGA
│                 │
│  ┌───────────┐  │
│  │  2FF Sync │  │   Metastability mitigation
│  └───────────┘  │   (50 MHz internal oscillator)
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  RP2040 Decoder │   Raspberry Pi RP2040
│                 │
│  • UART decode  │
│  • I2C decode   │
│  • Timestamps   │
│  • USB logging  │
└─────────────────┘
         │
         ▼
    USB Serial
```

**The FPGA does not decode protocols.** It captures, synchronizes, and forwards. All protocol intelligence lives in the RP2040 firmware.

---

## Architecture

### Signal Flow

```
External Protocol Line (UART / I2C)
         │
         │  (asynchronous, potentially noisy)
         ▼
  FPGA GPIO Input Buffer
         │
         ▼
  ┌──────────────────────────────┐
  │     2-Stage Synchronizer     │
  │                              │
  │  uart_in ──► ff1 ──► ff2    │   Clocked at 50 MHz (OSC_CLK)
  │                     │        │
  │              uart_out ◄──────┘
  └──────────────────────────────┘
         │
         │  (metastability-safe, synchronized output)
         ▼
  RP2040 GPIO Input (GPIO 15)
         │
         ▼
  PIO UART / I2C Decoder
         │
         ▼
  USB Serial Log
```

### Board-Level Bridge

The Shrike Lite board provides two dedicated runtime GPIO traces between the ForgeFPGA fabric and the RP2040:

| RP2040 GPIO | FPGA Pin | Direction | Usage |
|:-----------:|:--------:|:---------:|:------|
| GPIO 14     | Pin 18   | RP2040 → FPGA | Protocol signal input to FPGA |
| GPIO 15     | Pin 17   | FPGA → RP2040 | Synchronized output back to RP2040 |

The SPI programming interface (GPIO 0–3) and FPGA control lines (GPIO 12–14) are separate and reserved for bitstream loading.

### Metastability: Why the Synchronizer Exists

When a signal generated in one clock domain (or from an asynchronous source) is captured by a flip-flop clocked in a different domain, the flip-flop may enter a metastable state — an output voltage somewhere between logic 0 and logic 1 that resolves unpredictably. This can corrupt any downstream logic that reads it.

A two flip-flop synchronizer gives the first stage a full clock period to resolve before the second stage captures it. At 50 MHz, this provides ~20 ns of resolution time per stage. For UART at 115200 baud (bit period ≈ 8.68 µs), this is more than sufficient.

```
Async input ──► [FF1] ──► [FF2] ──► Safe output
                  │
                  └── Metastability resolves here
                      before FF2 captures
```

---

## Hardware

| Component        | Part                        | Notes |
|:-----------------|:----------------------------|:------|
| Development Board | Vicharak Shrike Lite        | RP2040 + ForgeFPGA on one PCB |
| FPGA             | Renesas SLG47910V           | 1120 LUTs, 19 GPIOs, internal 50 MHz OSC |
| MCU              | Raspberry Pi RP2040         | Dual-core Arm Cortex-M0+, PIO UART |
| Interface        | USB Type-C                  | Programming and serial logging |
| Bridge           | Onboard PCB traces          | GPIO14↔Pin18, GPIO15↔Pin17 |

**No external components are required for the synchronizer MVP.** The entire loopback path is on-board.

---

## FPGA Synchronization Design

The FPGA implements a minimal synchronizer with correct clock routing for the ForgeFPGA toolchain.

### Key Implementation Notes

- `(* clkbuf_inhibit *)` is required on the clock port to prevent the synthesis tool from renaming the clock net during buffer insertion. Without this, the IO Planner's `OSC_CLK → clk` assignment loses its target and the FFs become combinational.
- `osc_en` must be exported and tied HIGH to enable the internal 50 MHz oscillator.
- The `bridge_outputs_en` pattern used in some ForgeFPGA examples is not needed here — output direction is set statically in the IO Planner per-pin.
- UART idle state is HIGH. Since GPIO 14 / FPGA Pin 18 also doubles as the FPGA reset line (active-low), care must be taken: UART is safe because start bits (LOW) are at most ~8.68 µs, well below the ≥10 ms reset hold threshold.

### IO Planner Mapping

| IO Planner Resource | Verilog Port | Direction |
|:-------------------:|:------------:|:---------:|
| `OSC_CLK`           | `clk`        | Input (dedicated clock) |
| `OSC_EN`            | `osc_en`     | Output |
| FPGA Pin 18         | `uart_in`    | Input |
| FPGA Pin 17         | `uart_out`   | Output |

See [`fpga/rtl/uart_bridge_sync.v`](fpga/rtl/uart_bridge_sync.v) for the full implementation.

---

## RP2040 Firmware

The RP2040 firmware uses PIO UART on GPIO 14 (TX) and GPIO 15 (RX) since these are the only pins with direct PCB traces to the FPGA fabric. Hardware UART is reserved for USB debug output.

### Validation Output (Current)

```
Sending 0xAA marker bytes...
Sending incrementing counter 0x00..0x0F...
Sending ASCII string: SHRIKE_SNIFFER_MVP
```

See [`firmware/`](firmware/) for source code.

---

## Current Progress

| Task | Status |
|:-----|:------:|
| FPGA clock routing (OSC_CLK + OSC_EN) | ✅ Done |
| IO Planner mappings (Pin 17/18) | ✅ Done |
| 2-stage UART synchronizer (RTL) | ✅ Done |
| FPGA synthesis + PnR clean | ✅ Done |
| FPGA LED blink validation (clock alive) | ✅ Done |
| RP2040 UART TX generation | ✅ Done |
| End-to-end UART loopback validated | ✅ Done |
| RP2040 PIO UART RX on GPIO 15 | 🔄 In Progress |
| I2C two-wire synchronizer (SDA + SCL) | 🔄 In Progress |
| USB serial logging firmware | ⬜ Planned |
| Multi-protocol decode (UART + I2C) | ⬜ Planned |
| Timestamping + packet framing | ⬜ Planned |

---

## UART Validation

The MVP validates the complete synchronizer path using only the onboard hardware:

```
RP2040 GPIO 14 (PIO TX)
       │
       └──[PCB trace]──► FPGA Pin 18 (uart_in)
                               │
                         ┌─────▼──────────────┐
                         │  50 MHz OSC_CLK     │
                         │  ff1 ← uart_in      │
                         │  ff2 ← ff1          │
                         │  uart_out ← ff2     │
                         └─────────────────────┘
                               │
                         FPGA Pin 17 (uart_out)
                               │
                       ──[PCB trace]──► RP2040 GPIO 15 (PIO RX)
```

At 115200 baud, the 3-cycle synchronizer latency at 50 MHz is ~60 ns — invisible to the RP2040 UART decoder.

---

## I2C Integration (In Progress)

I2C requires synchronizing two signals simultaneously: SDA (data) and SCL (clock). The FPGA will run independent two-stage synchronizers on each line.

Planned bridge allocation:

| Signal | FPGA Pin | RP2040 GPIO | Notes |
|:------:|:--------:|:-----------:|:------|
| SDA    | Pin 18   | GPIO 14     | Existing UART trace, repurposed |
| SCL    | PMOD     | GPIO (TBD)  | Via PMOD connector |

Since the Shrike Lite only has two dedicated internal bridge traces, the I2C second wire will route through the PMOD connector to an available RP2040 GPIO.

---

## Repository Structure

```
shrike-peripheral-sniffer/
│
├── firmware/                    # RP2040 C firmware (Pico SDK)
│   ├── core/                    # Main loop, init, multicore dispatch
│   ├── uart/                    # PIO UART TX/RX, loopback test
│   ├── i2c/                     # I2C decode (planned)
│   └── utils/                   # Logging, timestamping helpers
│
├── fpga/                        # ForgeFPGA Verilog + toolchain files
│   ├── rtl/                     # Verilog source (uart_bridge_sync.v, etc.)
│   ├── constraints/             # Timing constraints (if applicable)
│   └── io_planner/              # IO Planner screenshots / exported configs
│
├── docs/                        # Engineering notes and design decisions
│   ├── architecture/            # Block diagrams, signal flow docs
│   ├── progress/                # Per-milestone build notes
│   └── notes/                   # Debugging logs, tool quirks, gotchas
│
├── images/                      # Photographs and screenshots
│   ├── hardware/                # Board photos
│   ├── waveforms/               # Simulation / logic analyzer captures
│   ├── fpga/                    # IO Planner, floorplan, PnR screenshots
│   └── diagrams/                # Architecture diagrams (exported)
│
├── tests/                       # Test scripts and validation programs
│   ├── uart/                    # UART loopback test firmware
│   ├── i2c/                     # I2C test vectors (planned)
│   └── loopback/                # End-to-end path validation
│
├── hardware/                    # Board reference material
│   ├── shrike_pinouts.md        # Copied/referenced from Vicharak docs
│   └── bridge_notes.md          # Internal MCU↔FPGA bridge documentation
│
├── .gitignore
├── LICENSE
├── CONTRIBUTING.md
└── README.md
```

---

## Build Instructions

### Prerequisites

- [Pico SDK](https://github.com/raspberrypi/pico-sdk) (v1.5.0 or later)
- [Go Configure Software Hub](https://www.renesas.com/us/en/software-tool/go-configure-software-hub) (Renesas ForgeFPGA toolchain)
- `cmake`, `arm-none-eabi-gcc`
- Python 3 (for test scripts)

### FPGA Bitstream

1. Open Go Configure Software Hub.
2. Load the project from `fpga/rtl/uart_bridge_sync.v`.
3. Verify IO Planner assignments match the table in [FPGA Synchronization Design](#fpga-synchronization-design).
4. Run Synthesize → Generate Bitstream. Check the Issues tab for any clock warnings before trusting the output.
5. Flash via the RP2040 SPI programming interface using the `shrike_fpga.py` library or the Arduino `ShrikeFPGA` library.

### RP2040 Firmware

```bash
cd firmware
mkdir build && cd build
cmake .. -DPICO_SDK_PATH=/path/to/pico-sdk
make -j4
# Flash the resulting .uf2 via USB bootloader (hold BOOTSEL on reset)
```

---

## Roadmap

**Phase 1 — Synchronizer MVP** *(complete)*
- FPGA clock routing, 2FF UART synchronizer, LED validation, end-to-end loopback

**Phase 2 — UART Decode**
- PIO UART RX on RP2040, byte capture, USB serial logging, baud rate configuration

**Phase 3 — I2C Frontend**
- Dual-line synchronizer (SDA + SCL), PMOD routing, RP2040 I2C decode

**Phase 4 — Protocol Framing**
- Timestamped packet capture, FIFO buffering, structured USB output format

**Phase 5 — Multi-Protocol**
- Runtime protocol selection, SPI sniffer frontend, configurable capture triggers

---

## References

- [Vicharak Shrike Lite Documentation](https://vicharak-in.github.io/shrike/)
- [Renesas SLG47910 Datasheet](https://www.renesas.com/en/document/dst/slg47910-datasheet)
- [ForgeFPGA Workshop User Guide](https://www.renesas.com/en/document/gde/forgefpga-workshop-user-guide)
- [RP2040 Datasheet](https://datasheets.raspberrypi.com/rp2040/rp2040-datasheet.pdf)
- [Shrike Lite Pin Reference — DeepWiki](https://deepwiki.com/vicharak-in/shrike-lite/10.1-complete-pin-reference)

---

## License

MIT — see [LICENSE](LICENSE).
