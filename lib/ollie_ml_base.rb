
#################################################################
# Base class for all models										#
#################################################################
class OllieMlBase
	##
	# @trainingData:	RegressionDataSet for training
	# @parameters:		Hash of params for the model. Set
	#					in setParameters.
	##
	def initialize data, parameters
		@trainingData	= data
		@parameters		= parameters.dup
		setParameters parameters
	end
	##
	# Set parameters for the model, class or whatever. To be overridden
	##
	def setParameters parameters
		@parameters		= parameters.dup
	end
	##
	# All descendants must flag either use a Hash or Array from the training data RegressionDataSet
	#
	# Declare this in the inheriting class to overwrite
	#
	# Output:	Boolean
	#
	# Notes:
	#	- Yep, it's an instance method. Too late to turn back now!
	##
	def useHash 
		false
	end
	##
	# Generate a name for the regressor / classifier / NN
	#
	# Output:	String name for the model
	##
	def name
		self.class.to_s + " (" + describeHyperparameters + ")"
	end
	##
	# Described the hyper parameters if any 
	#
	# Output:	String
	##
	def describeHyperparameters
		"No notable hyper param info"
	end
	##
	# Is this a classifier?
	#
	# Output: Boolean of whether this is a classifier or not. Boolean
	##
	def isClassifier?
		false
	end
	##
	# Is trained?
	#
	# Raise an exception if the model hasn't been trained
	##
	def isTrained?
		raise "OllieMlSupervisedBase::#{self.class}::ModelNotTrainedException" if ! @lr
	end
	
	##
	# Make a prediction for a single record
	#
	# input:	Single record of features Array[N-features]
	#
	# Output:	Single decimal prediction
	##
	def predict input
		@lr.predict input
	end
	##
	# Predict from an array
	##
	def predictSet rgDataSet
		output = PredictionSet.new self, false		
		rgDataSet.data.each{|entry|
			output.push(Prediction.new(entry, predict([entry])))
		}
		output
	end
	##
	# Training minimum value
	##
	def trainMinValue
		return @trainingMinValue if @trainingMinValue
		@trainingMinValue = 9999999
		trainingDataAsArray.each{|data|
			
			@trainingMinValue = data if data < @trainingMinValue
		}
		@trainingMinValue
	end
	##
	# Training max value
	##
	def trainMaxValue
		return @trainMaxValue if @trainMaxValue
		@trainMaxValue = -999999999
		trainingDataAsArray.each{|data|
			@trainMaxValue = data if data > @trainMaxValue
		}
		@trainMaxValue
	end
	def data
		@trainingData.clone
	end
	##
	# Get training data
	#
	# Output:	RegressionDataSet without the target feature
	##
	def trainingData
		newData = data.clone
		newData.dropFeatures [@target]
		newData
	end
	##
	# Get test data
	#
	# Output:	RegressionDataSet containing only the target feature
	##
	def trainingTarget
		newData = data.segregate([@target])
	end
	##
	# 
	##
	def features
		@trainingData.features.select{|feature| feature if feature != @target}
	end
	def getFeatureData rgDataSet
		rgDataSet.segregate features
	end
	def validateSet
		throw "OllieMlBase::MethodNotDefined - validateSet not defined"
	end
	def predictSet
		raise "OllieMlBase::MethodNotDefined - predictSet not defined"
	end
end
