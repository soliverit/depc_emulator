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
for plane in glob("./data/postal_planes/*.txt"):
	vertices	= []
	regionCode	= plane.replace("\\", "/").split("/")[-1].replace(".txt", "")[0:2]
	if filter and filter not in plane:
		continue
	if regionCode not in rMap.regions:
		rMap.addRegion(regionCode)
	with open(plane) as boundaryFile:
		for line in boundaryFile.readlines():
			values	= line.strip().split(",")
			vertices.append({"x": float(values[0]), "y": float(values[1])})
	polyline	= Polyline(vertices, regionCode, closed=True)
	rMap.regions[regionCode].addSubRegion(polyline)
	count += 1
	if count == limit:
		print("SHOE")
		break

rMap.drawRegions()
rMap.drawConvexHulls()