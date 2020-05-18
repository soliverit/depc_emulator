class DEPCProject
	attr_reader :regressor, :classifier, :clusterer
	CLASSIFIER_TARGET	= :ERROR
	class DEPCPrediction
		attr_reader :target, :full, :keep, :throw
		def initialize rgDataSet, target
			@target		= target
			@full		= rgDataSet
			
			grouped		= @full.groupByFunction{|data| data[@target] == 0? :keep : :throw}
			@keep		= grouped[:keep]
			@throw		= grouped[:throw]
		end
		def printHashTable
			Lpr.hashToTable({
				RMSE: {
					keep: 	@keep.rmse,
					throw:	@throw.rmse
				},
				R2: {
					keep: 	@keep.r2,
					throw: 	@throw.r2
				}
			})
		end
	end
	def initialize rgDataSet, target, isClassifier = false, clustererFeatures=false
		if isClassifier
			@target 			= target
			@isClassifier		= isClassifier
			@clustererFeatures	= clustererFeatures
			if @isClassifier && ! @clustererFeatures
				raise "#{self.class.name}::Undefined cluster feature for classifying project" 		
			end
			
			# Do data
			splitData 			= rgDataSet.partition 2
			# splitData 			= rgDataSet.partition 3
			@fullData			= rgDataSet
			@regTrainData		= splitData.first
			@classifierData		= splitData.last
			train
		else
		end
	end
	def train
		return if @regresssor
		trainRegressor
		if @isClassifier
			trainClusterer
			trainClassifier
		end
	end
	def trainRegressor
		return if @regressor
		Lpr.d "#{self.class.name} Train Regressor"
		@regressor	= EPSRegressor.new @regTrainData, @target, {}
		@regressor.train
	end
	def clusterer
		return @clusterer if @cluserter	
		trainClassifier
		@clusterer
	end
	def trainClusterer
		return if @clusterer
		Lpr.d "#{self.class.name} Train clusterer"
		@clusterer 		= KMeans.new @fullData.segregate(@clustererFeatures), {}
		@clusterer.train
		
		@clusteredData 	= @clusterer.predictSet(@fullData).groupBy(:clusterID)
		@clusterMachines= Hash[@clusteredData.each.map{|key, cData| 
			cData.dropFeatures [:clusterID]
			reg	=EPSRegressor.new(cData, @target, {})
			reg.train
			[key, reg]
		}]
	end
	def trainClassifier
		return if ! @isClassifier || @classifier
		trainRegressor
		Lpr.d "#{self.class.name} Train classifier"
		classifierTargets	= @classifierData.segregate([@target], true)
		regPredictions		= @regressor.validateSet(@classifierData, classifierTargets.retrieveFeatureAsArray(@target), Prediction)
		@classifierData		<< regPredictions.toRgDataSet
		@classifierData 	<< classifierTargets
		@classifierData.injectFeatureByFunction(CLASSIFIER_TARGET){|data| (data[:prediction] - data[@target]).abs > 3 ? 1 : 0}
		@classifierData.dropFeatures [@target, :prediction]
		
		@classifier			= KNN.new @classifierData.clone, CLASSIFIER_TARGET, {}
		
		@classifierData << classifierTargets
		@classifier.train
	end
	##
	# entry:		Hash with @clustererFeatures
	##
	cattr_accessor :shoe
	def predict entry
		rgDataSet			= RegressionDataSet.new [entry], false
		# If it's a classifying model then train a new machine if needed
		if @isClassifier
			# Classify the likelihood of needing a bespoke machine
			classifierResult	= ClassifierPrediction.new entry, @classifier.predict(@classifier.features.map{|feature| entry[feature]}), false, @classifier
			# Check if it needs a bespoke machine
			if classifierResult.prediction == 1
				# Find training data cluster id
				result 	= clusterer.predict([rgDataSet.segregate(@clustererFeatures).data.first])
				index	= -1
				# kData	= @clusteredData[result.first.to_s.to_sym]
				# machine	= EPSRegressor.new kData, @target, {clusters:4}
				# machine.train
				@@shoe = true
				return Prediction.new entry, @clusterMachines[result.first.to_s.to_sym].predict(entry), false, @clusterMachines[result.to_s.to_sym]
			end
			Prediction.new entry, @regressor.predict(rgDataSet.hashedData.first), false, @regressor
		end
	end
	def describeData
		Lpr.hashToTable({
			Length: {
				classifier:	@classifierData.length,
				regressor:	@regTrainData.length
			}
		})
		kData	= Hash[@clusterer.trainingClusters.each_with_index.map{|cluster,index| [index.to_s.to_sym, cluster.points.length]}]
		Lpr.hashToTable({
			k: kData
		})
	end
end