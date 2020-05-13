##
# Includes
##
## Native ##
require "libsvm"
## Library ##
require "./lib/ollie_ml_supervised_base.rb"
#################################################################
# Support vector machine 										#
#																#
# As always, no idea what it is, something to do with hyper 	#
# planes. Best model in the library, currently, though not a 	#
# classifier.													#
#################################################################
class LibSvmRegressor < OllieMlSupervisedBase
	cattr_accessor :greedyTrain
	@@defaultParameters = {
		c:			15,
		eps:		0.005,
		cache_size: 20
	}
	@@greedyTrain = true
	@@kernels = [
		"C-SVC",
		"nu-SVC",
		"linear: u'*v",
		"polynomial: (gamma*u'*v + coef0)^degree",
		"radial basis function: exp(-gamma*|u-v|^2)",
		"sigmoid: tanh(gamma*u'*v + coef0)"
	]
	@@svmTypes = [
		"nu-SVR",
		"one-class SVM",
		"epsilon-SVR"
	]
	@@svmClassifierTypes = [
		"C-SVC",
		"nu-SVC",
	]
	def svmClassifierTypes
		@@svmClassifierTypes.dup
	end
	##
	# OVERRIDDEN!
	#
	# Finally, an SVM to use this joke of a method... Let the user know
	# they're playing with an SVM model
	#
	# Output:	True
	## 
	def self.hasSVMType?
		true
	end
	##
	# OVERRIDDEN!
	#
	# Output:	True
	##
	def self.hasKernels?
		true
	end
	##
	# List normal kernel names
	#
	# Output:	Array of kernel names supported by this model
	##
	def self.kernels
		@@kernels.map{|k| k}
	end
	##
	# List SVM model types
	#
	# Output:	Array of SVM model type names
	##
	def self.svmTypes
		@@svmTypes.dup
	end
	##
	# Retrieve kernel ID by name
	#
	# Output:	Kernel ENUM ID, default C-SVC
	##
	def self.kernelIDFromName kernel
		@@kernels.find_index(kernel) || 0
	end
	##
	# Retrieve SVM type by name
	#
	# Output:	SVM type ENUM ID, default "one-class SVM"
	##
	def self.svmIDFromName svmType
		@@svmTypes.find_index(svmType) || 0
	end
	##
	# OVERRIDDEN!
	# Used to tell @trainingData to use its @data Array
	##
	def useHash
		false
	end
	##
	# Retrieve the ID of the kernel of this instance
	#
	# Output:	Kernel ENUM ID, default C-SVC if not found
	##
	def kernel
		self.class.kernelIDFromName @kernel
	end
	##
	# Retrieve the ID of the SVM type of this instance
	#
	# Output:	SVM type ENUM ID, default one-class-SVM
	##
	def svmType 
		self.class.svmIDFromName @svmType
	end
	##
	# OVERRIDDEN!
	# Describe the hyper parameters
	#
	# Output:	String of hyperparameters
	##
	def describeHyperparameters
		@parameters.to_json.gsub("\{\}\"","") + " - kernel: #{@kernel}"
	end
	##
	# data:			Training data. RegressionDataSet
	# target:			Training targets. Feature name as Symbol
	# parameters:		Parameters for the model either class or hyper params
	#
	# @grreedyTrain:	Always train after @parameters update. Boolean
	# @parameters:		Libsvm::Parameter
	# @trainingData:	Training data. RegressionDataSet
	# @targets:	Training targets. Array[Integer]
	# @paramStore:		Parameters hash as @parameters values
	# @problem:			Libsvm::Problem
	# @lr:				Libsvm::Model
	##
	def initialize data, target,parameters
		super(data, target, parameters)
		@@defaultParameters.each{|key, value| @parameters[key] ||= value}
		@svmParameters				= Libsvm::SvmParameter.new
		# Temp turn off greedy train if it's meant to go on
		@parameters[:kernel_type]	= self.class.kernelIDFromName @parameters[:kernel_type]
		@parameters[:svm_type]		= self.class.svmIDFromName @parameters[:svm_type]
		# Set with defaults first, then override or whatever
		setParameters @parameters
	end
	##
	# Train an SVM 
	##
	def train
		return if @lr
		@problem			= Libsvm::Problem.new
		@problem.set_examples(data.retrieveFeatureAsArray(@target), getTrainingData)
		@lr 				= Libsvm::Model.train(@problem, @svmParameters)
	end
	##
	# Set the parameters for the model
	#
	# params:	Parameter Hash. See @@defaultParameters
	#
	# Notes:
	#	- IF params is false then use @@defaultParameters
	#	- IF @greedyTrain is true then retrain the model
	##
	def setParameters params = false
		params = @@defaultParameters.dup unless params
		params.keys.each{|key|
			if @svmParameters.respond_to?(key)
				@svmParameters.send("#{key}=", params[key])
				@parameters[key] = params[key]
			end
		}
	end
	##
	# Get training data as an Array of Libsvm::Node.features
	#
	# Output:	Array of feature objects. Array[Libsvm::Node.features]
	#
	# Notes:
	#	- Essentially double data handling with trainingData.getDataStructure but
	#	  it keeps it consistent
	#
	# TODO:
	#	- Consider dealing with the noted concern
	#
	##
	def getTrainingData
		trainingData.map{|data| Libsvm::Node.features(data)}
	end
	##
	# OVERRIDDEN!
	# Translate the input Array or Hash into features
	#
	# input:	Default an Array but could be Hash
	#
	# Output:	Libsvm::Node.features
	##
	def translateFeatureInput input
		Libsvm::Node.features(input)
	end
end
