require_relative "./prediction.rb"
#################################################################
# Struct representing a prediction from any given (unknown)		#
# regression model or whatever you plug this into.				#
#################################################################
class ClassifierPrediction < Prediction
	##
	# Get error percentage by ID
	#
	# id:		prediction ID for individual output from @machine
	#
	# Output:	Numeric . Percentage as Float
	##
	def errorPercent id = 0
		@expected == prediction(id) ? 0 : 100.0
	end
end
