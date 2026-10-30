# Mini GPU

An FPGA-based graphics accelerator built using Verilog.

The goal of this project is to design a small parallel processing unit on an FPGA and use it to generate Mandelbrot fractals.

I'm building the project from scratch to understand digital hardware design, arithmetic circuits, parallel processing and FPGA development.

## Technologies

- Verilog HDL
- Icarus Verilog
- GTKWave
- Git

## Current Progress

Implemented and tested:

- 4-bit Counter
- 4-bit Adder
- 4-bit Unsigned Multiplier
- 8-bit Register
- 8-bit Accumulator

## Project Structure

```text
mini_gpu/
├── rtl/        # Verilog modules
├── tb/         # Testbenches
├── sim/        # Simulation outputs
├── reference/  # Reference files
└── README.md
```

## Running Simulations

Compile a module using Icarus Verilog:

```bash
iverilog -g2012 -o sim/output rtl/module.v tb/module_tb.v
```

Run the simulation:

```bash
vvp sim/output
```

View the waveform:

```bash
gtkwave sim/output.vcd
```

## Roadmap

- [x] Basic digital circuits
- [x] Arithmetic circuits
- [x] Registers and accumulators
- [ ] Signed arithmetic
- [ ] Fixed-point arithmetic
- [ ] Mandelbrot processing unit
- [ ] Parallel processing
- [ ] FPGA implementation

## Goal

Build a working FPGA-based parallel graphics accelerator and understand how it works at the hardware level.
