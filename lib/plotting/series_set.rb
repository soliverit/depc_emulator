class SeriesSet
	def initialize 
		@series 	= {}
		@minMax		= false
		@sortKeys	= false
	end
	def push series
		@series[series.name]	= series
		@minMax					= false
	end
	def sortKeys block
		@sortKeys = block
	end
	def length
		@series.keys.length
	end
	def minMax
		return if @minMax
		seriesSet	= @series.map{|key, series| series}
		firstSeries	= seriesSet.pop
		@minMax		= {	minX: firstSeries.minX, maxX: firstSeries.maxX,
						minY: firstSeries.minY, maxY: firstSeries.maxY}
		seriesSet.each{|series|
			@minMax[:minX] = series.minX	if series.minX < @minMax[:minX]
			@minMax[:minY] = series.minY	if series.minY < @minMax[:minY]
			@minMax[:maxX] = series.maxX	if series.maxX > @minMax[:maxX]
			@minMax[:maxY] = series.maxY	if series.maxY > @minMax[:maxY]
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
		@series.map{|name, series| series.longestYAxisLabelLength}.max
	end
	def each 
		(@sortKeys ? @series.keys.sort(&@sortKeys) : @series.keys).each{|key|
			yield @series[key]
		}
	end
	def seriesNames
		@series.map{|key, series| series.name}
	end
end