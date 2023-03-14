### Includes ###
##Native
from glob import glob
##Project
from lib_py.region_map 	import RegionMap
from lib_py.polyline	import Polyline

rMap 	= RegionMap()
limit	= 4
count	= 0
filter	= "AB"
for plane in glob("./data/postal_planes/*.txt"):
	vertices	= []
	if filter and filter not in plane:
		continue
	with open(plane) as boundaryFile:
		for line in boundaryFile.readlines():
			values	= line.strip().split(",")
			vertices.append({"x": float(values[0]), "y": float(values[1])})
	polyline	= Polyline(vertices, plane.replace("\\", "/").split("/")[-1].replace(".txt", ""), closed=True)
	rMap.addPolyline(polyline)
	count += 1
	if count == limit:
		break
hulls = rMap.drawConvexHulls()
print(hulls["AB"])
rMap.draw()