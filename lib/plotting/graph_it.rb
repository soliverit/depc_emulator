require "./lib/print_helper.rb"
require "./lib/plotting/canvas.rb"
class GraphIt
	attr_reader :seriesSet
	def initialize width=60, height=20, name="", majorLabels=1, midPoint=false
		@width			= width
		@height			= height
		@name			= name
		@seriesSet		= SeriesSet.new
		@canvas			= GraphCanvas.new @width, @height
		@majorLabels	= majorLabels
		@legend			= false
		@legendSort		= false
	end
	##
	# Add Series to SeriesSet
	#
	# series:	Series
	##
	def addSeries series
		@seriesSet.push series
	end
	##
	# Sort legend keys method
	#
	# &block:	A Proc for sorting SeriesSet keys
	##
	def legendSort &block
		@legendSort = block
	end
	##
	# Create a header for the plot
	##
	def header
		headerCanvas	= GraphCanvas.new @canvas.width , 3
		headerCanvas.canvasColour = :cyanWhite
		# Add graph name
		headerCanvas.draw GraphText.new " " +  @name + " ", CanvasCoordinate.new(@canvas.width / 2 - @name.length / 2 - 1, 1)
		# Return the new header canvas
		headerCanvas
	end
	##
	# Create a y-axis GraphCanvas
	## 
	def createYAxisCanvas
		##
		# Create y-axis label canvas
		##
		yAxisCanvas = GraphCanvas.new @seriesSet.longestYAxisLabelLength + 2, @canvas.height - 8
		yAxisCanvas.draw GraphLine.new(	
							CanvasCoordinate.new(yAxisCanvas.width - 1, 0),
							CanvasCoordinate.new(yAxisCanvas.width - 1, @canvas.height - 8),
							:blue,
							"|")
		# Do label numbers
		incrementY		= (@seriesSet.maxY.to_f - @seriesSet.minY) / (@canvas.width - yAxisCanvas.width)
		(0...yAxisCanvas.height/ 2).each{|idx|
			yAxisCanvas.draw GraphText.new (@seriesSet.maxY - idx * incrementY * 2).round.to_i.to_s, CanvasCoordinate.new(0, idx * 2), :blue
 		}
		yAxisCanvas
	end
	##
	# Create a legend of the symbol and name of each Series
	#
	# return:	GraphCanvas with Series labels legend info
	##
	def legend
		return if ! @legend
		# New canvas size of longest Series name + 2 and height of the No. Series + 2 buffer
		legendCanvas 	= GraphCanvas.new @seriesSet.seriesNames.sort{|a, b| b.length <=> a.length}.first.length + 4, @seriesSet.length 
		@seriesSet.sortKeys @legendSort
		i 				= 0
		@seriesSet.each{|series|
			#Series symbol
			legendCanvas.draw GraphText.new(
				series.symbol, 
				CanvasCoordinate.new(1, i), 
				series.colour)
			#Series name
			legendCanvas.draw GraphText.new(
				" " + series.name, 
				CanvasCoordinate.new(legendCanvas.width - series.name.length , i), 
				:white)
			i += 1
		}
		legendCanvas
	end
	##
	# Toggle return from 'legend' to either false or GraphCanvas
	#
	# value:	Boolean, produce legeng GraphCanvas
	##
	def legend= value
		@legend = value
	end
	##
	# Plot the SeriesSet to the console as whatever GraphIt type
	##
	def plot
		raise "GraphIt::#{self.class}::PlotMethodNotImplemented"
	end
end