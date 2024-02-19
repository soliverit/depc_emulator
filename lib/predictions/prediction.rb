#################################################################
# Struct representing a prediction from any given (unknown)		#
# regression model or whatever you plug this into.				#
#################################################################
class Prediction
	attr_reader :expected, :prediction, :machine
	##
	# input:		Features used in the prediction: Array[N-Features of associated model]
	# prediction:	The predicted value from the emulator
	# expected:		The target value for the prediction. Numeric - default nil
	#
	# Properties:
	#	@input:			Features array used by the emulator for the prediction
	#	@predictionSet:	Set of errors if delivered as prediction from say, Fast-ANN
	#
	# Notes:
	#	- Doesn't require an expected value however, errors obviously can't be determined
	#	  one
	#
	# Super Note:
	#	- @predictionSet replaced @prediction such that multi-prediction results from ANNs
	#	  can be accommodated. So, all the properties have been replaced with accessors which
	#	  can take an ID.
	##
	def initialize input, prediction, expected = nil, machine = false
		@predictionSet	= prediction.class == Array ? prediction : [prediction]
		@input 			= input
		@expected		= expected
		@machine		= machine
	end
	##
	# Retrieve a copy of the predictions. Note: exists to accommodated
	# FastANN's array output predictions
	#
	# Output:	Array of outputs, could be any value I think...
	##
	def predictionSet
		@predictionSet.dup
	end
	##
	# Get a prediction by ID
	#
	# id:		Prediction ID. Integer
	#
	# Output:	Prediction 
	##
	def prediction id = 0
		@predictionSet[id]
	end
	##
	# Get error distance by ID
	#
	# id:		prediction ID for individual output from @machine
	#
	# Output:	Numeric error. Real number
	##
	def error id = 0
		@predictionSet[id] - @expected
	end
	##
	# Get absolute error distance by ID
	#
	# id:		prediction ID for individual output from @machine
	#
	# Output:	Numeric error. Positive float
	##
	def absError id = 0
		error(id) < 0 ? error(id) * -1 : error(id)
	end
	##
	# Get error percentage by ID
	#
	# id:		prediction ID for individual output from @machine
	#
	# Output:	Numeric . Percentage as Float
	##
	def errorPercent id = 0
		(error(id) < 0 ? -1 : 1) * (100 - (@expected / prediction(id) * 100))
	end
	##
	# Get the squared error (residual square)
	#
	# id:		prediction ID for individual output from @machine
	#
	# Output:	Numeric . errror ^ 2
	##
	def errorSquared id = 0
		error(id) ** 2
	end
	##
	# How many predictions are there?
	#
	# Output:	Number of predictions in the prediction set.
	#
	##
	def predictionCount
		@predictionSet.length
	end
	##
	#
	##
	##
	# Return safe clone of the input features associated with Prediction
	#
	# Output:	Array of features used by the emulator to make the prediction. Numeric from R
	##
	def input
		@input.map{|i| i}	
	end
	##
	# Let the requester known, through the power of Boolean... err, return if the error value is set
	#
	# Output:	If the error is set. Boolean
	##
	def hasError?
		@expected != nil
	end
	##
	# Print out helper. Prints @input feature set
	##
	def printInputs
		if @input.class == Hash
			
			@input.each{|key, value|
				keyStr = key.to_s + ":" 
				while keyStr.length < 15
					keyStr << " "
				end
				puts "\t#{keyStr}#{value}"
			}
		else
			puts @input.to_json
		end
	end
	##
	# Print helper, prints out Expected, Prediction and Error values
	##
	def printOut
		if hasError?
			puts "Actual: #{@expected.round(3)}\t#{@prediction.round(3)}\t#{@error.round(3)}"
		end
	end
	##
	# Reject Prediction: To be overridden!
	#
	# A method for returning a set of Predictions whose contents with known critical
	# failures are rejected, leaving only those which are less than critically wrong.
	#
	# For example, DomainRejectionPredictions fail critically if their expected value
	# is not within the expected domain.
	##
	def reject?
		false
	end
end
