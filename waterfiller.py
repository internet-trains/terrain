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
startx = int(sys.argv[2])
starty = int(sys.argv[3])
level = int(sys.argv[4])

im = Image.open(infile)
# for some reason if I don't copy it, it's read-only, which is dumb
imarray = np.asarray(im)
outarray = np.zeros_like(imarray)

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
        if nbr not in checked and max(nbr) < 1024 and min(nbr) > -1:
            # check each neighbor now
            if imarray[nbr] <= level:
                flooded.add(nbr)
                # non-flooded pixels block further checking
                tocheck.add(nbr)

if len(flooded) == 0:
    print("Nothing flooded! Choose a new start point!")

for x in flooded:
    outarray[x] = 255
outarray[startx, starty] = 128
im = Image.fromarray(outarray)
im.save(outfile)
