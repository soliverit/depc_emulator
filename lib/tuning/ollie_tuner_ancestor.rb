class TunerAncestor
	attr_reader :model, :results
	def initialize model, results, tunerParamSet, parameterConfig
		@model 			= model
		@results		= results
		@tunerParamSet	= tunerParamSet
		@parameters		= parameterConfig
		@error			= false
	end
	def tunerParameters
		@tunerParamSet.dup
	end
	def rmse
		@error ||= @results.getError
		@error.rmse
	end
	def mutate prob = 0.3
		Hash[@tunerParamSet.map{|tp|[ tp.key, rand < prob ? tp.mutate : @parameters[tp.key]]}]
	end
	def parameterKeys
		@parameters.keys
	end
	def [] key
		@parameters[key]
	end
	def to_s
		cls = @model.class.name
		(cls.length...20).each{ cls += " "}
		
		err = "Error: #{rmse.round 5}"
		(err.length...17).each{ err += " "}
		
		params = "Parameters: #{@parameters.to_json}"
		
		cls + err + params
	end
end