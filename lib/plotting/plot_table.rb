class PlotTable < GraphCanvas
	attr_reader :headers
	DEFAULT_CELL_VALUE	= "  -  "
	def initialize width, height, headers, title="", blankChar=" "
		super width, height, title, blankChar
		@headers	= headers
		@data		= []
		@size		= true
	end
	def width
		@width 	||= [@headers.max{|header| [header.to_s.length, @data.max{|data| data.max{|key, value| value.to_s.length}}]}].max + @headers.length - 1
	end
	def height
		@height	||= @data.height + 3
	end
	def length
		@data.length
	end
	def [] id
		@data[id].dup
	end
	def addRow values
		@width = false
		newRow = {}
		if values.class == Array
			values.each_with_index{|value, idx|	newRow[@headers[idx]] = "#{value}"}
		elsif values.class == Hash
			values.each{|key, value| newRow[key] = value}
		end
		if newRow.keys.length > 0
			@headers.each{|header| newRow[header] ||= DEFAULT_CELL_VALUE} if @headers.length != newRow.keys.length
			@data.push newRow
		end
		##
		# Maintain size integrity unless told not to.
		##
		if @size
			w = width
			h = height
			
			if @cells.length > h
				@cells = (0...h).map{|idx| @cells.idx}
			elsif @cells.length < h
				puts "SHOE" while true
			end
		end
	end
	def << otherTable
		otherTable.headers.each{|header| @headers.push if ! headers.include? header}
		(0...otherTable.length).each{|idx| addRow otherTable[idx]}
	end
	def render
		cellDims = Hash[@header.map{|header|[header, @data.max{|data| data[header].to_s.length}]}]
	end
	def pad str, len
		while str < len
			str += " "
		end
		
	end
end