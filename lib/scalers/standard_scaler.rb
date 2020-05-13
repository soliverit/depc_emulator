#################################################################
# 					Scalers										#
#################################################################
class StandardScaler
	
	class MinMaxStruct
		attr_reader :min, :max
		def initialize min, max
			@min	= min
			@max	= max
		end
		def adjust val
			if val < @min
				@min = val 
			elsif val > @max
				@max = val
			end
		end
	end
	## STOLEN FROM RegressionDataSet - Refactor stuff!!!!!!!
	# Normalise a passed value
	#
	# val:		Value to be normalised
	# min:		Minimum value in the value's set
	# max:		Maximum value n the value's set
	#
	# Output:	Normalised value. Float
	##
	def self.normaliseValue val, min, max
		val == 0 ? 0 : (val - min) /( max - min)  
	end
	##
	# Invert normalisation
	#
	# Output:	Inverse of a hopefully normalised value. Numeric
	##
	def self.inverseNormaliseValue val, min, max
		1 - (val - min) / (max - min)
	end
	def initialize baseData
		@data	= baseData.dup
		@featureMinMaxs = @data.first.map{|val| MinMaxStruct.new val, val}
		fit
	end
	def normalise data
		data.map{|entry|
			entry.each_with_index.map{|val, index|
				self.class.normaliseValue val, @featureMinMaxs[index].min, @featureMinMaxs[index].max
			}
		}
	end
	def inverseNormalise data
		data.map{|entry|
			entry.each_with_index.map{|val, index|
				self.class.inverseNormaliseValue val, @featureMinMaxs[index].min, @featureMinMaxs[index].max
			}
		}
	end
	protected
	def fit
		@data.each{|data|
			data.each_with_index{|val, index|
				@featureMinMaxs[index].adjust val
			}
		}
	end
end
