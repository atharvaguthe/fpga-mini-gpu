
WIDTH = 320
HEIGHT = 240
MAX_ITER = 64
FRACTION_BITS_TO_TEST = (12,14,16,18,20,24)

def signed_wrap(value: int, bits: int) -> int:

    mask = (1 << bits) - 1
    value &= mask
    sign_bit = 1 << (bits - 1)
    return value - (1 << bits) if value & sign_bit else value

def pixel_coordinates(px: int, py: int, fractional_bits: int):

    scale = 1 << fractional_bits 
    a_raw = -(2 * scale) + (px * (3 * scale)) // (WIDTH - 1)
    b_raw = -(3 * scale // 2) + (py *(3 * scale)) // (HEIGHT - 1)
    return a_raw, b_raw

def mandelbrot_fixed(a_raw: int, b_raw: int, fractional_bits: int, width: int):
    
    x = 0
    y = 0
    escape_threshold = 4 << fractional_bits

    for iteration in range(1, MAX_ITER + 1):
        xx = (x * x) >> fractional_bits
        yy = (y * y) >> fractional_bits
        xy = (x * y) >> fractional_bits

        x = signed_wrap(xx - yy + a_raw, width)
        y = signed_wrap((xy << 1) + b_raw, width)

        magnitude_squared = ((x * x) >> fractional_bits) + ((y * y) >> fractional_bits)
        if magnitude_squared > escape_threshold:
            return iteration, 1
    return MAX_ITER, 0

def mandelbrot_float(a: float, b: float):

    x = 0.0
    y = 0.0

    for iteration in range(1, MAX_ITER + 1):
        x_next = x * x - y * y + a
        y_next = 2.0 * x * y + b 
        x, y = x_next, y_next

        if x * x + y * y > 4.0:
            return iteration, 1
    return MAX_ITER, 0

def run_sweep():
    
    total_pixel = WIDTH * HEIGHT

    print("Mandelbrot fixed-point precision sweeep")
    print(f"Resolution: {WIDTH} * {HEIGHT}  Max Iteration: {MAX_ITER}")
    print("Reference: pythond double precision, using each format's quantized input grid")
    print()
    print(f"{'Format':<12}{'Bits':>6}{'Iter mismatches':>19}{'Escape mismatches':>20}{'Iter agreement':>18}{'Escape agreement':>19}{'Max iter diff':>16}")
    print("-" * 110)

    for fractional_bits in FRACTION_BITS_TO_TEST:
        coordinate_width = fractional_bits + 9
        iteration_mismatches = 0
        escape_mismatches = 0
        max_iteration_difference = 0

        for py in range(HEIGHT):
            for px in range(WIDTH):

                a_raw, b_raw = pixel_coordinates(px,py,fractional_bits)
                scale = 1 << fractional_bits

                fixed_iterations, fixed_escaped = mandelbrot_fixed(a_raw,b_raw, fractional_bits, coordinate_width)
                float_iterations, float_escaped = mandelbrot_float(a_raw / scale, b_raw / scale)

                if fixed_iterations != float_iterations:
                    iteration_mismatches += 1
                if fixed_escaped != float_escaped:
                    escape_mismatches += 1

                
                difference = abs(fixed_iterations - float_iterations)
                if difference > max_iteration_difference:
                    max_iteration_difference = difference

        iteration_agreement = 100.0 * (1 - iteration_mismatches / total_pixel)
        escape_agreement = 100.0 * (1 - escape_mismatches / total_pixel)
        format_name = f"Q9.{fractional_bits}"

        print(
            f"{format_name:<12}{coordinate_width:>6}"
            f"{iteration_mismatches:>19,}{escape_mismatches:>20,}"
            f"{iteration_agreement:>17.4f}%{escape_agreement:>18.4f}%"
            f"{max_iteration_difference:>16}"
        )

if __name__ == "__main__":
    run_sweep()
