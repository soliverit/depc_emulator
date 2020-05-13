class TunerLeaderBoard
	def initialize scorer
		@set 	= []
		@dead	= []
		@scorer	= scorer
	end
	def include? parameterSet
		@set.each{|ancestor|
			return true if ancestor.parameterKeys.length == parameterSet.keys.length && ancestor.parameterKeys.count{|key| ancestor[key] == parameterSet[key]} == parameterSet.keys.length
		}
		@dead.each{|ancestor|
			return true if ancestor.parameterKeys.length == parameterSet.keys.length && ancestor.parameterKeys.count{|key| ancestor[key] == parameterSet[key]} == parameterSet.keys.length
		}
		false
	end
	def betterThanAny? otherAncestor
		@set.each{|ancestor| return false if otherAncestor.rmse > ancestor.rmse}
		true
	end
	def reduceByTournament survivors
		@set = @set.sort_by(&@scorer).each_with_index.map{|survivor, idx|
			if idx < survivors
				survivor
			else
				@dead.push survivor
				nil
			end
		}.compact
	end
	def [] id
		@set[id]
	end
	def each 
		@set.each{|ancestor| yield ancestor}
	end
	def map 
		@set.map{|ancestor| yield ancestor}
	end
	def push tunerOutcome
		@set.push tunerOutcome
	end
	def listError
		@set.each{|val|
			puts val.to_s
		}
	end
end