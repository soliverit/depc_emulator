require "rumale"
# require "svmkit"
include Rumale
require "./lib/ollie_ml_supervised_base.rb"
class KNN < OllieMlSupervisedBase
	DEFAULT_PARAMETERS	= {n_neighbors: 5}
	def initialize data, target, parameters
		super data, target, parameters
		DEFAULT_PARAMETERS.each{|key, value| @parameters[key] = value if ! @parameters[key]}
	end
	def normaliseSet data
		@normaliser.transform(data)
	end
	def train 
		@lr			= NearestNeighbors::KNeighborsClassifier.new(DEFAULT_PARAMETERS)
		@lr.fit trainingData, @trainingData.retrieveFeatureAsArray(@target)
	end
	def predict inputs
		inputs.map!{|input| input if input}.compact!
		@lr.predict(@normaliser.transform([inputs]))[0]
	end
	def getFeatureData rgDataSet
		rgDataSet
	end
end