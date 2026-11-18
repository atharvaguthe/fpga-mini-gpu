import csv
import sys

WIDTH = 320
HEIGHT = 240
MAX_ITER = 256

FRAC_BITS = 12
SCALE = 1 << FRAC_BITS
ESCAPE_LIMIT = 4 * SCALE


def signed(value, bits):
    value &= (1 << bits) - 1
    if value & (1 << (bits - 1)):
        value -= 1 << bits
    return value


def wrap(value, bits):
    return signed(value, bits)


def pixel_to_complex(px, py):
    a = -8192 + (px * 12288 // (WIDTH - 1))
    b = -6144 + (py * 12288 // (HEIGHT - 1))

    return signed(a, 16), signed(b, 16)


def mandelbrot_fixed(a, b):
    x = 0
    y = 0
    iterations = 0
    escaped = 0

    for _ in range(MAX_ITER):
        xx_raw = wrap(x * x, 42)
        yy_raw = wrap(y * y, 42)
        xy_raw = wrap(x * y, 42)

        xx = wrap(xx_raw >> FRAC_BITS, 30)
        yy = wrap(yy_raw >> FRAC_BITS, 30)
        xy = wrap(xy_raw >> FRAC_BITS, 30)

        x_result = wrap(xx - yy + a, 30)
        xy_shifted = wrap(xy << 1, 30)
        y_result = wrap(xy_shifted + b, 30)

        x_next = wrap(x_result, 21)
        y_next = wrap(y_result, 21)

        x_square = wrap(
            wrap(x_next * x_next, 42) >> FRAC_BITS, 30
        )
        y_square = wrap(
            wrap(y_next * y_next, 42) >> FRAC_BITS, 30
        )

        magnitude = (
            (x_square & ((1 << 30) - 1)) +
            (y_square & ((1 << 30) - 1))
        ) & ((1 << 31) - 1)

        iterations += 1

        if magnitude > ESCAPE_LIMIT:
            escaped = 1
            break

        x = x_next
        y = y_next

    return iterations, escaped


def generate_reference():
    reference = {}

    for py in range(HEIGHT):
        for px in range(WIDTH):
            a, b = pixel_to_complex(px, py)
            iterations, escaped = mandelbrot_fixed(a, b)

            reference[(px, py)] = (iterations, escaped)

    return reference


def check_file(filename, reference):
    actual = {}

    with open(filename, newline="") as f:
        reader = csv.DictReader(f)

        for row in reader:
            px = int(row["x"])
            py = int(row["y"])
            iterations = int(row["iterations"])
            escaped = int(row["escaped"])

            key = (px, py)

            if key in actual:
                raise AssertionError(f"Duplicate pixel: {key}")

            actual[key] = (iterations, escaped)

    if len(actual) != WIDTH * HEIGHT:
        raise AssertionError(
            f"Expected {WIDTH * HEIGHT} pixels, got {len(actual)}"
        )

    mismatches = []

    for coordinate, expected in reference.items():
        got = actual.get(coordinate)

        if got != expected:
            mismatches.append((coordinate, expected, got))

    if mismatches:
        print(f"\nFAIL: {filename}")
        print(f"Mismatched pixels: {len(mismatches)}")

        for coordinate, expected, got in mismatches[:20]:
            print(
                f"Pixel {coordinate}: "
                f"expected={expected}, RTL={got}"
            )

        return False

    print(f"PASS: {filename}")
    print(f"Pixels verified: {len(actual)}")
    print("Iterations: exact match")
    print("Escape flags: exact match")

    return True


if __name__ == "__main__":
    reference = generate_reference()

    print("Generated fixed-point golden reference")
    print(f"Resolution: {WIDTH} x {HEIGHT}")
    print(f"Maximum iterations: {MAX_ITER}")
    print()

    files = sys.argv[1:] or [
        "sim/rtl_results_1pe.csv",
        "sim/rtl_results_2pe.csv",
        "sim/rtl_results_4pe.csv",
        "sim/rtl_results_8pe.csv",
    ]

    all_passed = True

    for filename in files:
        try:
            if not check_file(filename, reference):
                all_passed = False

        except FileNotFoundError:
            print(f"MISSING: {filename}")
            all_passed = False

    print()
    print("=" * 45)
    print(
        "GOLDEN REFERENCE: " +
        ("ALL TESTS PASSED" if all_passed else "FAILURE")
    )
    print("=" * 45)

    sys.exit(0 if all_passed else 1)
