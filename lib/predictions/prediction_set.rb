require_relative "../error_information.rb"
#################################################################
# Bordering on a simple struct, this is a set of results from 	#
# whatever regression model predictSet or validateSet call is	#
# made. It stores a set of predictions which if withError		#
# is true, can be interrogated for error rates					#
#################################################################
class PredictionSet
	attr_reader :predictor
	##
	# predictor:	The classifier or regressor that made the predictions
	# withError: 	Does the set require an expected (target) value to be passed to be present
	# 			 	for any Prediction that's destined for the set. Boolean
	#
	# @predictor:	Regressor / multi-classifier or whatever Inheriting OllieMlSupervisedBase
	# @set:			Set of Predictions. Array[Prediction]
	# @withError:	Does the set have error information? Boolean
	# @magnitude:	Factor applied to the data set for fitting or whatever.
	#				Basically, SVR works with integers
	# @lastErrorID:	Sweet cache yo! ID of the last getError request. Integer
	##
	def initialize predictor, withError
		@predictor		= predictor
		@set 			=  []
		@withError		= withError
		@lastErrorId	= nil
	end
	##
	# Push Prediction to the set if it's hasError? is consistent with the @withError property
	#
	# prediction:	A Prediction object
	##
	def push prediction
		if (!@withError || prediction.hasError?)
			
			@set.push prediction 
			@error = false
		end
	end
	##
	# Converto to rgDataSet
	##
	def toRgDataSet
		 rgDataSet = RegressionDataSet.new false, [:prediction]
		 @set.each{|p| rgDataSet.push({prediction: p.prediction})}
		 rgDataSet
	end
	##
	# Return a clone of the Prediction[] set
	#
	# Output:	Array of Prediction objects matching the read-only set
	##
	def set 
		@set
	end
	##
	# Get the number of items in the set
	#
	# Output:	Number of entries in the set - Integer
	##
	def length
		@set.length
	end
	##
	# Get a list of the counters for each difference in 
	# category assigned to a classifier set.
	#
	# asPercentage:	Return results as percentages? Boolean
	#
	# Output:		Hash of the differences as keys and 
	#				a counter for each. Hash[<delta>: Integer]
	#
	# Notes:
	#	- IF for example this had two cats, 0 and 1, at most the
	#	  result would have the keys -1, 0 and 1
	##
	def getClassifierDeltas asPercentage=false
		return unless @predictor.isClassifier?
		output = {}
		@set.each{|prediction|
			key  = prediction.error.to_i.to_s
			output[key] = 0 if ! output[key]
			output[key] += 1
		}
		output.keys.each{|key|output[key] =  (output[key].to_f / length * 100).round(2).to_s + "%"} if asPercentage
		output
	end
	##
	# Get has of classifier category predictions. For example,
	# if the classes were 0 and 1, there'd be keys for both only
	#
	# Output:	Hash of counters
	##
	def getClassifierCounters
		return unless @predictor.isClassifier?
		output = {}
		@set.each{|prediction|
			key  = prediction.prediction.to_i.to_s
			output[key] = 0 if ! output[key]
			output[key] += 1
		}
		output
	end
	##
	# Get classifier category associated counts
	##
	
	##
	# Generate ErrorInformation struct based on the @set
	#
	# Output:	ErrorInformation struct with error aggregated error metrics
	##
	@@defaultHighValue = 9999999
	def getErrors 
		(0...@set.first.predictionCount).map{|index|
			getError(index)
		}
	end
	##
	# Get ErrorInformation for the request prediction ID from each Prediction
	#
	# id:		ID related to the Prediction.predictionSet index, default 0.
	#			Only relevant really for ANNs.
	#
	# Output:	ErrorInformation
	##
	def getError id = 0
		return @error if @error && id = @lastErrorID
		@lastErrorID = id
		rmse 	= 0
		
		simple	= 0
		mae		= 0
		min 	= @@defaultHighValue
		max		= 0
		negMin	= -999999
		negMax	= 0
		absMin	= @@defaultHighValue
		absMax	= 0
		perMin 	=  @@defaultHighValue
		perMax	= 0
		relErr 	= 0
		worstPrediction = @set.first
		bestPrediction	= @set.first
		pass	= @predictor.isClassifier? ?  0 : false
		@set.each{|prediction|
			relErr += prediction.absError.to_f / prediction.expected
			if prediction.absError(id) < absMin	
				absMin 			= prediction.absError(id)
				bestPrediction 	= prediction
			end
			if prediction.absError(id) > absMax	
				absMax 	= prediction.absError(id)
				worstPrediction = prediction
			end
			pass 	+= 1 if pass && prediction.error(id) == 0 
			perMin	= prediction.errorPercent(id) if prediction.errorPercent(id) < perMin
			perMax	= prediction.errorPercent(id) if prediction.errorPercent(id) > perMax
			negMin 	= prediction.error(id) if prediction.error(id) < 0 && prediction.error(id) > negMin
			negMax 	= prediction.error(id) if prediction.error(id) < negMax
			min		= prediction.error(id) if prediction.error(id) > 0 && prediction.error(id) < min
			max		= prediction.error(id) if prediction.error(id) > max
			mae 	+= prediction.absError(id)
			tempErr = prediction.error(id)
			rmse	+= tempErr ** 2
			simple	+= tempErr
		}
		relErr /= @set.length
		simple = 0 if simple == @@defaultHighValue
		fail = @predictor.isClassifier? ? @set.length - pass : false
		@error = ErrorInformation.new id, min, max, negMin, negMax, absMin, absMax, relErr, (rmse / @set.length) ** 0.5, simple / @set.length, mae / @set.length, perMin, perMax, worstPrediction, bestPrediction, pass, fail
	end
	##
	# Print helper. Prints out some generic information about the set
	#
	# Details:
	#	- Prediction model name
	#	- Cardinality of the set
	#	- ErrorInformation print out. (See ErroorInformation class flags)
	##
	def printOut table
		puts "--- Prediction information for (#{@predictor.name}) #{@predictor.isClassifier? ? "Classifier" : "Regressor"} ---"
		puts "No. Predictions:\t#{@set.length}"
		if table
			getError.printTable
		else
			getError.printOut
		end
	end
	##
	# Reduce by rejection
	#
	# Clone and reduce this PredictionSet based on Prediction reject? result
	#
	# Output:	Reduced PredictionSet
	##
	def reduceByRejection
		raise "PredictionSet::ValidateErrorlessSetException" if ! @withError
		output = PredictionSet.new @predictor, true
		@set.each{|prediction|
			output.push prediction if ! prediction.reject?
		}
		output
	end
end
