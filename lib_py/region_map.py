### Includes ###
## Native
import matplotlib.pyplot as plt
## Project
from lib_py.region	import Region
class RegionMap():
	##
	# Prepare region and convex hull storage
	##
	def __init__(self):
		self.regions		= {}
		self.convexHulls	= False
	##
	# Add Region:
	#
	# Regions are basically glorified Polylines at this point. They're
	# distinguished for other functinoality, like convex hulls and 
	# point value retireval (all Xvalue, for example).
	##
	def addRegion(self, regionCode):
		self.regions[regionCode]	= Region(regionCode)
	##
	# Draw the boundaries of all Regions.
	##
	def drawRegions(self):
		for alias, region in self.regions.items():
			plt.plot(region.pointXValues, region.pointYValues, linestyle="-", marker = "o")
		plt.show()
	##
	# Get all points from all regions
	#
	# filter:	A two character key that retstricts processed regions "AB" for AB12BC, for example.
	##
	def allPoints(self, filter=False):
		points = []
		for polyline in self.polylines:
			if filter and  filter not in polyline.alias:
				continue
			for point in polyline.vertices:
				points.append(point)
		return points
	##
	# Draw the convex hulls of all Regions
	##
	def drawConvexHulls(self, withPoints=False):
		for alias, region in self.regions.items():
			print(alias)
			plt.plot(region.convexHullXValues, region.convexHullYValues, linestyle='-', marker="x")
			if withPoints:
				for point in region.points:
					plt.plot(point["x"], point["y"], linestyle="-")
		plt.show()