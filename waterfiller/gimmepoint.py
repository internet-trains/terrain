# shh, i know it's ugly, shh

import numpy as np
import os
import sys
from PIL import Image


infile = sys.argv[1]
x = int(sys.argv[2])
y = int(sys.argv[3])
f, e = os.path.splitext(infile)
im = Image.open(infile)
print(im.getextrema())
print(im.getpixel((x, y)))
