### Includes ###
##Native
from glob 	import glob
from random import random
##Project
from lib_py.region_map 	import RegionMap
from lib_py.region	 	import Region
from lib_py.polyline	import Polyline

rMap 	= RegionMap()
limit	= 4454135
count	= 0
filter	= "AB"
##
# Parse potal plane data (format: two values, x and y, per row)
##
for plane in glob("./data/postal_planes/*.txt"):
	vertices	= []
	regionCode	= plane.replace("\\", "/").split("/")[-1].replace(".txt", "")[0:2]
	## Skip planes if testing. Only postcodes starting with "AB", for example.
	if filter and filter not in plane:
		continue
	## Add a region code to the Region hash. All files with the Region code
	## are added to this Region.
	if regionCode not in rMap.regions:
		rMap.addRegion(regionCode)
	## parse the input file's values
	with open(plane) as boundaryFile:
		for line in boundaryFile.readlines():
			values	= line.strip().split(",")
			vertices.append({"x": float(values[0]), "y": float(values[1])})
	## Update the RegionMap and Region
	polyline	= Polyline(vertices, regionCode, closed=True)
	rMap.regions[regionCode].addSubRegion(polyline)
	count += 1
	if count == limit:
		print("SHOE")
		break

rMap.drawRegions()
rMap.drawConvexHulls()