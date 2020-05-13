##
# Includes
##
## Native ##
require "liblinear"
## Library ##
require "./lib/ollie_ml_supervised_base.rb"
#################################################################
# Multi-model classifier and regression model handler			#
#																#
# Probably the most ambitious of the OllieMlSupervisedBase 		#
# descendants. Provides model generation for:					#
#	- Logistic													#
#	- Classification											#
#	- Regression												#
#																#
# In most cases it uses some form of SupportVector,				#
# yep, I have no idea what that means but pretty cool all the	#
# same.															#
#																#
# TODO:															#
#	- See if Colin will explain what I've actually done!		#
#################################################################
class LibLinLogisticRegressor < OllieMlSupervisedBase
	attr_reader :kernelName
	### Classifiers (7), Regressors(3) ####
	@@kernels = [
		# for multi-class classification
		"L2R_LR",		      	# L2-regularized logistic regression (primal)
		"L2R_L2LOSS_SVC_DUAL", 	# L2-regularized L2-loss support vector classification (dual)
		"L2R_L2LOSS_SVC" ,     	# L2-regularized L2-loss support vector classification (primal)
		"L2R_L1LOSS_SVC_DUAL", 	# L2-regularized L1-loss support vector classification (dual)
		"MCSVM_CS",            	# support vector classification by Crammer and Singer
		"L1R_L2LOSS_SVC",      	# L1-regularized L2-loss support vector classification
		#Logistic regression
		"L1R_LR",              	# L1-regularized logistic regression
		"L2R_LR_DUAL",    	   	# L2-regularized logistic regression (dual)
		#Linear regressoin using SVR
		"L2R_L2LOSS_SVR",      	# L2-regularized L2-loss support vector regression (primal)
		"L2R_L2LOSS_SVR_DUAL", 	# L2-regularized L2-loss support vector regression (dual)
		"L2R_L1LOSS_SVR_DUAL"  	# L2-regularized L1-loss support vector regression (dual)
	
	]
	@@regressionKernels = [
		"L2R_L2LOSS_SVR",      	# L2-regularized L2-loss support vector regression (primal)
		"L2R_L2LOSS_SVR_DUAL",	# L2-regularized L2-loss support vector regression (dual)
		"L2R_L1LOSS_SVR_DUAL" 	# L2-regularized L1-loss support vector regression (dual)
	]
	@@logisticKernels = [
		"L1R_LR",              	# L1-regularized logistic regression
		"L2R_LR_DUAL"     		# L2-regularized logistic regression (dual)
	]
	@@classifierKernels = [
		"L2R_LR",		       	# L2-regularized logistic regression (primal)
		"L2R_L2LOSS_SVC_DUAL", 	# L2-regularized L2-loss support vector classification (dual)
		"L2R_L2LOSS_SVC" ,     	# L2-regularized L2-loss support vector classification (primal)
		"L2R_L1LOSS_SVC_DUAL", 	# L2-regularized L1-loss support vector classification (dual)
		"MCSVM_CS",            	# support vector classification by Crammer and Singer
		"L1R_L2LOSS_SVC"     	# L1-regularized L2-loss support vector classification
	]
	##
	# Turn epoch reporting on or off 
	#
	# val:	Boolean for on or off
	##
	def self.quiteMode val
		if val 
			Liblinear.quiet_mode
		else
			Liblinear.verbos_mode
		end
	end
	##
	# Get list of Logistic regresion kernel names
	#
	# Output:	Array of String kernel names
	##
	def self.logisticKernels
		@@logisticKernels.map{|k| k}
	end
	##
	# Get list of classifier regresion kernel names
	#
	# Output:	Array of String kernel names
	##
	def self.classifierKernels
		@@classifierKernels.map{|k| k}
	end
	##
	# Get list of Linear regresion kernel names
	#
	# Output:	Array of String kernel names
	##
	def self.svrKernels
		@@regressionKernels.map{|k| k}
	end
	##
	# OVERRIDDEN!
	# Has named kernels?
	#
	# Output:	Boolean saying it has named kernels
	##
	def self.hasKernels?
		true
	end
	##
	# OVERRIDDEN!
	# Return a description of the Kernel and/or hyper parameters
	#
	# Output: String supplementary description of the model. String
	##
	def describeHyperparameters
		"Kernel: #{kernel}"
	end
	##
	# OVERRIDDEN!
	# Return notification that this does not use the data Hash when dealing
	# with RegressionDataSets.
	#
	# Output: True or false on whether it uses Hash or Array. Boolean
	##
	def useHash
		false
	end
	##
	# Return safe array of Kernel names. Array[String]
	#
	# Output:	Array of Kernel names, both logistic and linear. Array[String]
	##
	def self.kernels
		@@kernels.map{|k| k}
	end
	##
	# Find the Kernel ENUM ID for the passed String.
	#
	# Output:	The ENUM ID value for the passed string. Integer
	#
	# Notes:
	#	- Relies on explicit sorting in both Logistic and Linear Kernel Arrays
	##
	def self.findKernel str
		@@kernels.find_index str  
	end
	##
	# Class-level is Kernel a classifier
	#
	# Output:	True or false of whether it's a classifier. Boolean
	##
	def self.isClassifier? name
		@@classifierKernels.include? name
	end
	##
	# Is th named kernel a logistic regressor?
	#
	# name:		Kernel name, hopefully in one of the sets
	#
	# Output:	Boolean
	##
	def self.isLogistic? name
		@@logisticKernels.include? name
	end
	def self.isRegressor? name
		@@regressionKernels.include? name
	end
	##
	# OVERRIDDEN!
	# Return if a classifier (Logistic set) model is selected
	#
	# Output:	True or false on whether it's a classifier/logistic model. Boolean
	##
	def isClassifier?
		self.class.isClassifier? @kernelName
	end
	##
	# Return kernel name (possibly redundant
	#
	# Output:	Kernel name
	##
	def kernel
		@@kernels[@kernel]
	end
	##
	# Choose multi-classification or regression kernel
	#
	# @kernel:	Essentially an ENUM integer 0 - 13 representing 
	#			something from @@kernels
	#
	# Notes:
	#	- Has to retrain the model after changing for obvious reasons
	##
	def setKernel kernel
		@kernelName	= kernel
		@kernel 	= self.class.findKernel(kernel) 
		train
	end
	##
	# xData:	Training RegressionDataSet, not target included
	# yData:	Targets. Array[Integer]
	# kernel:	ENUM ID for the kernel, default to Liblinear::L2R_LR
	#
	# @kernel:	Kernel enumerated ID. Integer
	# Notes:
	#	- See LiinearRegressionBase for instance variable definitions
	#
	# TODO:
	#	- Change kernel input to String lookup for actual 
	##
	def initialize xData, target, parameters
		super(xData, target, parameters)
		setKernel @parameters[:kernel_type]
	end
	##
	# Train the model using the selected kernel
	##
	def train
		#Do data splitting
		data = trainingData
		trainData	= data.segregate trainingDataAsArray, true
		@lr	= Liblinear.train(
			{solver_type: self.class.findKernel(@kernel) },
			trainingData.getDataStructure(useHash)
		)
	end
	##
	# OVERRIDDEN!
	# Make prediction
	#
	# input:	Array of features of N-Features in the @trainingData
	#
	# Output:	Integer or Decimal depending on whether this is a
	#			classifier, linear regressor or NN 
	##
	def predict input
		Liblinear.predict(@lr, input)
	end
end
