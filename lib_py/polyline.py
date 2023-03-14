class Polyline():
	def __init__(self, vertices, alias, closed=False):
		self.vertices 	= vertices
		self.alias		= alias
		self.closed		= closed
		if closed and self.vertices[0] != self.vertices[-1]:
			self.vertices.append(self.vertices[0])
	