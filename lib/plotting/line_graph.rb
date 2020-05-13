class LineGraph < GraphIt
	def initialize width=60, height=20, name="", majorLabels=1, midPoint=false
		super width, height, name, majorLabels, midPoint
	end
	def render
		##
		# Header canvas
		##
		headerCanvas 	= header
		##
		# Y-axis canvas
		##
		yAxisCanvas 	= createYAxisCanvas
		##
		# Do x-axis
		##
		xAxisCanvas	= GraphCanvas.new @canvas.width, 11
		xAxisCanvas.draw GraphLine.new(
							CanvasCoordinate.new(yAxisCanvas.width + 1, 0),
							CanvasCoordinate.new(@canvas.width - yAxisCanvas.width - 1, 0),
							:white,
							"-")
		# Do X label numbers
		incrementX = @seriesSet.maxX.to_f / xAxisCanvas.width * 6
		incrementX = (@seriesSet.maxX.to_f - @seriesSet.minX) / (@canvas.width - yAxisCanvas.width)
		(0...xAxisCanvas.width / 6).each{|idx|
			xAxisCanvas.draw GraphText.new (@seriesSet.minX + idx * 6).round.to_i.to_s, CanvasCoordinate.new(yAxisCanvas.width + 1 + idx * 6, 1), :blue
		}
		##
		# Do series'es'es'es'es
		##
		plotAreaCanvas = PlotCanvas.new @canvas.width - yAxisCanvas.width - 1, yAxisCanvas.height
		@seriesSet.each{|series|
			len 	= series.values.length 
			values	= series.values
			xOffset	= (plotAreaCanvas.width / values.length.to_f).round.to_i
			posDiff	= ((@canvas.length - yAxisCanvas.width) / series.values.length).round
			values.each_with_index{|value, idx|
				idx += 1
				break if  values.length == idx
				plotAreaCanvas.draw(
					GraphLine.new(
						CanvasCoordinate.new(xOffset * (idx - 1) , values[idx - 1].last),
						CanvasCoordinate.new(xOffset * idx, values[idx].last),
						series.colour,
						series.symbol
					)
				)
			}	
		}
		##
		# Overlays and plot lines
		##
		#legend
		legendCanvas = false
		if @legend
			legendCanvas = legend
		end
		
		
		##
		# Merge all canvases
		##
		@canvas.merge headerCanvas
		@canvas.merge yAxisCanvas, 3, 0
		@canvas.merge xAxisCanvas, @canvas.height  - 5, 0
		@canvas.merge plotAreaCanvas, headerCanvas.height, yAxisCanvas.width + 1
		@canvas.merge legendCanvas, headerCanvas.height + 1, yAxisCanvas.width + 3 if legendCanvas
		##
		# Draw it!
		##
		@canvas.render
	end
end