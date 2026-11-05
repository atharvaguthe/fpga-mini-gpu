
import csv
import numpy as np 
import matplotlib.pyplot as plt 

WIDTH = 320
HEIGHT = 240

iterations = np.zeros((HEIGHT,WIDTH), dtype = np.uint16)
escaped = np.zeros((HEIGHT, WIDTH), dtype = np.uint8)

with open("sim/mandelbrot_pixels.csv", "r") as file:

    reader = csv.DictReader(file)

    count = 0

    for row in reader:
        x = int(row["x"])
        y = int(row["y"])

        iterations[y,x] = int(row["iterations"])
        escaped[y,x] = int(row["escaped"])

        count += 1

print("=========================")
print("mandelbrot image analysis")
print("=========================")

print("Pixels loaded:", count)
print("image resolution:", WIDTH, "x", HEIGHT)

print("Escaped pixels",np.sum(escaped == 1))
print("Non-escaped pixels:", np.sum(escaped == 0))

print("Minimum iterations: ", iterations.min())
print("Maximum iterations: ", iterations.max())

print("unique iteration counts: ",np.unique(iterations))

image = np.ma.masked_where(escaped == 0,iterations)

cmap = plt.colormaps["turbo"].copy()
cmap.set_bad("black")

plt.figure(figsize=(12,9))

plt.imshow(image,cmap=cmap, origin="upper",interpolation="nearest",vmin=1,vmax=64)

plt.colorbar(label="Escape iterations")

plt.title("mandelbrot set - Verilog FPGA simulation")

plt.xlabel("X coordinate")
plt.ylabel("y coordinate")

plt.tight_layout()

plt.savefig("sim/mandelbrot.png",dpi=200)

plt.show()

print("image saved: sim/mandelbrot.png")

