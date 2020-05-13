require_relative "./machine_set.rb"
class SupervisedEnsembleBase
	def initialize rgDataSet, target, machineClass, parameters
		@data			= rgDataSet
		@target			= target
		@parameters		= parameters
		@machineClass	= machineClass
		doData
	end
	protected
	def doData
		tempSplit 		= @data.split(0.4)
		@trainingData	= tempSplit.first
		@testData		= tempSplit.last
		@testTargets	= @testData.retrieveFeatureAsArray @target, true
	end
end