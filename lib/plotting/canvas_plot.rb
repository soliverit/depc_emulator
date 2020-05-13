class PlotCanvas < GraphCanvas
	def initialize width, height, title="", blankChar= " "
		super width, height, title, blankChar
	end
	def cells
		@cells.reverse
	end
end