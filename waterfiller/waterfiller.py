# Water-filling script. RLB, 2019-07-23, I should have been working on my
# dissertation but I was doing this instead
# Invoke from the command line. Inputs:
#   input image filename
#   starting x coordinate
#   starting y coordinate
#   reservoir level or whatever
# so, for example,
#       python waterfiller.py test.bmp 448 512 120
# loads test.bmp, starts at point (448, 512), and fills to a water
# level of 120 (out of 255, since this is an 8 bit grayscale image)
# The output is an image that's white in the filled pixels and black otherwise,
# named "test_120.png". The starting point is made gray so you can find it,
# hopefully (128 instead of 255).

import numpy as np
import os
import sys
from PIL import Image


infile = sys.argv[1]
f, e = os.path.splitext(infile)
outfile = f + "_" + sys.argv[4] + ".png"

# assigning these "backwards" bc of how numpy arranges images
starty = int(sys.argv[2])
startx = int(sys.argv[3])
level = int(sys.argv[4])

im = Image.open(infile)
print(im.format, im.size, im.mode)
# r, __, __, __ = im.split()

# for some reason if I don't copy it, it's read-only, which is dumb
# for now, make the output always 8-bit, to make the file small
imarray = np.asarray(im)
outarray = np.zeros_like(imarray, dtype="uint8")

levelstart = imarray[startx, starty]
print(levelstart)

tocheck = set()
checked = set()
flooded = set()

# do the first step outside the loop, because I haven't thought of a better way
tocheck.add((startx, starty))
if imarray[(startx, starty)] <= level:
    flooded.add((startx, starty))
# the order of operations here is slightly weird and maybe can be improved?
while len(tocheck) > 0:

    # pop out an arbitrary value from the set
    inds = tocheck.pop()
    checked.add(inds)

    # construct neighbors
    north = (inds[0], inds[1] + 1)
    east = (inds[0] + 1, inds[1])
    south = (inds[0], inds[1] - 1)
    west = (inds[0] - 1, inds[1])
    for nbr in (north, east, south, west):
        # this isn't quite correct for non-square images yet
        if nbr not in checked and max(nbr) < im.size[0] and min(nbr) > -1:
            # check each neighbor now
            if imarray[nbr] <= level:
                flooded.add(nbr)
                # non-flooded pixels block further checking
                tocheck.add(nbr)

if len(flooded) == 0:
    print("Nothing flooded! Choose a new start point!")
else:
    Ntotal = im.size[0] * im.size[1]
    Nflooded = len(flooded)
    pctFlooded = np.round(Nflooded / Ntotal * 100, 2)
    print("{} points flooded ({}%)".format(Nflooded, pctFlooded))

for x in flooded:
    outarray[x] = 255
outarray[startx, starty] = 128
im = Image.fromarray(outarray)
im.save(outfile)
