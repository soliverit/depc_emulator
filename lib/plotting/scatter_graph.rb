class ScatterGraph < GraphIt
	def initialize width=60, height=20, name="", majorLabels=1, midPoint=true
		super width, height, name, majorLabels, midPoint
		@midPoint 			= midPoint
		@yBoundaryFactor	= 0.05
	end
	def createYBoundary 
		{min: (1 - @yBoundaryFactor)  * @seriesSet.maxY, max: (@yBoundaryFactor + 1) * @seriesSet.maxY} 
	end
	def render
		##
		# Header canvas
		##
		headerCanvas	= GraphCanvas.new @canvas.width , 3
		# Set background colour
		headerCanvas.canvasColour = :cyanWhite
		# Add graph name
		headerCanvas.draw GraphText.new " " +  @name + " ", CanvasCoordinate.new(@canvas.width / 2 - @name.length / 2 - 1, 1)
		
		##
		# Create y-axis label canvas
		##
		yAxisCanvas = PlotCanvas.new @seriesSet.longestYAxisLabelLength + 2, @canvas.height - 8
		yAxisCanvas.draw GraphLine.new(	
							CanvasCoordinate.new(yAxisCanvas.width - 1, 0),
							CanvasCoordinate.new(yAxisCanvas.width - 1, @canvas.height - 8),
							:blue,
							"|")
		
		# Create y-axis domain
		domain 		= createYBoundary
		diff		= domain[:max] - domain[:min]
		pixelYSize	= (yAxisCanvas.height.to_f / diff)
		
		# Do label numbers
		incrementY		= (@seriesSet.maxY.to_f - @seriesSet.minY) / (@canvas.width - yAxisCanvas.width)
		(0...(yAxisCanvas.height)/ 2).each{|idx|
			yAxisCanvas.draw GraphText.new (domain[:min] + diff * idx / 5.0 ).round(4).to_s, CanvasCoordinate.new(0, idx * 2), :blue
 		}
		
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
			series.values.each{|value|
				value		= value.dup
				value[0] 	= (plotAreaCanvas.width / @seriesSet.maxX.to_f * value[0]).floor
				value[1] 	= (plotAreaCanvas.height / (domain[:max] - domain[:min]) * (value[1] - domain[:min])).to_f.floor
				puts value.to_json
				plotAreaCanvas.setPixel value.last, value.first, CanvasPixel.new(value.last, value.first, series.symbol, series.colour)
			}
		}
		plotAreaCanvas.canvasColour = :greenWhite
		#legend
		legendCanvas = false
		if @legend
			legendCanvas = legend
		end
		#Mid-point line
		if @midPoint
			plotAreaCanvas.draw(
				GraphLine.new(
					CanvasCoordinate.new(0, 0),
					CanvasCoordinate.new(plotAreaCanvas.width - 1, plotAreaCanvas.height - 1),
					:cyanWhite,
					" "))
		end
		##
		# Merge all canvases
		##
		@canvas.merge headerCanvas
		@canvas.merge yAxisCanvas, 3, 0
		@canvas.merge xAxisCanvas, @canvas.height  - 5, 0
		@canvas.merge plotAreaCanvas, headerCanvas.height, yAxisCanvas.width + 1
		@canvas.merge legendCanvas, headerCanvas.height + 1, yAxisCanvas.width + 3 if legendCanvas
		@canvas.render
		
		@canvas
	end
end