# shh, i know it's ugly, shh

import numpy as np
import sys
from PIL import Image


infile = sys.argv[1]
x = int(sys.argv[2])
y = int(sys.argv[3])
im = Image.open(infile)

# print some basic stats: extrema and pixel value
print("(min, max):", im.getextrema())
print("point value:", im.getpixel((x, y)))


# crop and print the area near the pixel
box = (x - 3, y - 3, x + 4, y + 4)
imarray = np.asarray(im.crop(box))
print("Local region:")
print(imarray)
