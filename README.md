# FPGA Mini GPU — Parallel Mandelbrot Accelerator

A Verilog hardware-design project exploring how a graphics-style workload can be mapped onto digital logic and progressively accelerated with multiple processing elements (PEs).

The workload is **Mandelbrot fractal rendering**. The repository contains arithmetic building blocks, fixed-point datapaths, Mandelbrot processing elements, pixel generators, renderers, 2-PE scheduling and result-collection logic, and parameterized N-PE components. Simulation testbenches and Python scripts are used to verify behaviour and inspect rendered output.

> **Project status:** The repository has progressed beyond the original single-PE design. It contains a working 2-PE renderer architecture and separate parameterized N-PE building blocks (including an N-PE scheduler, PE array, result collector and FIFO). These components should not be confused with a fully integrated N-PE frame renderer. The project currently includes simulation artifacts; FPGA synthesis, place-and-route and a physical FPGA demonstration are not documented as completed.

---

## Contents

- [Project overview](#project-overview)
- [Architecture](#architecture)
- [Implemented RTL](#implemented-rtl)
- [Numerical representation](#numerical-representation)
- [Repository structure](#repository-structure)
- [Requirements](#requirements)
- [Running simulations](#running-simulations)
- [Python analysis](#python-analysis)
- [Verification coverage](#verification-coverage)
- [Current status and limitations](#current-status-and-limitations)
- [Roadmap](#roadmap)

## Project overview

The project uses the Mandelbrot recurrence as a compute workload:

\[
x_{n+1}=x_n^2-y_n^2+a
\]

\[
y_{n+1}=2x_ny_n+b
\]

with \(x_0=y_0=0\). Iteration ends when the magnitude exceeds the escape radius, \(x_n^2+y_n^2>4\), or the configured iteration limit is reached.

The hardware calculates an iteration count and escape status for each pixel. Pixel coordinates are mapped to complex-plane coordinates, processed by one or more PEs, and returned with their pixel positions so that results can be reconstructed into an image.

### Goals

- Design arithmetic and sequential building blocks in Verilog.
- Implement signed and fixed-point arithmetic.
- Build a Mandelbrot iteration datapath and control unit.
- Generate pixel coordinates and render complete frames in simulation.
- Explore parallel execution using multiple processing elements.
- Handle result buffering and downstream backpressure.
- Compare hardware-oriented fixed-point results with software reference calculations.
- Measure throughput and, in a future stage, FPGA resource and timing costs.

## Architecture

### Single-PE rendering path

The original rendering path uses one PE and processes pixels sequentially:

```text
Pixel Coordinate Generator
          |
          v
   Mandelbrot Renderer
          |
          v
  Mandelbrot Processing Element
          |
          v
 Pixel result (x, y, iterations, escaped)
```

The image-generation testbench writes pixel results to CSV. Python scripts can then visualize the frame and compare the output with software calculations.

### 2-PE rendering path

The repository also contains a 2-PE renderer. Its architecture includes a parallel pixel-coordinate generator, a scheduler, two processing elements, result holding/collection logic and a FIFO-backed output interface.

```text
Parallel Pixel Coordinate Generator
                 |
                 v
          2-PE Scheduler
             /      \
            v        v
          PE 0      PE 1
            \        /
             v      v
        Result Holds / Collector
                 |
                 v
             Result FIFO
                 |
                 v
       Renderer Output Interface
```

The renderer exposes pixel coordinates with each result. This matters because PEs can finish work at different times; completion order is not necessarily the same as pixel submission order.

### Parameterized N-PE building blocks

The repository contains reusable N-PE modules:

- `mandelbrot_pe_array` instantiates a configurable number of PEs.
- `mandelbrot_scheduler_npe` distributes incoming pixels across available PEs using a round-robin search.
- The N-PE scheduler tracks busy and pending work and provides per-PE result-valid/result-ready signalling.
- `pe_result_collector_npe` captures per-PE results and forwards them into an output FIFO.
- `result_fifo_npe` accepts writes from multiple PE lanes subject to available FIFO capacity.

These are building blocks for scaling beyond two PEs. **There is not currently an integrated N-PE full-frame renderer in this repository.**

## Implemented RTL

| Area | Modules / files | Purpose |
|---|---|---|
| Basic arithmetic | `adder.v`, `multiplier.v`, `signed_adder.v`, `signed_multiplier.v` | Basic and signed arithmetic units |
| Fixed-point arithmetic | `fixed_adder.v`, `fixed_adder_16.v`, `fixed_multiplier.v`, `fixed_multiplier_16.v` | Fixed-point arithmetic experiments |
| Sequential building blocks | `register.v`, `counter.v`, `accumulator.v`, `iteration_counter.v` | Registers, counting and accumulation |
| Mandelbrot datapath | `mandelbrot_step.v`, `mandelbrot_step_q16.v` | Mandelbrot iteration arithmetic variants |
| Escape detection | `mandelbrot_escape.v`, `mandelbrot_escape_wide.v`, `mandelbrot_escape_detector_q16.v` | Escape-condition logic variants |
| State and PE | `mandelbrot_registers.v`, `mandelbrot_registers_q16.v`, `mandelbrot_fsm.v`, `mandelbrot_pe.v` | Coordinate state, control and processing element |
| PE composition | `mandelbrot_pe_pair.v`, `mandelbrot_pe_array.v` | Two-PE wrapper and parameterized PE array |
| 2-PE scheduling | `mandelbrot_scheduler_2pe.v` | Assigns pixels to available PEs |
| N-PE scheduling | `mandelbrot_scheduler_npe.v` | Parameterized round-robin work assignment |
| Result handling | `pe_result_hold.v`, `pe_result_collector_2pe.v`, `pe_result_collector_npe.v` | Holds and collects completed PE results |
| Result buffering | `result_fifo_2pe.v`, `result_fifo_npe.v` | FIFO buffering for collected results |
| Display / coordinates | `pixel_coordinate_generator.v`, `pixel_coordinate_generator_parallel.v`, `mandelbrot_renderer.v`, `mandelbrot_renderer_2pe.v` | Pixel generation and single-/2-PE rendering paths |

## Numerical representation

The repository contains multiple arithmetic variants, so numerical widths should be checked in the relevant RTL module before changing or comparing configurations.

The original image-generation path uses:

- Image resolution: **320 × 240**.
- Pixel count: **76,800**.
- Maximum iteration count in the image testbench: **64**.
- Pixel-to-complex-plane coordinate representation: signed 16-bit values using a Q4.12-style scale.
- Escape condition: squared magnitude greater than 4.

There are also wider and Q16-named datapath variants in the repository. They are separate implementation experiments; do not assume every renderer or testbench uses the same widths or scaling.

## Repository structure

```text
fpga-mini-gpu/
├── rtl/
│   ├── display/
│   │   ├── mandelbrot_renderer.v
│   │   ├── mandelbrot_renderer_2pe.v
│   │   ├── pixel_coordinate_generator.v
│   │   └── pixel_coordinate_generator_parallel.v
│   └── ...                 # Arithmetic, PE, scheduler and FIFO RTL
├── tb/
│   ├── display/            # Renderer and coordinate-generator testbenches
│   └── ...                 # Arithmetic, PE, scheduler and FIFO testbenches
├── scripts/
│   ├── compare_mandelbrot.py
│   ├── plot_mandelbrot.py
│   ├── plot_mandelbrot_2pe.py
│   ├── precision_analysis.py
│   └── precision_sweep.py
├── sim/                    # Generated CSVs, plots and simulation artifacts
├── .gitignore
└── README.md
```

## Requirements

### RTL simulation

- Icarus Verilog (`iverilog` and `vvp`)
- GTKWave (optional, for waveform inspection)

### Python analysis

- Python 3
- NumPy
- Matplotlib

On Arch Linux:

```bash
sudo pacman -S iverilog gtkwave python-numpy python-matplotlib
```

On Ubuntu:

```bash
sudo apt update
sudo apt install iverilog gtkwave python3 python3-numpy python3-matplotlib
```

## Running simulations

Run commands from the repository root.

### Run the single-PE full-frame image test

The following command compiles the image-generation testbench and its RTL dependencies:

```bash
mkdir -p sim

iverilog -g2012 -o sim/mandelbrot_image_tb_sim \
  rtl/iteration_counter.v \
  rtl/mandelbrot_escape_wide.v \
  rtl/mandelbrot_registers.v \
  rtl/mandelbrot_step.v \
  rtl/mandelbrot_fsm.v \
  rtl/mandelbrot_pe.v \
  rtl/display/pixel_coordinate_generator.v \
  rtl/display/mandelbrot_renderer.v \
  tb/display/mandelbrot_image_tb.v

vvp sim/mandelbrot_image_tb_sim
```

The testbench writes `sim/mandelbrot_pixels.csv`. A complete 320 × 240 frame contains 76,800 pixel records, in addition to any CSV header.

### Plot the single-PE image

```bash
python3 scripts/plot_mandelbrot.py
```

### Compare the single-PE output with the fixed-point reference

```bash
python3 scripts/compare_mandelbrot.py
```

This comparison checks RTL output against a software model intended to mirror the implemented fixed-point behaviour. It is a consistency check, not proof that finite-width arithmetic exactly matches ideal real-number arithmetic.

### Plot the 2-PE image

If the 2-PE simulation has generated `sim/mandelbrot_2pe.csv`, visualize it with:

```bash
python3 scripts/plot_mandelbrot_2pe.py
```

The script expects the corresponding CSV output to exist. Run the relevant 2-PE testbench first if the file is absent or you want to regenerate it.

### Run precision analysis

```bash
python3 scripts/precision_analysis.py
python3 scripts/precision_sweep.py
```

These scripts examine numerical differences across fixed-point configurations. Use their generated results as analysis outputs for the data currently present in `sim/`; regenerate the relevant simulation data when the RTL or numerical configuration changes.

## Running an individual testbench

The repository has separate testbenches for arithmetic units, fixed-point operations, Mandelbrot datapath variants, escape detection, the FSM, PEs, schedulers, result collectors, FIFOs, coordinate generators and renderers.

For an individual testbench, compile it with all RTL dependencies it instantiates:

```bash
iverilog -g2012 -o sim/test_sim \
  rtl/module_a.v \
  rtl/module_b.v \
  tb/module_tb.v

vvp sim/test_sim
```

Replace the example filenames with the actual testbench and its dependencies. The exact compile list varies by testbench.

### Waveforms

If the testbench contains `$dumpfile` and `$dumpvars`, run the simulation and open the generated VCD file:

```bash
gtkwave sim/waveform.vcd
```

If no waveform is generated, enable or add the dump statements in the relevant testbench before compiling it.

## Verification coverage

Testbench files are provided for:

- Basic adders, multipliers, registers, counters and accumulators.
- Fixed-point adders and multipliers.
- Mandelbrot iteration and escape-detection variants.
- Mandelbrot registers, FSM and processing elements.
- PE pairs and parameterized PE arrays.
- 2-PE and N-PE schedulers.
- 2-PE and N-PE result collectors and FIFOs.
- Sequential and parallel pixel-coordinate generation.
- Single-PE and 2-PE renderer paths.
- Renderer equivalence and full-frame scenarios.

The presence of a testbench means a test has been written; it does not by itself establish that every test passes in the current checkout. Run the relevant testbenches to confirm the current state after modifications.

## Current status and limitations

- The original single-PE renderer and full-frame simulation flow are present.
- A 2-PE renderer implementation and associated testbenches are present.
- Parameterized N-PE scheduling, PE-array, result-collection and FIFO modules are present.
- The N-PE components are not yet integrated into a complete N-PE frame renderer.
- Simulation outputs and Python analysis scripts are included.
- No board-specific FPGA top-level, pin constraints or completed hardware demonstration are represented in the current repository.
- Synthesis and place-and-route resource/timing results are not currently documented.
- Fixed-point variants need careful comparison because their widths and scaling differ.

## Roadmap

- [x] Implement basic combinational and sequential building blocks.
- [x] Implement signed and fixed-point arithmetic experiments.
- [x] Implement the Mandelbrot datapath, escape detection, FSM and PE.
- [x] Generate pixel coordinates and render a full frame in simulation.
- [x] Add Python visualization and numerical-analysis scripts.
- [x] Implement a 2-PE renderer architecture.
- [x] Add parameterized N-PE PE-array, scheduler, result collector and FIFO modules.
- [ ] Run and consolidate the complete regression suite.
- [ ] Strengthen N-PE tests for backpressure, simultaneous completions, reset and result stability.
- [ ] Integrate the N-PE components into a complete frame renderer.
- [ ] Benchmark 1-, 2-, 4- and 8-PE configurations using comparable workloads.
- [ ] Quantify throughput, latency and scaling efficiency.
- [ ] Select a target FPGA board and create a synthesizable top-level module.
- [ ] Add board-specific pin and timing constraints.
- [ ] Synthesize and evaluate LUT, flip-flop, DSP and timing utilization.
- [ ] Implement and test the design on physical FPGA hardware.
- [ ] Consider a VGA or other display output.

## Project objective

Build a small graphics-oriented accelerator from the ground up and use Mandelbrot rendering to explore datapath design, fixed-point numerical behaviour, parallel processing, buffering, verification and FPGA implementation.

The focus is not only on producing a fractal image, but on understanding the hardware architecture and measuring what changes when computation is distributed across multiple processing elements.
