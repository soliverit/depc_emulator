class Series
	attr_accessor :name, :colour, :symbol
	##
	# 
	# name:	Series name as String
	# values:	Numerical values either as Array of 2 element Arrays or
	#			an Array of numeric value which will be translaged into
	#			[[0, value],..]
	##
	def initialize name, values, precision=2, colour=:yellow, symbol="x", createLabels=false
		@name		= name
		@values		= values.first.class == Array ? values.dup : values.map{|value| [0, value]}
		@precision	= precision
		@colour		= colour
		@minMax		= false
		@symbol		= symbol
		@doLabels	= createLabels
	end
	def values
		@values.map{|value| [value.first.round(@precision), value.last.round(@precision)]}
	end
	def minMax
		return if @minMax
		values 		= @values.dup
		firstValue	= values.pop
		@minMax		= {	minX: firstValue[0], maxX: firstValue[0],
						minY: firstValue[1], maxY: firstValue[1]}
		values.each{|value|
			@minMax[:minX] = value[0] if value[0] < @minMax[:minX]
			@minMax[:minY] = value[0] if value[0] < @minMax[:minY]
			@minMax[:maxX] = value[1] if value[1] > @minMax[:maxX]
			@minMax[:maxY] = value[1] if value[1] > @minMax[:maxY]
		}
	end
	def minX
		minMax
		@minMax[:minX]
	end
	def minY
		minMax
		@minMax[:minY]
	end
	def maxX
		minMax
		@minMax[:maxX]
	end
	def maxY
		minMax
		@minMax[:maxY]
	end
	def longestYAxisLabelLength
		@longestYLabelLength ||= @values.length  == 0 ? 0 : values.map{|value|  [value[0].to_s.length, value[1].to_s.length]}.flatten.max
	end
end