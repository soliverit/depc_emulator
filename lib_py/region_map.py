### Includes ###
## Native
import matplotlib.pyplot as plt
## Project
from lib_py.region	import Region
class RegionMap():
	def __init__(self):
		self.regions		= {}
		self.convexHulls	= False
	def addRegion(self, regionCode):
		print(regionCode)
		self.regions[regionCode]	= Region(regionCode)
	def drawRegions(self):
		for alias, region in self.regions.items():
			plt.plot(region.pointXValues, region.pointYValues, linestyle="-", marker = "o")
		plt.show()
	def allPoints(self, filter=False):
		points = []
		for polyline in self.polylines:
			if filter and  filter not in polyline.alias:
				continue
			for point in polyline.vertices:
				points.append(point)
		return points
			
	def drawConvexHulls(self, withPoints=False):
		for alias, region in self.regions.items():
			print(alias)
			plt.plot(region.convexHullXValues, region.convexHullYValues, linestyle='-', marker="x")
			if withPoints:
				for point in region.points:
					plt.plot(point["x"], point["y"], linestyle="-")
		plt.show()
	# def createConvexHulls(self):
		# pointSets	= {}
		# for polyline in self.polylines:
			# alias	= polyline.alias[0:2]
			# if alias not in pointSets:
				# pointSets[alias] = []
			# for vertex in polyline.vertices:
				# pointSets[alias].append([vertex["x"], vertex["y"]])
		# hulls	= {}
		# for alias in list(pointSets):
			# hulls[alias] = ConvexHull(pointSets[alias])
			
		# self.convexHulls	= hulls
		
		# for ax in (ax1, ax2):
			# ax.plot(points[:, 0], points[:, 1], '.', color='k')
			# if ax == ax1:
				# ax.set_title('Given points')
			# else:
				# ax.set_title('Convex hull')
				# for simplex in hull.simplices:
					# ax.plot(points[simplex, 0], points[simplex, 1], 'c')
				# ax.plot(points[hull.vertices, 0], points[hull.vertices, 1], 'o', mec='r', color='none', lw=1, markersize=10)
			# ax.set_xticks(range(10))
			# ax.set_yticks(range(10))
		# plt.show()
		