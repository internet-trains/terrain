# Utilities

## Town Placer

Creates a gamescript (in `./town_placer/townplacer`) that will automatically place
towns according to certain assumptions about the map corners and map size.

## Waterfiller

Given a fill origin and height and grayscale PNG, fills water on the map.

## Tree Placer

Creates a gamescript that will automatically place trees according to a
grayscale image.

## PoI Labeler

Drops signs programmatically based on PoI from a dataset.

##


1. Go to USGS EarthExplorer
  Select a region and download both the Void Filled and water body data. Save in data/scenarios/<scenario>/height and data/scenarios/<scenario>/water

2. Go to https://earthenginepartners.appspot.com/science-2013-global-forest/download_v1.2.html
  Download the tiles in the area you are interested in. Save in data/scenarios/<scenario>/trees

3. Go to http://gaia.geosci.unc.edu/rivers/
  Download the rivers that you need. Save in data/rivers

4. Go to https://download.geonames.org/export/dump/
  Download the GeoNames for the countries you need. Use https://www.geonames.org/countries/ to identify the ISO-3166 alpha2 codes.
  Delete the readmes in the zip files. Save in data/geonames

Rivers and GeoNames are stored in the terrain/data directory
Trees and USGS EarthExplorer data due to their size can be stored in per-project folders, to be deleted to clear up disk space as needed

5. Load in the height map tifs in MicroDEM

6. Scale up to a generous amount (100% is ideal) and then generate the following two files:

6.1. A coast file -- elevation color -1, 0, 1, save as geotiff
Save as data/scenarios/<scenario>/base_coast.TIF

6.2. A height file -- elevation color, grayscale, 0 to whatever the max.
Save as data/scenarios/<scenario>/base.TIF

7. Run build_stack.R after configuring scenario_name, river_scale, and map_crs the way you want in parameters.R

8. In GIMP, stack together all the files and then perform crop/scale to get the scenario file you want
