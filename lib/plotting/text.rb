class GraphText < GraphObject
	def initialize text, position, colour = :yellow
		super position, " ", colour
		@text = text
	end
	def pixels
		@text.split("").each_with_index.map{|char, idx|
			CanvasPixel.new @startPoint.x + idx, @startPoint.y, char, @colour
		}
	end
end