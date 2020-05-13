#########################################
# Linear Regression Printing Helper		#
#										#
# Prettifier for printing to the 		#
# the console.							#
#										#
# Supports:								#
#	- Creating tables					#
#	- Creating bar graphs				#
#	- Padding strings					#
#	- Generating repeated char strings	#
#	- determine optimal pad size		#
#########################################
class LRPrintHelper
	##
	# Pad a string to a given length
	#
	# input:	String
	# length:	Integer expected end String length
	# withPipe:	Should a pipe be appended to the output?
	# round:	Rounding precision for Floats
	#
	# Output:	String of (input param: length) length
	#
	# RUBY bug:	Lost the post but there's a frozen string but in 2.4 which
	#			appears to bugger Symbol to string conversion
	##
	def self.pad input, length=14, padChar = false, withPipe = false, round=2
		padChar = " " if ! padChar
		input = "NULL"  unless input
		inStr =[String, Symbol, Array, Hash].include?(input.class) ? input.to_s : input.round(round).to_s #rescue "Infinity?"
		while inStr.length < length
			inStr = inStr +  padChar
		end
	
		inStr = inStr + " | " if withPipe
		inStr
	end
	##
	# Centre pad the string
	#
	# Broke trying to fix the Rduby bug mentioned above. Come back to it
	# in the morning.
	##
	# def self.centrePad input, length= 14, round=3
		# input = input.round(round) if ! [Symbol, String].include?(input.class)
		# padLength = length - input.to_s.length	
		# output = self.spamCharacter(" ", padLength.to_i + 1 ) + input.to_s + self.spamCharacter(" ", 1 + padLength.to_i ) 
		# output += padLength % 2 == 1 ? " " : ""
	# end
	##
	# Translate a Hash into a print rows with multiple rows
	#
	# hash:			Input Hash 
	# columns:		Number of columns per row
	# numericKeys:	Are the keys to be treated as numeric (for sorting where numeric Symbols are key)
	# padSize:		Number of characters to pad value Strings to
	# round:		Rounding precision for numeric values
	#
	# Output:		String representation of the columned Hash#
	# 
	# Example:		{a:1, b:2, c:3, d:1}, 2, false, 3}
	#
	#				a: 1 b: 2 
	#				c: 3 d: 4
	##
	def self.hashToRows hash, columns=1, numericKeys=false, padSize=20, round=3
		keys = self.sortArray hash.keys
		tempStrs	= []
		tempStr 	= ""
		keys.each_with_index{|key, index|
			if (columns + index) % columns == 0
				tempStrs.push tempStr if tempStr != ""
				tempStr = ""
			end
			tempStr << self.pad(key.to_s + ":", padSize)
			tempStr << self.pad(hash[key], padSize)
		}
		tempStrs.push tempStr
		tempStrs.join("\n")
	end
	##
	# Hash to multi-row table. Turn hash in String table
	#
	# hash:		Input hash, possibly nested hashes (2D at most)
	# keys:		Sorted keys for the headers
	# padSize:	Header and value string length expected
	# tab:		Default spacing string
	#
	# Output:	String of hash table representation
	##
	def self.multiRowTableFromHash hash, keys, padSize, tab = "    "
		labelLen = 0
		nestedKeys = self.sortArray( hash.map{|key, val|
			val.keys.map{|k|
				labelLen = k.to_s.length if k.to_s.length > labelLen
				k
			}
		}.flatten.uniq)
		columnPads = Hash[hash.keys.map{|key| [key, 0]}]
		hash.keys.each{|key|
			columnPads[key] = key.to_s.length if key.to_s.length > columnPads[key]
			hash[key].keys.each{|nKey|
				hash[key][nKey] = hash[key][nKey].round(3) if ![String,Symbol].include?(hash[key][nKey].class)
				columnPads[key] = hash[key][nKey].to_s.length if hash[key][nKey].to_s.length > columnPads[key]
				columnPads[key] = nKey.to_s.length if nKey.to_s.length > columnPads[key]
			}
			# columnPads[key] += 1 if columnPads[key] % 2 == 1
		}
		labelLen += 2
		lLength = 0
		header = tab + colourise("| ", @@colourCodes[:white]) + self.pad("",labelLen) + keys.map{|key| 
			lLength += columnPads[key]
			self.colourise(key.to_s, @@colourCodes[:yellow]) +  self.spamCharacter(" ", columnPads[key] - key.to_s.length) + " |"
		}.join("")
		rows = nestedKeys.map{|nestedKey|
			tab + colourise("| ", @@colourCodes[:white]) + self.pad(nestedKey, labelLen) + keys.map{|key| 
				self.pad(hash[key][nestedKey], columnPads[key], false) + colourise(" |", @@colourCodes[:white])
			}.join("")
		}
		[
			colourise(tab + self.spamCharacter("=", lLength+ 2 * keys.length + labelLen + 4)+ "=", @@colourCodes[:white]),
			header,
			colourise(tab + "|" + self.spamCharacter("=", lLength+ 2 * keys.length + labelLen + 4), @@colourCodes[:white]), rows, tab + colourise(self.spamCharacter("=", lLength+ 2 * keys.length + labelLen + 4), @@colourCodes[:white])].flatten.join("\n")
	end
	##
	# Create a string table for the passed Hash
	#
	# hash:			The hash in question. Hash
	# numericKeys:	Are the keys implicitly numeric? Boolean
	# padSize:		Number of characters in each padded string
	#
	# Output:		Returns a string representation of the table. String
	#
	# TODO:
	#	- Work with mixed keys, String and Numeric
	#	- Multiple rows
	##
	def self.hashToTable hash, numericKeys=false, padSize=2, round = 3
		padSize = self.optimalPadSize hash unless padSize
		keys 	= self.sortArray hash.keys
		hash = hash.dup
		
		if hash[keys.first].class == Hash
			hash.keys.each{|key|
			hash[key].keys.each{|nKey|
				hash[key][nKey] = hash[key][nKey].round(round).to_s if ! [Symbol, String].include? hash[key][nKey].class
			}
		}
			puts self.multiRowTableFromHash hash, keys, false
		else
			headers 	= "|"
			values	 	= "|"
			keys.each{|key|
				headers << self.pad(key.dup, padSize)
				values	<< self.pad(hash[key].dup, padSize)
			}
			puts [headers, self.spamCharacter("-", values.length),values].join("\n")
		end
	end
	##
	# Sort a set based on whether it's numeric or not
	#
	# Output:	Sorted Array. Array[Variant]
	#
	# Notes:
	#	- Yep, this doesn't belong here but it's convenient
	##
	def self.sortArray arr
		
		if arr.map{|a| a.to_s.match(/^-?\d+$/)}.compact.length == arr.length
			arr.sort{|a,b|a.to_s.to_i <=> b.to_s.to_i} 
		else
			arr.sort{|a,b| a <=> b}
		end
	end
	##
	# Determine the optimal padding size based on the maximum length of the passed 
	# hash keys and values
	#
	# hash:		Hash to be assessed
	#
	# Output:	Length of the longest Key or value String
	## 
	def self.optimalPadSize hash
		len = 0
		hash.keys.each{|key|
			#Ruby doesn't like case with classes apparently, use string
			case hash[key].class.to_s
			when "Hash"
				val = self.optimalPadSize hash[key]
				len =  val if len < val
			when "Array"
				hash[key].each{|value| len = value.to_s.length if len < value.to_s.length}
			else
				val = [Symbol, String].include?(hash[key].class) ? hash[key].to_s.length : hash[key].round(3).to_s.length
				len = val if len < val
			end
			len = key.to_s.length if key.to_s.length > len
		}
		len
	end
	##
	# Generate a string of N characters of the same character
	#
	# char:		Character to be spammed. String
	# length:	Number of character in the output. Integer
	#
	##
	def self.spamCharacter char, length
		output = ""
		while output.length < length
			output << char
		end
		output
	end
	##
	# Turn a string into a coloured string!
	#
	# Output:	String that tells the console to print its contents in a particular colour
	##
	def self.colourise(text, colourCode)
	  "\e[#{colourCode}m#{text}\e[0m"
	end
	##
	# Keyed colour codes for Windows console only
	##
	@@colourCodes = {
		white:	30,
		red:	31,
		green:	32,
		yellow: 33,
		blue:	34
	}
	##
	# Graph it! Create a bar graph from a Hash.
	#
	# values:		Hash of bar values and labels
	# scale:		Number of rows used to represent the highest value bar
	# keys:			Force the key order or even passed filtered keys to only print those
	# barColour:	Colour of the bars as @@colourCodes key Symbol
	# labelColour:	Colour of the labels as @@colourCodes key Symbol
	# lineClour:	Colour of the lines around the graph as @@colourCodes key Symbol
	# pad:			String that separates the left-most edge of the console and the print
	#
	# TODO:
	# 	- Introduce stacked bars
	##
	def self.graphIt values, scale,keys = false, barColour = :yellow, labelColour= :blue, lineColour=:white, pad=""
		keys = values.keys.dup unless keys
        min = 0
        max = 0    
        values.each{|key,value|

            max = value if value > max
            min = value if value < min
        }
        labelPadSize	= max.to_s.length + 5
		padSize			= max.to_s.length  + 5
		maxKeyLength = keys.dup.sort{|a, b| b.to_s.length <=> a.to_s.length}.first.to_s.length + 2
        increment = ((max + min.abs) / scale.to_f)
        counter = max
        zeroBar = false
		labelID = 0
        while counter > min do
            if counter <= 0 && ! zeroBar
                zeroBar = true
				print pad
                (0...values.length).each{|i| print ((i > 0)? "---------": "\t")}
                print "\n"
            end
            counterStr = counter.round(3).to_s
            print "#{pad}#{(colourise(self.pad(counterStr, labelPadSize, false), @@colourCodes[labelColour]))}"
            print self.colourise("|",@@colourCodes[lineColour])
            numericCount = 0
            keys.each{|key|
                value = values[key]
				isNumeric = ((value >= counter && counter >= 0) || counter < 0 && value <= counter)
				numericCount += 1 
				print colourise( isNumeric ? "  ##" : "    ", (value> 0)? @@colourCodes[barColour] : 31)
		   }
			if labelID < keys.length
				value = values[keys[labelID]]
				print self.spamCharacter("  " , (keys.length - numericCount) * 6)
				print self.spamCharacter(" ", maxKeyLength - keys[labelID].to_s.length) + value.round(4).to_s
				print self.pad((labelID + 1).to_s, 2, false) +keys[labelID].to_s
				labelID += 1
			end
            print "\n"    
            counter -= increment
        end
        (0...values.length).each{|i| print ((i > 0)? colourise(self.spamCharacter("=", values.length / 2 + padSize) ,@@colourCodes[lineColour]): "\t")}
        print "#{pad}\n#{pad}#{self.spamCharacter(" ",labelPadSize + 2)}"
		i = 1
        keys.each{|key|
			print i < 10 ? " #{i}  " : "  #{i} " 
			i += 1
        }
        puts "\n"
	end
	##
	# Print with fancy = padding
	##
	def self.p name = "Debug", colour = :yellow
		return if @@silentMode
		eqLen = 75 - name.length - 2
		eqStr = self.spamCharacter("=",eqLen)
		puts colourise("\t" + eqStr + "" + name.gsub("\n","\n\t") + " " + eqStr + "\n", @@colourCodes[colour])
	end
	##
	# Print with fancy - padding
	##
	def self.s name = "Debug", colour = :white
		return if @@silentMode
		eqLen = 75 - name.length - 2
		eqStr = self.spamCharacter("-",eqLen)
		puts colourise("\t" + eqStr + "" + name + " " + eqStr, @@colourCodes[colour])
	end
	##
	# Print summary comment
	##
	def self.d value, pad = "->", colour = :blue
		return if @@silentMode
		timer = @@timer ? (Time.now - @@timer).to_s + " seconds: " : ""
		puts timer + colourise( pad + value.to_s, @@colourCodes[colour])
	end
	##
	# Write some info
	##
	def self.info input, padChar="#"
		lines 		= input.strip.split(/\n/).map{|line|
			self.colourise("#{padChar} ", @@colourCodes[:yellow]) + line  
		}
		
		barLength	= lines.sort{|a,b| a.length  <=> b.length }.last.length
		headBar		= "\t" + self.colourise(self.pad(padChar,barLength -7, padChar), @@colourCodes[:yellow])
		puts headBar
		puts lines.map{|line|
			"\t" + self.pad( line, barLength, " ") +
			self.colourise(" #{padChar}", @@colourCodes[:yellow])
		}.join("\n")
		
		puts headBar
	end
	##
	# Track current time for printing
	#
	# NOTE: This is for serial processes only!!!!
	##
	@@timer = false
	def self.startTimer
		@@timer = Time.now
	end
	##
	# Silent mode flagging
	##
	@@silentMode = false
	def self.silentMode= value
		@@silentMode = value
	end
	##
	# Print the time difference between now and the last time startTimer was called
	##
	def self.timeDelta reset=false
		partial = (Time.now - @@timer) / 60.0
		minutes	= partial.to_i
		seconds	= ((partial - minutes) * 60).to_i
		minutes = "0" + minutes.to_s if minutes.to_s.length == 1
		seconds = "0" + seconds.to_s if seconds.to_s.length == 1
		puts "Time: #{minutes}:#{seconds}"
		self.startTimer if reset
	end
end
#################################################
# Shorthand class for LRPrintHelper				#
#################################################
class Lpr < LRPrintHelper	
	
end
