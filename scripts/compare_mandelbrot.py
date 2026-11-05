
import csv 

WIDTH = 320
HEIGHT = 240
MAX_ITER = 64

def signed_wrap(value, bits):

    mask = (1 << bits) - 1
    value &= mask

    if value >= (1 << (bits -1)):
        value -= (1 << bits)

    return value


def mandelbrot_fixed(a,b):

    x = 0
    y = 0

    escaped = 0
    iterations = 0

    for i in range(1, MAX_ITER + 1):

        xx = (x * x) >> 12
        yy = (y * y) >> 12
        xy = (x * y) >> 12

        x_next = signed_wrap(xx - yy + a, 21)
        y_next = signed_wrap((xy << 1) + b, 21)

        x = x_next
        y = y_next

        iterations = i

        magnitude_squared = (x * x >> 12) + (y * y >> 12)

        if magnitude_squared > 16384:

            escaped = 1
            break
    return iterations, escaped

#load hardware simulation result

hardware = {}

with open("sim/mandelbrot_pixels.csv", "r") as file:
    reader = csv.DictReader(file)

    for row in reader:

        x = int(row["x"])
        y = int(row["y"])

        hardware[(x, y)] = (int(row["iterations"]),
                            int(row["escaped"]))

print("====================")
print("Verilog vs python ref")
print("====================")

print("hardware pixels loaded:", len(hardware))

total_pixels = 0
interation_errors = 0
escape_errors = 0
missing_pixels = 0

for py in range(HEIGHT):

    for px in range(WIDTH):

        total_pixels += 1

        if (px,py) not in hardware:
            
            missing_pixels += 1
            continue

        a = -8192 + (px * 12288//319)
        b = -6144 + (py * 12288//239)

        expected_iterations, expected_escaped = (mandelbrot_fixed(a,b))

        actual_iterations, actual_escaped = hardware[(px, py)]

        if expected_iterations != actual_iterations:

            interation_errors += 1

            if interation_errors <= 10:

                print(f"Iteration mismatch at ({px},{py}):"
                      f"Python={expected_iterations},"
                      f"Verilog={actual_iterations}")

        if expected_escaped != actual_escaped:

            escape_errors += 1

            if escape_errors <= 10:

                print(f"escape mismatch at ({px},{py}):"
                      f"Python={expected_escaped},"
                      f"Verilog={actual_escaped}")

print("-------------------------------")

print("total pixel checked:",total_pixels)
print("Missing pixels:", missing_pixels)
print("iterations mismatch:", interation_errors)
print("escape mismatch:", escape_errors)

if (
    total_pixels == WIDTH * HEIGHT
    and len(hardware) == WIDTH * HEIGHT
    and missing_pixels == 0
    and interation_errors == 0
    and escape_errors == 0
):
    print("success : exact match")

else:
    print("failed")

print("-------------------------------")
