

####
# Utilities class (Static)
###
class OllieUtilities
	def self.trainTestAndPrintError modelClass, trainData, testData, testTargets, target, parameters = {}
		model 			= modelClass.new trainData, target, parameters
		puts model.describeHyperparameters
		model.train
		predictionSet 	= model.validateSet testData, testTargets, Prediction
		results			= predictionSet.getError
		results.printOut 
	end
end
