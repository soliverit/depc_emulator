require "./lib/plotting/graph_object.rb"
class GraphLine < GraphObject
	attr_reader :startPoint, :endPoint
	def initialize startPoint, endPoint, colour = :yellow, patternChar="-", nodeChar="+"
		super startPoint, patternChar, colour
		@endPoint	= endPoint
		@nodeChar	= nodeChar
		
		@coordinates= false
	end
	def pixels
		return @coordinates if @coordinates
		@deltaX		= @endPoint.x - @startPoint.x
		@deltaY		= @startPoint.y - @endPoint.y
		@dirX		= @deltaX < 0 ? -1 : 1
		@dirY		= @deltaY < 0 ? -1 : 1
		@absDeltaX	= @deltaX.abs
		@absDeltaY	= @deltaY.abs
		if @absDeltaX >= @absDeltaY
			ratio = @deltaY.to_f / @absDeltaX.to_f 
			ratio = @absDeltaX if ratio.nan?
			(0...(@absDeltaX)).map{|idx|
				CanvasPixel.new @startPoint.x + idx * @dirX ,
					(@startPoint.y + idx * ratio  * @dirY).round.to_i,
					@patternChar,
					@colour
			}
		else
			ratio = @deltaX.to_f / @absDeltaY.to_f
			ratio = @deltaY if ratio.nan?

			(0...(@absDeltaY)).map{|idx|
				CanvasPixel.new (@startPoint.x + idx * ratio * @dirX).round,
					@startPoint.y + idx * @dirY * -1,
					@patternChar,
					@colour
			}
		end
	end
	def length
		((@startPoint.x - @endPoint.x) ** 2 + (@startPoint.y + @endPoint.y) ** 2) ** 0.5
	end
	def pixelsOLD
		deltaX 		= @startPoint.x - @endPoint.x
		deltaY 		= @startPoint.y - @endPoint.y
		xDirection	= deltaX != 0 ?  -deltaX / deltaX.abs : 1
		yDirection	= deltaY != 0 ?  deltaY / deltaY.abs : 1
		maxDiff		= [deltaX.abs, deltaY.abs].max
		ratio		= deltaX == 0 ? 0 : deltaY .to_f / deltaX.to_f
		if maxDiff == deltaX.abs
			canvasPixels = (0...maxDiff).map{|idx|
				increment = (deltaY.to_f / maxDiff*  idx)
				CanvasPixel.new(
					@startPoint.x + idx, 
					(@startPoint.y + increment * yDirection).round.to_i, 
					@patternChar,
					@colour
				)
			}
		else
			canvasPixels = (0...maxDiff).map{|idx|
				increment = (deltaX.to_f / maxDiff *  idx)
				CanvasPixel.new(
					(@startPoint.x + increment * xDirection).round.to_i,
					@startPoint.y + idx,  
					@patternChar
				)
			}
		end
		canvasPixels[0] = CanvasPixel.new(
			canvasPixels[0].column, 
			canvasPixels[0].row, 
			@nodeChar, 
			:yellow
		)
		canvasPixels[canvasPixels.length - 1]	= CanvasPixel.new(
			canvasPixels[canvasPixels.length - 1].column, 
			canvasPixels[canvasPixels.length - 1].row, 
			@nodeChar, 
			:yellow
			)
		canvasPixels
	end
	def to_s
		"Start:	#{@startPoint}\tColour: #{@colour}\nEnd:	#{@endPoint}\tSymbol:   #{@patternChar}"
	end
end