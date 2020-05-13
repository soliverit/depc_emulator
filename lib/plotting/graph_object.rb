class GraphObject
	attr_reader :startPoint, :patternChar, :colour
	def initialize startPoint, patternChar, colour
		@startPoint 	= startPoint
		@patternChar	= patternChar
		@colour			= colour
	end
	def coordinates
		raise "GraphObject::#{self.class}::CoordinateMethodNotImplemented"
	end
	def pixels
		raise "GraphObject::#{self.class}::PixelMethodNotImplemented"
	end
	def move
		raise "GraphObject::#{self.class}::MoveMethodNotImplemented"
	end
end