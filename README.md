# Mini GPU — Verilog Mandelbrot Accelerator

A from-scratch digital hardware project exploring how a graphics workload can be implemented with Verilog and eventually accelerated on an FPGA.

The current design generates a **320 × 240 Mandelbrot image** in simulation. A pixel-coordinate generator supplies one complex coordinate at a time to a Mandelbrot processing element (PE). The PE iterates the Mandelbrot recurrence, detects escape, and reports the iteration count. A renderer sequences the pixels and a testbench writes the results to CSV for inspection with Python.

> **Current architecture:** one processing element, processing pixels sequentially. The project is a foundation for a parallel, multi-PE accelerator; it is not yet a parallel GPU or an FPGA-deployed design.

## Project goals

- Learn digital logic and arithmetic by implementing the building blocks in Verilog.
- Implement signed fixed-point arithmetic and a Mandelbrot iteration datapath.
- Build control logic and a pixel renderer around the processing element.
- Validate the RTL against software reference models.
- Investigate numerical precision and hardware cost.
- Extend the design to multiple processing elements and evaluate throughput.
- Eventually synthesize and run the design on an FPGA, with a display output if the target board supports it.

## Current implementation

### Hardware blocks

| Block | File | Purpose |
|---|---|---|
| Basic arithmetic | `rtl/adder.v`, `rtl/multiplier.v` | Unsigned arithmetic building blocks |
| Signed arithmetic | `rtl/signed_adder.v`, `rtl/signed_multiplier.v` | Signed arithmetic building blocks |
| Registers and state | `rtl/register.v`, `rtl/counter.v`, `rtl/accumulator.v` | Sequential logic fundamentals |
| Fixed-point arithmetic | `rtl/fixed_adder*.v`, `rtl/fixed_multiplier*.v` | Fixed-point add and multiply experiments |
| Iteration counter | `rtl/iteration_counter.v` | Tracks Mandelbrot iterations |
| Mandelbrot datapath | `rtl/mandelbrot_step.v` | Computes the next real and imaginary coordinates |
| Escape detector | `rtl/mandelbrot_escape*.v` | Checks whether the magnitude has exceeded the escape radius |
| Coordinate registers | `rtl/mandelbrot_registers.v` | Stores the current iteration coordinates |
| Controller | `rtl/mandelbrot_fsm.v` | Controls initialization, iteration, update and completion |
| Processing element | `rtl/mandelbrot_pe.v` | Combines the datapath, controller and iteration counter |
| Pixel generator | `rtl/display/pixel_coordinate_generator.v` | Scans the image and maps pixels to complex coordinates |
| Frame renderer | `rtl/display/mandelbrot_renderer.v` | Feeds pixels to the PE and emits per-pixel results |

### Current numerical configuration

- Image resolution: **320 × 240** (76,800 pixels).
- Maximum iteration count used by the image-generation testbench: **64**.
- Pixel coordinates: signed 16-bit values with 12 fractional bits (Q4.12 representation).
- Internal Mandelbrot coordinates: signed 21-bit values, with 12 fractional bits retained by the current datapath.
- Escape condition: the squared magnitude is greater than 4.0.
- Pixel traversal: left-to-right, top-to-bottom.
- Processing model: one PE calculates one pixel at a time.

The recurrence implemented is:

\[
 x_{n+1}=x_n^2-y_n^2+a
\]
\[
 y_{n+1}=2x_ny_n+b
\]

Starting from \(x_0=y_0=0\), iteration stops when \(x_n^2+y_n^2>4\) or the configured iteration limit is reached.

## Repository layout

```text
mini_gpu/
├── rtl/                 # Synthesizable Verilog design modules
│   └── display/         # Pixel coordinate generator and frame renderer
├── tb/                  # Verilog testbenches
│   └── display/         # Renderer and image-generation testbenches
├── scripts/             # Python plotting and numerical comparison scripts
├── sim/                 # Simulation executables and generated outputs
├── reference/            # Reserved for reference material
├── constraints/          # Reserved for FPGA pin/timing constraints
├── .gitignore
└── README.md
```

## Requirements

For RTL simulation:

- Icarus Verilog (`iverilog` and `vvp`)
- GTKWave (optional, for waveform viewing)

For Python analysis:

