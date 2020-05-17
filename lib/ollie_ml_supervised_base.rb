require "./lib/ollie_ml_base.rb"
require_relative "./predictions/prediction_set.rb"
require "rumale"
include Rumale
#################################################################
# Generate Linear regression models using generic dataset 		#
# with either standard or gradient descent-based scoring.		#
#																#
# Based on the RubyRubyLinRegression library, this class			#
# provides abstract model generation on any dataset that takes	#
# the user's fancy.												#
#																#
# Supports single independent and multivariate regression.		#
#################################################################
class OllieMlSupervisedBase < OllieMlBase
	##
	# Is the class a neural network
	#
	# Basically, ANN takes nested inputs and produces array outputs which
	# conflicts with every other model's single dim input and output.
	#
	# Output:	Boolean
	##
	def self.isNN?
		false
	end
	##
	# Has named kernels?
	#
	# Output:	Boolean saying it has named kernels
	##
	def self.hasKernels?
		false
	end
	##
	# Select a random kernel if the model supports kernel selection
	#
	# Output:	Random value from whatever the descendant's self.kernels method returns
	#
	# Notes:
	#	- Mostly a silly feature, hasn't been useful but who knows it might be in the future
	##
	def self.randomKernel
		raise "OlliMlModel::#{self.name}::NoKernelSupport" if ! self.hasKernels?
		self.kernels.sort{|a, b| Random.rand <=> Random.rand}.first
	end
	##
	# Does the model have SVM types: (to be overridden)
	#
	# Output:	Boolean
	#
	# Notes:
	# - As with everything else, this is probably overkill. It just means that 
	#	any ambitious *algorithmic* (read random guessing) doesn't throw a fit 
	#	if you're telling a method to just try anything and everything.
	##
	def self.hasSVMType?
		false
	end
	##
	# Does the ML model training method expected the target to be present
	# in the training data with a Symbol passed as the target identifier
	# or does it expect an array of targets
	#
	# Currently only relevant for EpsRegressor
	#
	# Output:	Boolean
	##
	def self.useTargetKey?
		false
	end
	##
	# Base initialize
	#
	# @data:			All data as RegressionDataSet including target
	# @traiingTarget:	Symbol of the feature to be estimated
	# @parameters:		Hash of parameters wit instance.setParameters expected
	#					to be overridden based on the model type. SVM for example's
	#					setParameters uses respond_to? and iteration over keys 
	#					on the Libsvm::Parameter object
	##
	def initialize data, target, parameters
		super data, parameters
		@target	= target
		if ! self.class.isNN?
			trainMinValue
			trainMaxValue
		end
		@normaliser	= Preprocessing::MinMaxScaler.new(feature_range: [0.0, 1.0])
		@normaliser.fit(@trainingData.segregate(features).data)
	end
	##
	# Normalise a 2D array 
	##
	def normaliseSet data
		@normaliser.transform(data).to_a
	end
	##
	# Normalise
	##
	def normalise inputs
		normaliseSet([inputs])
	end
	def trainingTargets
		@trainingData.retrieveFeatureAsArray(@target)
	end
	def trainingData
		data 		= @trainingData.segregate(features).data
		unless @parameters[:SKIP_NORMALISE]
			normaliseSet(data)
		else
			data
		end
	end
	def trainingTargets
		data.retrieveFeatureAsArray(@target)
	end
	# TrainingDataAsArray
	#
	# Output:	Array of training data
	##
	def trainingDataAsArray
		data.retrieveFeatureAsArray(@target)
	end
	##
	# Make a prediction for a set of input records and return a pretty redundant (non validated) prediction set
	#
	# inputs:	A set of test records containing individual feature arrays. Array[Array[N-features]]
	#
	# Output:	A PredictionSet with no expectations tracked, can't check error rates
	##
	def predictSet inputs
		isTrained?
		inputs = getFeatureData inputs
		predictionSet = PredictionSet.new self, false
		inputs.getDataStructure(useHash).each_with_index{|input, index|
			inputSets = inputToPredictTrackSplit input
			inputTrack	= useHash ? inputs.hashedData[index] : inputs.data[index]
			predictionSet.push Prediction.new(inputTrack, predict(inputSets[1]))
		}
		predictionSet
	end
	##
	# Make a prediction for a set of input records and return an epic prediction set (validating)
	#
	# inputs:		A set of test records containing individual feature arrays. Array[Array[N-features]]
	# expectations:	The target values for the inputs sorted as per the inputs
	#
	# Output:		A PredictionSet capable of having error rates extracted
	##
	def validateSet inputs, expectations, predictionClass
		isTrained?
		inputs = getFeatureData inputs
		predictionSet = PredictionSet.new self, true
		inputs.getDataStructure(useHash).each_with_index{|input, index|
			inputSets = inputToPredictTrackSplit input
			prediction =  predict(inputSets[1])
			predictionSet.push predictionClass.new(inputSets[0], prediction,expectations[index])
		}
		predictionSet
	end
	##
	# Clone input data into an array with two sub arrays of the inputs. One for actual prediction and
	# another for the prediction set.
	#
	# input:	Any single dimension array, really
	#
	# Output:	Array with two clones of the input array
	#
	# Notes:
	#	- RubyRubyLinRegression does in-place normalisation on inputs 
	##
	def inputToPredictTrackSplit input
		if useHash
			output = [{},{}]
			input.each{|key, val| 
				output[0][key] = val
				output[1][key] = translateFeatureValue val
			}
		else 
			output = [[],[]]
			input.each{|i|
				output[0].push i
				output[1].push translateFeatureValue i
			}
		end
		output[1] = translateFeatureInput output[1]
		output
	end
	##
	# Translate an input Array or Hash. Placeholder method
	#
	# Output:	Return modified version of the input. Pass, anything
	##
	def translateFeatureInput input
		input
	end
	##
	# Translate and predict 
	#
	# Output:	Prediction, presumably numeric or Array if it's an ANN
	##
	def translateAndPredict input
		predict(translateFeatureInput input)
	end
	##
	# Placeholder for translating value to a feature. Mostly
	# for libSVM
	#
	# value:	Input value, typically a number. Variant
	#
	# Output:	Translated value
	##
	def translateFeatureValue value
		value
	end
	def doPermutationImportance data, targets, predictionClass
		output = {RMSE: {}, MAE: {}}
		base	= false
		[false, data.features].flatten.each{|feature|
			if feature
				backupFeature	= data.segregate [feature]
				data.shuffleFeatures [feature]
				
			end
			results 				= validateSet(data, targets, predictionClass).getError
			output[:RMSE][feature]	= results.rmse
			output[:MAE][feature]	= results.mae
			# Resotre feature on dataset
			data.dropFeatures [feature]
			if feature
				data << backupFeature
			else
				base = results.rmse
			end
			puts output[:RMSE][feature].to_s + "\t " + feature.to_s + "\t" + (results.rmse - base).to_s
		}
		output
	end
end
