from scipy.spatial import ConvexHull
class Region():
	def __init__(self, alias):
		self.alias		= alias
		self.subRegions	= []
		self.points		= []
		self.hull		= False
	def addSubRegion(self, polyline):
		self.subRegions.append(polyline)
		for point in polyline.vertices:	# Wish ah'd called them points now. Sigh
			self.points.append(point)
		self.hull	= False
	@property
	def pointArray(self):
		return [[point["x"], point["y"]] for point in self.points]
	@property
	def pointXValues(self):
		print(self.points[0])
		return [point["x"] for point in self.points]
	@property
	def pointYValues(self):
		return [point["y"] for point in self.points]
	@property
	def convexHull(self):
		if self.hull:
			return self.hull
		hull 		= ConvexHull(self.pointArray)
		points		= []
		for simplex in hull.simplices:	
			points.append({"x": self.points[simplex[0]]["x"], "y": self.points[simplex[0]]["y"]})
		self.hull	= points
		return points
	@property
	def convexHullXValues(self):
		return [point["x"] for point in self.convexHull]
	@property
	def convexHullYValues(self):
		return [point["y"] for point in self.convexHull]
			