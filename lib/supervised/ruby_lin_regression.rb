##
# Includes
##
## Native ##
require "ruby_linear_regression"
## Library ##
require "./lib/ollie_ml_supervised_base.rb"
#################################################################
# Linear Regression using the standard equation or gradient		#
# descent.														# 
#																#
# SEE OPENING NOTES: Covers the stuff, the Base class just 		#
# contains the generics. LibLinLogisticRegressor for 			#
# classification problems.										#
#																#
# Wrapper for the ruby_linear_regression gem					#
#################################################################
class RubyLinRegression < OllieMlSupervisedBase
	attr_accessor :silentMode
	attr_reader :trained, :gradientModel
	@@defaultGDIterations 	= 100
	@@defaultGDLearnRate	= 0.0005
	##
	# Set default number of iterations for Gradient Descent training
	#
	# val:		Hopefully am Integer, otherwise don't set
	##
	def self.defaultGDIterations= val
		@@defaultGDIterations = val if val.class == Integer
	end
	##
	# Set default gradient descent learn rate
	#
	# val:		Hopefully numeric, otherwise don't set
	##
	def self.defaultGDLearnRate= val
		@@defaultGDLearnRate = val if val.to_f.class == Float && val < 1
	end
	##
	# xData:			Training input feature set. Array[Array[N-Features]]
	# yData:			Training targets. Array[Numeric]
	# parameters:		Hash of parameters, hopefully ones relevant to GD or standard models
	#
	# @trainingInputs:	Training data. Array[Array[N-Features]]
	# @targets:	Training target values. Array[Numeric] - same size as @trainingInputs
	# @silentMode:		The flag...
	# @trained:			Is there an existing trained emulator of any type for this instance? Boolean
	# @gradientModel:	Is the currently trained emulator gradient descent or standard (if anything). Boolean
	#
	# @lr:				RubyRubyLinRegression instance
	# @learningRate:	Learning rate for gradient descent models
	# @iterations:		No. of steps taken revising looking for a model
	##
	def initialize data, target, parameters
		super(data, target, parameters)
		@silentMode			= !(parameters[:silentMode] || false)
		@gradientModel		= parameters[:gradientDescent] || false
		newRegressor
	end
	##
	# Train model
	##
	def train
		@gradientModel ? trainAsGradientDescent : trainAsStandardRegressor
	end
	##
	# Train either GD or standard based on input parameters
	##
	##
	# OVERRIDDEN!
	# Describe the hyperparameters of the model
	#
	# Output:	Description of the mode. String
	##
	def describeHyperparameters
		if @gradientModel
			"Gradient descent: Learn rate: #{@learningRate} Steps: #{@iterations}"
		else
			"Standard equation"
		end	
	end
	##
	# Set silent mode
	#
	# silent:	True or false for whether silent mode should be on. Boolean
	##
	def silentMode mode
		@silentMode = !mode
	end
	##
	# Completely replace the existing regression model instance
	##
	def newRegressor
		@trained		= false
		@lr 			= RubyLinearRegression.new
		@lr.load_training_data trainingData, trainingTargets
	end
	##
	# Determine if it actual found a working model (is converged the right word here?)
	#
	# SERIOUSLY! I have no idea, a loss function I think - lower is better though!
	##
	def cost
		@lr.compute_cost.class != NaN
	end
	##
	# Train model gradient descent model
	#
	# lRate: 		Learning rate, how long it *wastes* per iteration or something. Inversely proportional to model quality
	# iterations:	Number of steps taken revising the model. 
	#
	# Notes:
	#	- Will only train a new model if the hyperparameters are different from the previous model or if
	#	  the current model is a standard equation.
	##
	def trainAsGradientDescent
		lRate 				= @parameters[:lRate] || @@defaultGDLearnRate 
		iterations			= @parameters[:iterations] || @@defaultGDIterations
		#Skip identical train
		return if @trained && @gradientModel && @learningRate == lRate && @iterations == iterations
		#Set hyperparameters
		@learningRate 		= lRate
		@iterations			= iterations
		#Train Gradient Descent
		@lr.train_gradient_descent @learningRate, @iterations, @silentMode
		#Train flags update
		@trained 			= true
		@gradientModel		= true
	end
	##
	# Train a standard linear equation model. Nothing fancy, quick and probably fun at parties
	##
	def trainAsStandardRegressor
		return if @trained && @gradientModel == false
		#Train standard regressor
		#FIRE!
		@lr.train_normal_equation
		#Train flags update
		@train				= true
		@gradientModel		= false
	end
end
