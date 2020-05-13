class GraphCanvas
	attr_reader :width, :height
	attr_accessor :hasBorder
	def initialize width, height, title="", blankChar= " "
		@width 		= width
		@height		= height
		@blankChar	= blankChar
		@cells 		= (0...@height).map{(0...@width).map{@blankChar}}
	end
	def cells
		@cells
	end 
	def canvasColour= colour
		@cells = @cells.reverse.each_with_index.map{|row, idx|
			row.each_with_index.map{|cell, cIdx|
				if cell.class != CanvasPixel || cell.value == @blankChar
					CanvasPixel.new idx, cIdx, @blankChar, colour 
				else
					cell
				end
			}
		}
	end
	def describe
		puts  """
			Width:       #{@width}
			Height:      #{@height}
			Blank Char:  #{@blankChar}
			Has Border:  #{@hasBorder}
		"""
	end
	def setPixel row, column, value
		@cells[row][column] = value
	end
	def length
		@cells.length
	end
	def [] id
		cells[id].dup
	end
	def draw object
		object.pixels.each{|pixel| @cells[ pixel.row][pixel.column] = pixel}
	end
	def render
		boundingChar		= @hasBorder ? "#" : ""
		puts cells.map{|row| boundingChar + row.join("") + boundingChar}.join("\n")
	end
	def merge otherGraphCanvas,offsetRow=0, offsetColumn=0,  strict=false
		(0...otherGraphCanvas.height).each{|row|
			otherRow = otherGraphCanvas[row]
			curRow = row + offsetRow	
			next if curRow < 0 || curRow >= @height
			otherRow.each_with_index{|column, cIdx|
				curColumn = cIdx + offsetColumn
				next if curColumn < 0 || curColumn >= @width
				@cells[curRow][curColumn] = column if ! column.class != CanvasPixel|| strict
			}
		}	
	end
end