- Python 3
- NumPy and Matplotlib (needed by the plotting script)

On Ubuntu, the tools can be installed with:

```bash
sudo apt update
sudo apt install iverilog gtkwave python3 python3-numpy python3-matplotlib
```

## Run the full Mandelbrot image simulation

Run these commands from the **repository root** (`mini_gpu/`). The image testbench writes `sim/mandelbrot_pixels.csv`.

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

The testbench should report the number of pixels received and coordinate errors. A successful full frame contains 76,800 records, plus the CSV header.

### Plot the generated image

```bash
python3 scripts/plot_mandelbrot.py
```

This reads `sim/mandelbrot_pixels.csv` and saves the visualization to `sim/mandelbrot.png`.

### Compare RTL output with the fixed-point Python reference

```bash
python3 scripts/compare_mandelbrot.py
```

This checks the generated hardware CSV against a Python model that mirrors the current fixed-point arithmetic and 21-bit wrapping behavior. It is a consistency check between the RTL and the model, not an independent proof that the fixed-point result matches ideal real-number mathematics.

### Analyze fixed-point precision against floating point

```bash
python3 scripts/precision_analysis.py
```

This compares the generated pixel results with a floating-point Mandelbrot reference using the same quantized input coordinates. Differences can occur near the set boundary because finite-width fixed-point arithmetic truncates intermediate products and wraps values to the configured width.

## Run an individual testbench

The exact RTL dependencies vary by testbench. For a standalone module, compile the module and its dependencies together with its testbench:

```bash
iverilog -g2012 -o sim/test_sim rtl/module.v tb/module_tb.v
vvp sim/test_sim
```

Replace the example filenames with the relevant module and testbench. For a testbench that instantiates other RTL modules, include those source files in the compile command too.

To capture and inspect waveforms, enable the `$dumpfile` and `$dumpvars` statements in the relevant testbench, run the simulation, then open the generated VCD file:

```bash
gtkwave sim/waveform.vcd
```

## Validation status

Implemented testbenches cover the basic arithmetic and sequential blocks, fixed-point operations, Mandelbrot datapath, escape detection, FSM, processing element, coordinate generator and renderer. The image-generation testbench checks pixel ordering and writes the complete frame to CSV.

The Python scripts provide two distinct checks:

1. **RTL vs fixed-point reference:** checks that the hardware output matches a software model of the current bit widths, shifts and wrapping behavior.
2. **Fixed-point vs floating-point analysis:** measures numerical differences caused by finite precision.

Precision results should be regenerated from the current CSV rather than treated as permanent project specifications. The next development step is to investigate the numerical mismatches and evaluate a wider fractional datapath.

## Roadmap

- [x] Build basic combinational and sequential circuits.
- [x] Implement signed arithmetic building blocks.
- [x] Implement fixed-point arithmetic building blocks.
- [x] Implement the Mandelbrot iteration datapath and escape detection.
- [x] Implement the Mandelbrot controller and processing element.
- [x] Generate pixel coordinates for a 320 × 240 frame.
- [x] Render a complete frame in simulation and export pixel data to CSV.
- [x] Add Python visualization and numerical comparison scripts.
- [ ] Investigate fixed-point precision errors and boundary cases.
- [ ] Evaluate a wider internal fractional precision and compare accuracy/cost.
- [ ] Improve automated test coverage, including reset and restart behavior.
- [ ] Design a scheduler and add a second processing element.
- [ ] Scale to multiple PEs and measure throughput.
- [ ] Choose an FPGA board and add a synthesizable top-level design and constraints.
- [ ] Synthesize, implement and analyze FPGA resource utilization and timing.
- [ ] Add a physical display interface (for example, VGA) if supported by the target board.

## Current limitations

- The renderer uses a single PE, so pixels are processed sequentially.
- The current project has simulation results, but no completed FPGA synthesis or hardware demonstration.
- The numerical format and precision have not yet been optimized.
- `constraints/` is currently reserved; board-specific pin assignments and timing constraints will be added after selecting an FPGA board.

## Project objective

Develop a small FPGA-based graphics accelerator from the ground up, using Mandelbrot rendering as the workload. The project will explore fixed-point numerical design, datapath/control architecture, parallel processing, verification, synthesis and hardware performance trade-offs.
