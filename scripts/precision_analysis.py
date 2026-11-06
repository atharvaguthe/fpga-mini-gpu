

import csv 

WIDTH = 320
HEIGHT = 240
MAX_ITER = 64


def mandelbrot_float(a, b):

    x = 0.0
    y = 0.0

    escaped = 0
    iterations = 0

    for i in range(1, MAX_ITER + 1):

        x_next = x*x - y*y + a
        y_next = 2*x*y + b

        x = x_next
        y = y_next

        iterations = i

        magnitude_squared = x*x + y*y

        if magnitude_squared > 4.0:

            escaped = 1
            break
        
    return iterations, escaped


hardware = {}

with open("sim/mandelbrot_pixels.csv", "r") as file:

    reader = csv.DictReader(file)

    for row in reader:

        px = int(row["x"])
        py = int(row["y"])

        hardware[(px,py)] = (int(row["iterations"]), int(row["escaped"]))

print("===============================")
print("fixed point vs floating point analysis")
print("===============================")

print("hardware pixels loaded",len(hardware))

iterations_mismatches = 0
escape_mismatches = 0
total_pixels = 0

max_iteration_difference = 0

examples = []

for py in range(HEIGHT):

    for px in range(WIDTH):

        if (px, py) not in hardware:
            continue

        total_pixels += 1

        a_fixed = -8192 + (px * 12288 // 319)
        b_fixed = -6144 + (py * 12288 // 239)

        a = a_fixed / 4096.0
        b = b_fixed / 4096.0

        float_iterations, float_escaped = (mandelbrot_float(a,b))

        fixed_iterations, fixed_escaped = hardware[(px,py)]

        iteration_difference = abs(float_iterations - fixed_iterations)

        max_iteration_difference = max(max_iteration_difference,iteration_difference)

        if float_iterations != fixed_iterations:
            iterations_mismatches += 1


        if float_escaped != fixed_escaped:
            escape_mismatches += 1
            print(f"Excape misatch at({px},{py}):"
                  f"fixed={fixed_escaped}"
                  f"float={float_escaped}"
                  f"fixed iterations={fixed_iterations}"
                  f"float iterations={float_iterations}")

        if ((float_iterations != fixed_iterations or float_escaped != fixed_escaped) and len(examples) < 10):

            examples.append((px,py,fixed_iterations,float_iterations,fixed_escaped,float_escaped))


print("=========================================")

print("Pixedls compared:", total_pixels)

print("iterations_mismatches: ", iterations_mismatches)

print("Excape mismatches:", escape_mismatches)

print("max iteration difference:", max_iteration_difference)

if total_pixels:

    iteration_accuracy = (1 - iterations_mismatches / total_pixels) * 100

    escape_accuracy = (1 - escape_mismatches / total_pixels) * 100

    print(f"Iteration agreement: {iteration_accuracy:.4f}%")
    print(f"Escape agreement: {escape_accuracy:.4f}%")

print("=====================================")

if examples:

    print("first mismatching pixels:")

    for item in examples:
        
        px, py, fi, fl, fe, fle = item

        print(f"Pixel({px},{py} |"
            f"Fixed: {fi}, escaped={fe} | "
            f"Float: {fl}, escaped={fle}")

else:

    print("No difference")
print("=============================================")
