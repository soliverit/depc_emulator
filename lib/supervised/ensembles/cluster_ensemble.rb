require "./lib/unsupervised/kemans_clusterer.rb"
class ClusterEnsemble
	def initialize rgDataSet, modelClass, target, clusterDataSize, trainDataSize
		@modelClass		= modelClass
		@target			= target
		@clusterer		= false
		@clusterColumns	= false
		@models			= {}
		doData rgDataSet, clusterDataSize, trainDataSize
	end
	def trainingData
		@trainingData.clone
	end
	def train columns
		clusterer columns
		##
		# Bind clusters to trainingData
		##
		tData = clusterTagData trainingData
		tData.normalise = true
		##
		# Create training data groups
		##
		groupedTrainingData = tData.groupBy :clusterID
		##
		#
		##
		output = {size:{}}
		groupedTrainingData.each{|key, data|
			output[:size][key] = data.length.to_s
		}
		puts Lpr.hashToTable output
		exit
	end
	def clusterTagData rgDataSet
		@clusterer.predictSet rgDataSet
	end
	protected 
	def doData data, cDataSize, trainDataSize
		clusterSplit 			= data.split(cDataSize)
		@clusterData			= clusterSplit.first	
		@clusterData.normalise 	= true
		trainSplit				= clusterSplit.last.split(trainDataSize)
		@trainingData			= trainSplit.first
		@testData				= trainSplit.last
		@testTargets			= @testData.retrieveFeatureAsArray @target, true
	end
	def clusterer columns
		@clusterColumns			= columns
		@clusterer 				= KMeans.new @clusterData, columns, {auto: 4}
		@clusterer.train
	end
end