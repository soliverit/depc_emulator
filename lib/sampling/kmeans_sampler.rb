require "rumale"

require_relative "../unsupervised/kemans_clusterer.rb"
require_relative "../regression_data_set.rb"

class KMeansSampler
	##
	# Initialise
	#
	# rgDataSet:	RegressionDataSet
	##
	def initialize rgDataSet, features
		@data		= rgDataSet
		@scaler		= Rumale::Preprocessing::MinMaxScaler.new(feature_range: [0.0, 1.0])
		@features	= features
		@scaler.fit(@data.data)
		fit
	end
	def fit
		@clusterer	= KMeans.new @data, @features, {}
		@clusterer.train
	end
	def sample rgDataSet, sampleSize
		raise "KMeansSampler not fitted" if ! @clusterer
		clustered 	= @clusterer.predictSet rgDataSet
		groups		= clustered.groupBy :clusterID
		output		= RegressionDataSet.new false, clustered.features
		residuals	= RegressionDataSet.new false, clustered.features
		clustered.toCSVGem "./cluster.csv"
		groups.each{|key, set|
			set.sort!{|data| Random.rand <=> Random.rand}
			
			tempSample 	= set.length / rgDataSet.length.to_f * sampleSize * groups.length
			splitSet	= set.split(tempSample)
			output.merge splitSet.first
			residuals.merge splitSet.last
		}
		data	= {samples: output, residuals: residuals}
	end
end