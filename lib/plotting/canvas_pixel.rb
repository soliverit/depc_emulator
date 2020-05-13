class CanvasPixel
	attr_reader :row, :column, :colour, :value
	COLOURS = {
		white:	30,
		red:	31,
		green:	32,
		yellow: 33,
		blue:	34,
		redWhite:		41,
		greenWhite: 	42,
		yellowWhite:	43,
		blueWhite:		44,
		magentaWhite:	45,
		cyanWhite:		46
	}
	def self.colours
		COLOURS.dup
	end
	DEFAULT_VALUE = "x"
	def initialize column, row, value=DEFAULT_VALUE, colour=:yellow
		@row 	= row
		@column	= column
		@value	= value
		@colour	= colour
	end
	def describe
		puts "X: #{@column}\tY: #{@row}"
	end
	def to_s
		@colour ? "\e[#{COLOURS[@colour]}m#{@value}\e[0m" : @value
	end
end