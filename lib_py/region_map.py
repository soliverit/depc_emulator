import matplotlib.pyplot as plt
from scipy.spatial import ConvexHull
class RegionMap():
	def __init__(self):
		self.polylines		= []
		self.convexHulls	= False
	def addPolyline(self, shape):
		self.polylines.append(shape)
	def drawPolylines(self):
		for polyline in self.polylines:
			# Open polylines technically have a start and end point, with vertices in between
			for idx in range(len(polyline.vertices) - 1):	
				vertex1	= polyline.vertices[idx]
				vertex2	= polyline.vertices[idx + 1]
				plt.plot([vertex1["x"], vertex2["x"]], [vertex1["y"], vertex2["y"]], linestyle="-", marker = "o")
		plt.show()
	def drawConvexHulls(self):
		if not self.convexHulls:
			self.createConvexHulls()
			print("SHOE")
		for hullAlias in list(self.convexHulls):
			hull 		= self.convexHulls[hullAlias]
			vertices	= {"x": [], "y": []}
			for simplex in hull.simplices:	
				print(simplex[0])
				vertices["x"].append(simplex[0])
				vertices["y"].append(simplex[1])
			for idx in range(len(vertices["x"]) - 1):
				plt.plot([vertices["x"][idx], vertices["x"][idx + 1]], [vertices["y"][idx], vertices["y"][idx + 1]], linestyle="-", marker = "o")
		plt.show()
	def createConvexHulls(self):
		pointSets	= {}
		for polyline in self.polylines:
			alias	= polyline.alias[0:2]
			if alias not in pointSets:
				pointSets[alias] = []
			for vertex in polyline.vertices:
				pointSets[alias].append([vertex["x"], vertex["y"]])
		hulls	= {}
		for alias in list(pointSets):
			hulls[alias] = ConvexHull(pointSets[alias])
			
		self.convexHulls	= hulls
		
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
		